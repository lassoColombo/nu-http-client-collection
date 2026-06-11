# Auto-generated client for Proteins REST API v1.0
# Source: https://www.ebi.ac.uk/proteins/api/openapi.json
# Auth: --token flag or $env.PROTEINS_REST_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PROTEINS_REST_API_TOKEN | default "" }
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
def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/x-gff"] }
def accept-completer-1 [] { ["application/json" "application/xml"] }
def accept-completer-2 [] { ["application/json" "application/xml" "text/x-fasta" "text/x-flatfile"] }
def accept-completer-3 [] { ["application/json" "application/xml" "text/x-fasta"] }
def accept-completer-4 [] { ["application/json" "application/xml" "text/x-gff" "text/x-peff"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "antigen get" } } | get name | first)
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

# Get antigen by UniProt accession
#
# GET /antigen/{accession}
# operationId: getByAccession
export def "antigen get" [
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: table<type: string, category: string, cvId: string, ftId: string, description: string, alternativeSequence: string, begin: string, end: string, molecule: string, ligand: record, ligandPart: record, xrefs: list, evidences: list, dbReferenceType: list, variantType: record, rnaEditingInfo: record, locationType: record, variant: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/antigen/($accession)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search antigens in UniProt
#
# GET /antigen
# operationId: search
export def "antigen search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --accession: string # UniProt accession(s). Comma separated values accepted up to 100.
  --antigen-sequence: string # Antigen sequence
  --antigen-id: string # Human Protein Atlas (HPA) antigen ID. Comma separated values accepted up to 20.
  --ensembl-ids: string # Ensembl IDs. Comma separated values accepted up to 20.
  --match-score: int # Minimum alignment score for the antigen sequence and the target protein sequence (format: int32)
]: nothing -> record<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: table<type: string, category: string, cvId: string, ftId: string, description: string, alternativeSequence: string, begin: string, end: string, molecule: string, ligand: record, ligandPart: record, xrefs: list, evidences: list, dbReferenceType: list, variantType: record, rnaEditingInfo: record, locationType: record, variant: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "antigen_sequence" $antigen_sequence "scalar") (serialize-qp "antigen_id" $antigen_id "scalar") (serialize-qp "ensembl_ids" $ensembl_ids "scalar") (serialize-qp "match_score" $match_score "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/antigen" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get genomic coordinates for a UniProt accession
#
# GET /coordinates/{accession}
# operationId: getByAccession_1
export def "coordinates get-by-accession" [
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<accession: string, name: string, taxid: int, sequence: string, protein: record<accession: string, entryType: string>, gene: table<value: string, evidence: list, type: string>, gnCoordinate: table<genomicLocation: record, feature: list, ensemblGeneId: string, ensemblTranscriptId: string, ensemblTranslationId: string, refseqNucleotideId: string, refseqProteinId: string, nucleotideId: string, proteinId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coordinates/($accession)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search UniProt entries by genomic database cross reference IDs: Ensembl, CCDS, HGNC or RefSeq
#
# GET /coordinates/{dbtype}:{dbid}
# operationId: getByDbXRef
export def "coordinates get-by-dbtype-dbid" [
  dbtype: string
  dbid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
]: nothing -> table<accession: string, name: string, taxid: int, sequence: string, protein: record<accession: string, entryType: string>, gene: list<record>, gnCoordinate: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/coordinates/($dbtype):($dbid)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search UniProt entries by taxonomy and genomic coordinates
#
# GET /coordinates/{taxonomy}/{locations}
# operationId: getByLocations
export def "coordinates get-by-taxonomy-locations" [
  taxonomy: string
  locations: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --in-range: string@bool-completer # When it is set to true for location search, only those entries that are in the range will be retrieved
]: nothing -> table<accession: string, name: string, taxid: int, sequence: string, protein: record<accession: string, entryType: string>, gene: list<record>, gnCoordinate: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "in_range" $in_range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/coordinates/($taxonomy)/($locations)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search UniProt entries by taxonomy and genomic coordinates
#
# GET /coordinates/{taxonomy}/{locations}/feature
# operationId: getFeatureByLocations
export def "coordinates-feature get" [
  taxonomy: string
  locations: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --in-range: string@bool-completer # When it is set to true for location search, only those entries that are in the range will be retrieved
]: nothing -> table<accession: string, name: string, taxid: int, sequence: string, protein: record<accession: string, entryType: string>, gene: list<record>, gnCoordinate: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "in_range" $in_range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/coordinates/($taxonomy)/($locations)/feature" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get genome coordinate by protein sequence position range
#
# GET /coordinates/location/{accession}:{pStart}-{pEnd}
# operationId: getGenomeLocationByAccession
export def "coordinates-location get" [
  accession: string
  pStart: int
  pEnd: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<locations: table<accession: string, entryType: string, taxid: int, ensemblGeneId: string, ensemblTranscriptId: string, ensemblTranslationId: string, proteinStart: int, proteinEnd: int, aminoAcids: string, chromosome: string, geneStart: int, geneEnd: int, reverseStrand: bool, nucleotideId: string, assemblyName: string, refseqNucleotideId: string, refseqProteinId: string, features: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coordinates/location/($accession):($pStart)-($pEnd)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get genome coordinate by protein sequence position
#
# GET /coordinates/location/{accession}:{pPosition}
# operationId: getGenomePositionByAccession
export def "coordinates-location list" [
  accession: string
  pPosition: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<locations: table<accession: string, entryType: string, taxid: int, ensemblGeneId: string, ensemblTranscriptId: string, ensemblTranslationId: string, proteinStart: int, proteinEnd: int, aminoAcids: string, chromosome: string, geneStart: int, geneEnd: int, reverseStrand: bool, nucleotideId: string, assemblyName: string, refseqNucleotideId: string, refseqProteinId: string, features: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coordinates/location/($accession):($pPosition)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get genome coordinate by protein sequence position
#
# GET /coordinates/glocation/{taxonomy}/{chromosome}:{gPosition}
# operationId: getProteinPositionByGenomeLocation
export def "coordinates-glocation list" [
  taxonomy: string
  chromosome: string
  gPosition: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
]: nothing -> table<locations: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coordinates/glocation/($taxonomy)/($chromosome):($gPosition)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get genome coordinate by protein sequence position
#
# GET /coordinates/glocation/{taxonomy}/{chromosome}:{gstart}-{gend}
# operationId: getProteinPositionByGenomeLocation2
export def "coordinates-glocation get" [
  taxonomy: string
  chromosome: string
  gstart: string
  gend: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
]: nothing -> table<locations: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coordinates/glocation/($taxonomy)/($chromosome):($gstart)-($gend)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search genomic coordinates for UniProt entries
#
# GET /coordinates
# operationId: search_1
export def "coordinates search-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --accession: string # UniProt accession(s). Comma separated values accepted up to 100.
  --chromosome: string # Chromosome name, i.e. 1, 2, X, etc. Comma separated values accepted up to 20.
  --ensembl: string # Ensembl gene ID, transcript ID or translation ID. Comma separated values accepted up to 20.
  --gene: string # UniProt gene name. Comma separated values accepted up to 20.
  --protein: string # UniProt protein name
  --taxid: string # Organism taxon ID. Comma separated values accepted up to 20.
  --location: string # Genome location range such as 58205437-58219305 (genome start to genome end)
]: nothing -> table<accession: string, name: string, taxid: int, sequence: string, protein: record<accession: string, entryType: string>, gene: list<record>, gnCoordinate: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "chromosome" $chromosome "scalar") (serialize-qp "ensembl" $ensembl "scalar") (serialize-qp "gene" $gene "scalar") (serialize-qp "protein" $protein "scalar") (serialize-qp "taxid" $taxid "scalar") (serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/coordinates" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get UniProt interactions by accession
#
# GET /proteins/interaction/{accession}
# operationId: getAllInteractionEntries
export def "proteins-interaction get" [
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
]: nothing -> table<accession: string, name: string, proteinExistence: string, taxonomy: int, interactions: list<record>, diseases: list<record>, subcellularLocations: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/proteins/interaction/($accession)")
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get UniProt entry by accession
#
# GET /proteins/{accession}
# operationId: getByAccession_2
export def "proteins get-by-accession" [
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, property: table<type: string, value: string>, representativeMember: record<dbReference: record<property: list, id: string, type: string>, sequence: record<value: string, length: int, checksum: string>>, member: table<dbReference: record, sequence: record>, id: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/proteins/($accession)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get UniProt entries by UniProt cross reference and its ID
#
# GET /proteins/{dbtype}:{dbid}
# operationId: getByCrossReference
export def "proteins get" [
  dbtype: string
  dbid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --reviewed: string # Reviewed(true) or not Reviewed (false)
  --isoform: int # 0 for exclude isoform only and 1 for isoform only (format: int32)
]: nothing -> table<name: string, property: list<record>, representativeMember: record<dbReference: record, sequence: record>, member: list<record>, id: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "reviewed" $reviewed "scalar") (serialize-qp "isoform" $isoform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/proteins/($dbtype):($dbid)" $qp)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get UniProt isoform entries from parent entry accession
#
# GET /proteins/{accession}/isoforms
# operationId: getEntriesForIsoforms
export def "proteins-isoforms get" [
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> table<name: string, property: list<record>, representativeMember: record<dbReference: record, sequence: record>, member: list<record>, id: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/proteins/($accession)/isoforms")
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search UniProt entries
#
# GET /proteins
# operationId: search_2
export def "proteins search-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --accession: string # UniProt accession(s). Comma separated values accepted up to 100.
  --reviewed: string # Reviewed(true) or not Reviewed (false)
  --isoform: int # 0 for excluding isoform, 1 for isoform only and 2 for both canonical and isoform (format: int32)
  --goterms: string # GO ontology terms
  --keywords: string # UniProt keywords
  --ec: string # UniProt EC number. Comma separated values accepted up to 20.
  --gene: string # UniProt gene name. Comma separated values accepted up to 20.
  --exact-gene: string # UniProt exact gene name. Comma separated values accepted up to 20.
  --protein: string # UniProt protein name
  --organism: string # Organism name
  --taxid: string # Organism taxon ID. Comma separated values accepted up to 20.
  --pubmed: string # UniProt reference PubMed ID. Comma separated values accepted up to 20.
  --seqLength: string # Sequence length. Sequence length can be a single length value such as 123 or range 123-234
  --md5: string # Sequence md5 value.
]: nothing -> table<name: string, property: list<record>, representativeMember: record<dbReference: record, sequence: record>, member: list<record>, id: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "reviewed" $reviewed "scalar") (serialize-qp "isoform" $isoform "scalar") (serialize-qp "goterms" $goterms "scalar") (serialize-qp "keywords" $keywords "scalar") (serialize-qp "ec" $ec "scalar") (serialize-qp "gene" $gene "scalar") (serialize-qp "exact_gene" $exact_gene "scalar") (serialize-qp "protein" $protein "scalar") (serialize-qp "organism" $organism "scalar") (serialize-qp "taxid" $taxid "scalar") (serialize-qp "pubmed" $pubmed "scalar") (serialize-qp "seqLength" $seqLength "scalar") (serialize-qp "md5" $md5 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/proteins" $qp)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get epitope by UniProt accession
#
# GET /epitope/{accession}
# operationId: getByAccession_3
export def "epitope get-by-accession" [
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: table<type: string, category: string, cvId: string, ftId: string, description: string, alternativeSequence: string, begin: string, end: string, molecule: string, ligand: record, ligandPart: record, xrefs: list, evidences: list, dbReferenceType: list, variantType: record, rnaEditingInfo: record, locationType: record, variant: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/epitope/($accession)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search epitope in UniProt
#
# GET /epitope
# operationId: search_3
export def "epitope search-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --accession: string # UniProt accession(s). Comma separated values accepted up to 100.
  --epitope-sequence: string # Epitope sequence
  --iedb-id: string # Epitope or antigenic determinant ID. Comma separated values accepted up to 20.
  --match-score: int # Minimum alignment score for the antigen sequence and the target protein sequence (format: int32)
]: nothing -> table<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "epitope_sequence" $epitope_sequence "scalar") (serialize-qp "iedb_id" $iedb_id "scalar") (serialize-qp "match_score" $match_score "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/epitope" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get UniProt protein sequence features by accession 
#
# GET /features/{accession}
# operationId: getByAccession_4
export def "features get-by-accession" [
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Category types: MOLECULE-PROCESSING, TOPOLOGY, SEQUENCE-INFORMATION, STRUCTURAL, DOMAINS-AND-SITES, PTM, VARIANTS, MUTAGENESIS Comma separated values accepted up to 20: string
  --Feature types: INIT-MET, SIGNAL, PROPEP, TRANSIT, CHAIN, PEPTIDE, TOPO-DOM, TRANSMEM, DOMAIN, REPEAT, ZN-FING, DNA-BIND, REGION, COILED, MOTIF, COMPBIAS, ACT-SITE, BINDING, SITE, NON-STD, MOD-RES, LIPID, CARBOHYD, DISULFID, CROSSLNK, VAR-SEQ, VARIANT, MUTAGEN, UNSURE, CONFLICT, NON-CONS, NON-TER, HELIX, TURN, STRAND, INTRAMEM Comma separated values accepted up to 20: string
  --location: string # Filter by the amino acid range position in the sequence(s). Any valid amino acid range position within the length of the protein sequence such as 10-60 (start position to end position)
]: nothing -> record<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: table<type: string, category: string, cvId: string, ftId: string, description: string, alternativeSequence: string, begin: string, end: string, molecule: string, ligand: record, ligandPart: record, xrefs: list, evidences: list, dbReferenceType: list, variantType: record, rnaEditingInfo: record, locationType: record, variant: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Category type(s): MOLECULE_PROCESSING, TOPOLOGY, SEQUENCE_INFORMATION, STRUCTURAL, DOMAINS_AND_SITES, PTM, VARIANTS, MUTAGENESIS. Comma separated values accepted up to 20" $Category types: MOLECULE_PROCESSING, TOPOLOGY, SEQUENCE_INFORMATION, STRUCTURAL, DOMAINS_AND_SITES, PTM, VARIANTS, MUTAGENESIS Comma separated values accepted up to 20 "scalar") (serialize-qp "Feature type(s): INIT_MET, SIGNAL, PROPEP, TRANSIT, CHAIN, PEPTIDE, TOPO_DOM, TRANSMEM, DOMAIN, REPEAT, ZN_FING, DNA_BIND, REGION, COILED, MOTIF, COMPBIAS, ACT_SITE, BINDING, SITE, NON_STD, MOD_RES, LIPID, CARBOHYD, DISULFID, CROSSLNK, VAR_SEQ, VARIANT, MUTAGEN, UNSURE, CONFLICT, NON_CONS, NON_TER, HELIX, TURN, STRAND, INTRAMEM. Comma separated values accepted up to 20" $Feature types: INIT_MET, SIGNAL, PROPEP, TRANSIT, CHAIN, PEPTIDE, TOPO_DOM, TRANSMEM, DOMAIN, REPEAT, ZN_FING, DNA_BIND, REGION, COILED, MOTIF, COMPBIAS, ACT_SITE, BINDING, SITE, NON_STD, MOD_RES, LIPID, CARBOHYD, DISULFID, CROSSLNK, VAR_SEQ, VARIANT, MUTAGEN, UNSURE, CONFLICT, NON_CONS, NON_TER, HELIX, TURN, STRAND, INTRAMEM Comma separated values accepted up to 20 "scalar") (serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/features/($accession)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search protein sequence features in UniProt
#
# GET /features
# operationId: search_4
export def "features search-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --accession: string # UniProt accession(s). Comma separated values accepted up to 100.
  --reviewed: string # The reviewed parameter can only be true or false
  --gene: string # UniProt gene name. Comma separated values accepted up to 20.
  --exact-gene: string # UniProt exact gene name. Comma separated values accepted up to 20.
  --protein: string # UniProt protein name
  --organism: string # Organism name
  --taxid: string # Organism taxon ID. Comma separated values accepted up to 20.
  --categories: string # Category type(s): MOLECULE_PROCESSING, TOPOLOGY, SEQUENCE_INFORMATION, STRUCTURAL, DOMAINS_AND_SITES, PTM, VARIANTS, MUTAGENESIS. Comma separated values accepted up to 20
  --types: string # Feature type(s): INIT_MET, SIGNAL, PROPEP, TRANSIT, CHAIN, PEPTIDE, TOPO_DOM, TRANSMEM, DOMAIN, REPEAT, ZN_FING, DNA_BIND, REGION, COILED, MOTIF, COMPBIAS, ACT_SITE, BINDING, SITE, NON_STD, MOD_RES, LIPID, CARBOHYD, DISULFID, CROSSLNK, VAR_SEQ, VARIANT, MUTAGEN, UNSURE, CONFLICT, NON_CONS, NON_TER, HELIX, TURN, STRAND, INTRAMEM. Comma separated values accepted up to 20
]: nothing -> table<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "reviewed" $reviewed "scalar") (serialize-qp "gene" $gene "scalar") (serialize-qp "exact_gene" $exact_gene "scalar") (serialize-qp "protein" $protein "scalar") (serialize-qp "organism" $organism "scalar") (serialize-qp "taxid" $taxid "scalar") (serialize-qp "categories" $categories "scalar") (serialize-qp "types" $types "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/features" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search protein sequence features of a given type in UniProt
#
# GET /features/type/{type}
# operationId: searchFeatureType
export def "features-type searchFeatureType" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --categories: string # Category type(s): MOLECULE_PROCESSING, TOPOLOGY, SEQUENCE_INFORMATION, STRUCTURAL, DOMAINS_AND_SITES, PTM, VARIANTS, MUTAGENESIS. Comma separated values accepted up to 20
  --types: string # Feature type(s): INIT_MET, SIGNAL, PROPEP, TRANSIT, CHAIN, PEPTIDE, TOPO_DOM, TRANSMEM, DOMAIN, REPEAT, ZN_FING, DNA_BIND, REGION, COILED, MOTIF, COMPBIAS, ACT_SITE, BINDING, SITE, NON_STD, MOD_RES, LIPID, CARBOHYD, DISULFID, CROSSLNK, VAR_SEQ, VARIANT, MUTAGEN, UNSURE, CONFLICT, NON_CONS, NON_TER, HELIX, TURN, STRAND, INTRAMEM. Comma separated values accepted up to 20
  --terms: string # Search for term(s) that appear in feature description for your specified feature type. For example, you can search by type=DOMAIN and Term=Kinase.  Comma separated values accepted up to 20.
]: nothing -> table<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "categories" $categories "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "terms" $terms "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/features/type/($type)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get gene centric proteins by Uniprot accession
#
# GET /genecentric/{accession}
# operationId: getGeneCentricByAccession
export def "genecentric get" [
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<gene: record<accession: string, entryType: string, length: int, geneName: string, geneNameType: string>, relatedGene: table<accession: string, entryType: string, length: int, geneName: string, geneNameType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/genecentric/($accession)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search gene centric proteins
#
# GET /genecentric
# operationId: getGeneCentricByUpid
export def "genecentric list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --upid: string # UniProt proteome UPID(s). Comma separated values accepted up to 100.
  --accession: string # UniProt accession(s). Comma separated values accepted up to 100.
  --gene: string # It is a unique gene identifier found in MOD, Ensembl, Ensembl Genomes, OLN ,ORF or UniProt Gene Name database. Comma separated values accepted up to 20.
]: nothing -> record<gene: record<accession: string, entryType: string, length: int, geneName: string, geneNameType: string>, relatedGene: table<accession: string, entryType: string, length: int, geneName: string, geneNameType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "upid" $upid "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "gene" $gene "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/genecentric" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hpp peptides mapped to UniProt by accession
#
# GET /hpp/{accession}
# DEPRECATED
# operationId: getByAccession_5
@deprecated
export def "hpp get-by-accession" [
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: table<type: string, category: string, cvId: string, ftId: string, description: string, alternativeSequence: string, begin: string, end: string, molecule: string, ligand: record, ligandPart: record, xrefs: list, evidences: list, dbReferenceType: list, variantType: record, rnaEditingInfo: record, locationType: record, variant: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hpp/($accession)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search hpp peptides in UniProt
#
# GET /hpp
# DEPRECATED
# operationId: search_5
@deprecated
export def "hpp search-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --accession: string # UniProt accession(s). Comma separated values accepted up to 100.
  --taxid: string # Organism taxon ID. Comma separated values accepted up to 20.
  --upid: string # UniProt proteome UPID(s). Comma separated values accepted up to 100.
  --datasource: string # HPP data source(s): MaxQB, PeptideAtlas, EPD or HppDB. Comma separated values accepted up to 2.
  --peptide: string # Peptide sequence. Comma separated values accepted up to 20.
  --unique: string # Peptide uniqueness (unique peptides map to one gene group only). Values can be true or false.
]: nothing -> table<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "taxid" $taxid "scalar") (serialize-qp "upid" $upid "scalar") (serialize-qp "datasource" $datasource "scalar") (serialize-qp "peptide" $peptide "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hpp" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hpp peptides mapped to UniProt by accession
#
# GET /proteomics/hpp/{accession}
# operationId: getByAccession_6
export def "proteomics-hpp get-by-accession" [
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: table<type: string, category: string, cvId: string, ftId: string, description: string, alternativeSequence: string, begin: string, end: string, molecule: string, ligand: record, ligandPart: record, xrefs: list, evidences: list, dbReferenceType: list, variantType: record, rnaEditingInfo: record, locationType: record, variant: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/proteomics/hpp/($accession)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search hpp peptides in UniProt
#
# GET /proteomics/hpp
# operationId: search_6
export def "proteomics-hpp search-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --accession: string # UniProt accession(s). Comma separated values accepted up to 100.
  --taxid: string # Organism taxon ID. Comma separated values accepted up to 20.
  --upid: string # UniProt proteome UPID(s). Comma separated values accepted up to 100.
  --datasource: string # HPP data source(s): MaxQB, PeptideAtlas, EPD or HppDB. Comma separated values accepted up to 2.
  --peptide: string # Peptide sequence. Comma separated values accepted up to 20.
  --unique: string # Peptide uniqueness (unique peptides map to one gene group only). Values can be true or false.
]: nothing -> table<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "taxid" $taxid "scalar") (serialize-qp "upid" $upid "scalar") (serialize-qp "datasource" $datasource "scalar") (serialize-qp "peptide" $peptide "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/proteomics/hpp" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /info
#
# operationId: getUniProtInfo
export def "info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get mutagenesis mapped to UniProt by accession
#
# GET /mutagenesis/{accession}
# operationId: getByAccession_7
export def "mutagenesis get-by-accession" [
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location: string # Filter by the amino acid range position in the sequence(s). Any valid amino acid range position within the length of the protein sequence such as 10-60 (start position to end position)
]: nothing -> record<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: table<type: string, category: string, cvId: string, ftId: string, description: string, alternativeSequence: string, begin: string, end: string, molecule: string, ligand: record, ligandPart: record, xrefs: list, evidences: list, dbReferenceType: list, variantType: record, rnaEditingInfo: record, locationType: record, variant: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mutagenesis/($accession)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search mutagensis in UniProt
#
# GET /mutagenesis
# operationId: search_7
export def "mutagenesis search-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --accession: string # UniProt accession(s). Comma separated values accepted up to 100.
  --taxid: string # Organism taxon ID. Comma separated values accepted up to 20.
  --dbid: string # Cross-reference database ID, e.g. rs121918508 for dbSNP, COSM29836 for cosmic curated, rcv61200 for ClinVar. Comma separated values accepted up to 20.
]: nothing -> table<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "taxid" $taxid "scalar") (serialize-qp "dbid" $dbid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mutagenesis" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get proteome by proteome UPID
#
# GET /proteomes/{upid}
# operationId: getByUpid
export def "proteomes get" [
  upid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, description: string, isReferenceProteome: bool, isRepresentativeProteome: bool, redundantTo: string, strain: string, isolate: string, genomeAssembly: record<genomeAssemblySource: string, genomeAssembly: string, genomeAssemblyUrl: string, genomeRepresentation: string>, dbReference: table<property: list, id: string, type: string>, component: table<description: string, biosampleId: string, genomeAccession: list, protein: list, name: string, count: int>, reference: table<citation: record>, redundantProteome: table<upid: string, similarity: float>, canonicalGene: table<gene: record, relatedGene: list>, panproteome: string, annotationScore: record<normalizedAnnotationScore: int>, excluded: record<exclusionReason: list<string>>, scores: table<property: list, name: string>, upid: string, modified: string, taxonomy: int, source: string, superregnum: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/proteomes/($upid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get gene centric proteins by proteome UPID is deprecated, please use new /genecentric?upid= endpoint
#
# GET /proteomes/genecentric/{upid}
# DEPRECATED
# operationId: getGeneCentricByUpidDeprecated
@deprecated
export def "proteomes-genecentric get" [
  upid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, description: string, isReferenceProteome: bool, isRepresentativeProteome: bool, redundantTo: string, strain: string, isolate: string, genomeAssembly: record<genomeAssemblySource: string, genomeAssembly: string, genomeAssemblyUrl: string, genomeRepresentation: string>, dbReference: table<property: list, id: string, type: string>, component: table<description: string, biosampleId: string, genomeAccession: list, protein: list, name: string, count: int>, reference: table<citation: record>, redundantProteome: table<upid: string, similarity: float>, canonicalGene: table<gene: record, relatedGene: list>, panproteome: string, annotationScore: record<normalizedAnnotationScore: int>, excluded: record<exclusionReason: list<string>>, scores: table<property: list, name: string>, upid: string, modified: string, taxonomy: int, source: string, superregnum: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/proteomes/genecentric/($upid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get proteins by proteome UPID
#
# GET /proteomes/proteins/{upid}
# operationId: getProteinsByUpid
export def "proteomes-proteins get" [
  upid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reviewed: string # Reviewed(true) or not Reviewed (false)
]: nothing -> record<name: string, description: string, isReferenceProteome: bool, isRepresentativeProteome: bool, redundantTo: string, strain: string, isolate: string, genomeAssembly: record<genomeAssemblySource: string, genomeAssembly: string, genomeAssemblyUrl: string, genomeRepresentation: string>, dbReference: table<property: list, id: string, type: string>, component: table<description: string, biosampleId: string, genomeAccession: list, protein: list, name: string, count: int>, reference: table<citation: record>, redundantProteome: table<upid: string, similarity: float>, canonicalGene: table<gene: record, relatedGene: list>, panproteome: string, annotationScore: record<normalizedAnnotationScore: int>, excluded: record<exclusionReason: list<string>>, scores: table<property: list, name: string>, upid: string, modified: string, taxonomy: int, source: string, superregnum: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reviewed" $reviewed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/proteomes/proteins/($upid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search proteomes in UniProt
#
# GET /proteomes
# operationId: search_8
export def "proteomes search-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --upid: string # UniProt proteome UPID(s). Comma separated values accepted up to 100.
  --name: string # Search proteome name
  --taxid: string # Organism taxon ID. Comma separated values accepted up to 20.
  --keyword: string # Terms the proteome contains
  --xref: string # Proteome cross references such as Genome assembly ID or Biosample ID. Comma separated values accepted up to 20.
  --genome-acc: string # Genome accession. Comma separated values accepted up to 20.
  --is-ref-proteome: string # Reference Proteome(true) or not reference proteome (false)
  --is-redundant: string # Redundant Proteome(true) or non redundant proteome (false)
]: nothing -> record<name: string, description: string, isReferenceProteome: bool, isRepresentativeProteome: bool, redundantTo: string, strain: string, isolate: string, genomeAssembly: record<genomeAssemblySource: string, genomeAssembly: string, genomeAssemblyUrl: string, genomeRepresentation: string>, dbReference: table<property: list, id: string, type: string>, component: table<description: string, biosampleId: string, genomeAccession: list, protein: list, name: string, count: int>, reference: table<citation: record>, redundantProteome: table<upid: string, similarity: float>, canonicalGene: table<gene: record, relatedGene: list>, panproteome: string, annotationScore: record<normalizedAnnotationScore: int>, excluded: record<exclusionReason: list<string>>, scores: table<property: list, name: string>, upid: string, modified: string, taxonomy: int, source: string, superregnum: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "upid" $upid "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "taxid" $taxid "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "xref" $xref "scalar") (serialize-qp "genome_acc" $genome_acc "scalar") (serialize-qp "is_ref_proteome" $is_ref_proteome "scalar") (serialize-qp "is_redundant" $is_redundant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/proteomes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get proteomics peptides mapped to UniProt by accession
#
# GET /proteomics/{accession}
# DEPRECATED
# operationId: getByAccession_8
@deprecated
export def "proteomics get-by-accession" [
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: table<type: string, category: string, cvId: string, ftId: string, description: string, alternativeSequence: string, begin: string, end: string, molecule: string, ligand: record, ligandPart: record, xrefs: list, evidences: list, dbReferenceType: list, variantType: record, rnaEditingInfo: record, locationType: record, variant: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/proteomics/($accession)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get proteomics peptides mapped to UniProt by accession
#
# GET /proteomics/nonPtm/{accession}
# operationId: getNonPtmByAccession
export def "proteomics-non-ptm get" [
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: table<type: string, category: string, cvId: string, ftId: string, description: string, alternativeSequence: string, begin: string, end: string, molecule: string, ligand: record, ligandPart: record, xrefs: list, evidences: list, dbReferenceType: list, variantType: record, rnaEditingInfo: record, locationType: record, variant: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/proteomics/nonPtm/($accession)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search proteomics peptides in UniProt
#
# GET /proteomics
# DEPRECATED
# operationId: search_9
@deprecated
export def "proteomics search-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --accession: string # UniProt accession(s). Comma separated values accepted up to 100.
  --taxid: string # Organism taxon ID. Comma separated values accepted up to 20.
  --upid: string # UniProt proteome UPID(s). Comma separated values accepted up to 100.
  --datasource: string # Proteomics data source(s): MaxQB, PeptideAtlas, EPD or ProteomicsDB. Comma separated values accepted up to 2.
  --peptide: string # Peptide sequence. Comma separated values accepted up to 20.
  --unique: string # Peptide uniqueness (unique peptides map to one gene group only). Values can be true or false.
]: nothing -> table<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "taxid" $taxid "scalar") (serialize-qp "upid" $upid "scalar") (serialize-qp "datasource" $datasource "scalar") (serialize-qp "peptide" $peptide "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/proteomics" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search proteomics peptides in UniProt
#
# GET /proteomics/nonPtm
# operationId: searchNonPtm
export def "proteomics-non-ptm searchNonPtm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --accession: string # UniProt accession(s). Comma separated values accepted up to 100.
  --taxid: string # Organism taxon ID. Comma separated values accepted up to 20.
  --upid: string # UniProt proteome UPID(s). Comma separated values accepted up to 100.
  --datasource: string # Proteomics data source(s): MaxQB, PeptideAtlas, EPD or ProteomicsDB. Comma separated values accepted up to 2.
  --peptide: string # Peptide sequence. Comma separated values accepted up to 20.
  --unique: string # Peptide uniqueness (unique peptides map to one gene group only). Values can be true or false.
]: nothing -> table<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "taxid" $taxid "scalar") (serialize-qp "upid" $upid "scalar") (serialize-qp "datasource" $datasource "scalar") (serialize-qp "peptide" $peptide "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/proteomics/nonPtm" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get proteomics metadata overview
#
# GET /proteomics/species
# operationId: getOverview
export def "proteomics-species get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/proteomics/species")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search proteomics species by datatype, taxid, or upid
#
# GET /proteomics/species/search
# operationId: searchSpecies
export def "proteomics-species-search searchSpecies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --datatype: string # default: 
  --taxid: string # default: 
  --upid: string # default: 
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datatype" $datatype "scalar") (serialize-qp "taxid" $taxid "scalar") (serialize-qp "upid" $upid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/proteomics/species/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get proteomics peptide ptm mapped to UniProt by accession
#
# GET /proteomics-ptm/{accession}
# DEPRECATED
# operationId: getByAccession_9
@deprecated
export def "proteomics-ptm get-by-accession-by-accession" [
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PTM Confidence scores: Bronze, Silver, Gold: string
]: nothing -> record<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: table<type: string, category: string, cvId: string, ftId: string, description: string, alternativeSequence: string, begin: string, end: string, molecule: string, ligand: record, ligandPart: record, xrefs: list, evidences: list, dbReferenceType: list, variantType: record, rnaEditingInfo: record, locationType: record, variant: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PTM Confidence score(s): Bronze, Silver, Gold" $PTM Confidence scores: Bronze, Silver, Gold "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/proteomics-ptm/($accession)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search proteomics peptide ptm in UniProt
#
# GET /proteomics-ptm
# DEPRECATED
# operationId: search_10
@deprecated
export def "proteomics-ptm search-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --accession: string # UniProt accession(s). Comma separated values accepted up to 100.
  --taxid: string # Organism taxon ID. Comma separated values accepted up to 20.
  --upid: string # UniProt proteome UPID(s). Comma separated values accepted up to 100.
  --datasource: string # Proteomics data source(s): PRIDE, PTMExchange. Comma separated values accepted up to 2.
  --peptide: string # Peptide sequence. Comma separated values accepted up to 20.
  --unique: string # Peptide uniqueness (unique peptides map to one gene group only). Values can be true or false.
  --ptm: string # Ptm name
  --confidence-score: string # PTM Confidence score(s): Bronze, Silver, Gold
]: nothing -> record<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: table<type: string, category: string, cvId: string, ftId: string, description: string, alternativeSequence: string, begin: string, end: string, molecule: string, ligand: record, ligandPart: record, xrefs: list, evidences: list, dbReferenceType: list, variantType: record, rnaEditingInfo: record, locationType: record, variant: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "taxid" $taxid "scalar") (serialize-qp "upid" $upid "scalar") (serialize-qp "datasource" $datasource "scalar") (serialize-qp "peptide" $peptide "scalar") (serialize-qp "unique" $unique "scalar") (serialize-qp "ptm" $ptm "scalar") (serialize-qp "confidence_score" $confidence_score "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/proteomics-ptm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get proteomics peptide ptm mapped to UniProt by accession
#
# GET /proteomics/ptm/{accession}
# operationId: getByAccession_10
export def "proteomics-ptm get-by-accession-by-accession-1" [
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PTM Confidence scores: Bronze, Silver, Gold: string
]: nothing -> record<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: table<type: string, category: string, cvId: string, ftId: string, description: string, alternativeSequence: string, begin: string, end: string, molecule: string, ligand: record, ligandPart: record, xrefs: list, evidences: list, dbReferenceType: list, variantType: record, rnaEditingInfo: record, locationType: record, variant: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PTM Confidence score(s): Bronze, Silver, Gold" $PTM Confidence scores: Bronze, Silver, Gold "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/proteomics/ptm/($accession)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search proteomics peptide ptm in UniProt
#
# GET /proteomics/ptm
# operationId: search_11
export def "proteomics-ptm search-by--1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --accession: string # UniProt accession(s). Comma separated values accepted up to 100.
  --taxid: string # Organism taxon ID. Comma separated values accepted up to 20.
  --upid: string # UniProt proteome UPID(s). Comma separated values accepted up to 100.
  --datasource: string # Proteomics data source(s): PRIDE, PTMExchange. Comma separated values accepted up to 2.
  --peptide: string # Peptide sequence. Comma separated values accepted up to 20.
  --unique: string # Peptide uniqueness (unique peptides map to one gene group only). Values can be true or false.
  --ptm: string # Ptm name
  --confidence-score: string # PTM Confidence score(s): Bronze, Silver, Gold
]: nothing -> record<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: table<type: string, category: string, cvId: string, ftId: string, description: string, alternativeSequence: string, begin: string, end: string, molecule: string, ligand: record, ligandPart: record, xrefs: list, evidences: list, dbReferenceType: list, variantType: record, rnaEditingInfo: record, locationType: record, variant: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "taxid" $taxid "scalar") (serialize-qp "upid" $upid "scalar") (serialize-qp "datasource" $datasource "scalar") (serialize-qp "peptide" $peptide "scalar") (serialize-qp "unique" $unique "scalar") (serialize-qp "ptm" $ptm "scalar") (serialize-qp "confidence_score" $confidence_score "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/proteomics/ptm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /
#
# operationId: redirectRoot
export def "api redirectRoot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get rna editing mapped to UniProt by accession
#
# GET /rna-editing/{accession}
# operationId: getByAccession_11
export def "rna-editing get-by-accession" [
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: table<type: string, category: string, cvId: string, ftId: string, description: string, alternativeSequence: string, begin: string, end: string, molecule: string, ligand: record, ligandPart: record, xrefs: list, evidences: list, dbReferenceType: list, variantType: record, rnaEditingInfo: record, locationType: record, variant: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rna-editing/($accession)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search rna editing in UniProt
#
# GET /rna-editing
# operationId: search_12
export def "rna-editing search-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --accession: string # UniProt accession(s). Comma separated values accepted up to 100.
  --taxid: string # Organism taxon ID. Comma separated values accepted up to 20.
  --variantlocation: string # RNA EDITING variant location(s). Comma separated values accepted up 4
]: nothing -> table<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "taxid" $taxid "scalar") (serialize-qp "variantlocation" $variantlocation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rna-editing" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get UniParc entries by Proteome UPID
#
# GET /uniparc/proteome/{upid}
# operationId: getByProteomeId
export def "uniparc-proteome get" [
  upid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-3 # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --rfDdtype: string # Response filter by Cross reference database type, e.g EMBL, RefSeq, Ensembl, etc. Comma separated values accepted.
  --rfDbid: string # Response filter by all UniParc cross reference accessions, eg. AAC02967 (EMBL) or  XP_006524055 (RefSeq). Comma separated values accepted.
  --rfActive: string # Response filter by Active(true) or not Active(false) Cross reference.
  --rfTaxId: string # Response filter by organism taxon ID. Comma separated values accepted.
]: nothing -> table<name: string, property: list<record>, representativeMember: record<dbReference: record, sequence: record>, member: list<record>, id: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "rfDdtype" $rfDdtype "scalar") (serialize-qp "rfDbid" $rfDbid "scalar") (serialize-qp "rfActive" $rfActive "scalar") (serialize-qp "rfTaxId" $rfTaxId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/uniparc/proteome/($upid)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get UniParc entries by sequence
#
# POST /uniparc/sequence
# operationId: getBySequence
export def "uniparc-sequence post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rfDdtype: string # Response filter by Cross reference database type, e.g EMBL, RefSeq, Ensembl, etc. Comma separated values accepted.
  --rfDbid: string # Response filter by all UniParc cross reference accessions, eg. AAC02967 (EMBL) or  XP_006524055 (RefSeq). Comma separated values accepted.
  --rfActive: string # Response filter by Active(true) or not Active(false) Cross reference.
  --rfTaxId: string # Response filter by organism taxon ID. Comma separated values accepted.
  sequence: string
]: any -> record<name: string, property: table<type: string, value: string>, representativeMember: record<dbReference: record<property: list, id: string, type: string>, sequence: record<value: string, length: int, checksum: string>>, member: table<dbReference: record, sequence: record>, id: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rfDdtype" $rfDdtype "scalar") (serialize-qp "rfDbid" $rfDbid "scalar") (serialize-qp "rfActive" $rfActive "scalar") (serialize-qp "rfTaxId" $rfTaxId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/uniparc/sequence" $qp)
  let body = {sequence: $sequence} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get UniParc longest sequence for entries.
#
# GET /uniparc/bestguess
# operationId: getUniParcBestGuest
export def "uniparc-bestguess get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --upi: string # UniParc ID (UPI). Comma separated values accepted up to 100
  --accession: string # UniProt accession(s). Comma separated values accepted up to 100.
  --dbid: string # All UniParc cross reference accessions, eg. AAC02967 (EMBL) or  XP_006524055 (RefSeq). Comma separated values accepted up to 100.
  --gene: string # UniProt gene name. Comma separated values accepted up to 20.
  --taxid: string # Organism taxon ID. Comma separated values accepted up to 20.
]: nothing -> record<name: string, property: table<type: string, value: string>, representativeMember: record<dbReference: record<property: list, id: string, type: string>, sequence: record<value: string, length: int, checksum: string>>, member: table<dbReference: record, sequence: record>, id: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upi" $upi "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "dbid" $dbid "scalar") (serialize-qp "gene" $gene "scalar") (serialize-qp "taxid" $taxid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/uniparc/bestguess" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get UniParc entries by all UniParc cross reference accessions
#
# GET /uniparc/dbreference/{dbid}
# operationId: getUniParcByUniparcAccessions
export def "uniparc-dbreference get" [
  dbid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --rfDdtype: string # Response filter by Cross reference database type, e.g EMBL, RefSeq, Ensembl, etc. Comma separated values accepted.
  --rfDbid: string # Response filter by all UniParc cross reference accessions, eg. AAC02967 (EMBL) or  XP_006524055 (RefSeq). Comma separated values accepted.
  --rfActive: string # Response filter by Active(true) or not Active(false) Cross reference.
  --rfTaxId: string # Response filter by organism taxon ID. Comma separated values accepted.
]: nothing -> record<name: string, property: table<type: string, value: string>, representativeMember: record<dbReference: record<property: list, id: string, type: string>, sequence: record<value: string, length: int, checksum: string>>, member: table<dbReference: record, sequence: record>, id: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "rfDdtype" $rfDdtype "scalar") (serialize-qp "rfDbid" $rfDbid "scalar") (serialize-qp "rfActive" $rfActive "scalar") (serialize-qp "rfTaxId" $rfTaxId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/uniparc/dbreference/($dbid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get UniParc entry only by UniProt accession
#
# GET /uniparc/accession/{accession}
# operationId: getUniParcEntryByUniprotAccession
export def "uniparc-accession get" [
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rfDdtype: string # Response filter by Cross reference database type, e.g EMBL, RefSeq, Ensembl, etc. Comma separated values accepted.
  --rfDbid: string # Response filter by all UniParc cross reference accessions, eg. AAC02967 (EMBL) or  XP_006524055 (RefSeq). Comma separated values accepted.
  --rfActive: string # Response filter by Active(true) or not Active(false) Cross reference.
  --rfTaxId: string # Response filter by organism taxon ID. Comma separated values accepted.
]: nothing -> record<name: string, property: table<type: string, value: string>, representativeMember: record<dbReference: record<property: list, id: string, type: string>, sequence: record<value: string, length: int, checksum: string>>, member: table<dbReference: record, sequence: record>, id: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rfDdtype" $rfDdtype "scalar") (serialize-qp "rfDbid" $rfDbid "scalar") (serialize-qp "rfActive" $rfActive "scalar") (serialize-qp "rfTaxId" $rfTaxId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/uniparc/accession/($accession)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get UniParc entry by UniParc UPI
#
# GET /uniparc/upi/{upi}
# operationId: getUniParcEntryByUpId
export def "uniparc-upi get" [
  upi: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rfDdtype: string # Response filter by Cross reference database type, e.g EMBL, RefSeq, Ensembl, etc. Comma separated values accepted.
  --rfDbid: string # Response filter by all UniParc cross reference accessions, eg. AAC02967 (EMBL) or  XP_006524055 (RefSeq). Comma separated values accepted.
  --rfActive: string # Response filter by Active(true) or not Active(false) Cross reference.
  --rfTaxId: string # Response filter by organism taxon ID. Comma separated values accepted.
]: nothing -> record<name: string, property: table<type: string, value: string>, representativeMember: record<dbReference: record<property: list, id: string, type: string>, sequence: record<value: string, length: int, checksum: string>>, member: table<dbReference: record, sequence: record>, id: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rfDdtype" $rfDdtype "scalar") (serialize-qp "rfDbid" $rfDbid "scalar") (serialize-qp "rfActive" $rfActive "scalar") (serialize-qp "rfTaxId" $rfTaxId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/uniparc/upi/($upi)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search UniParc entries
#
# GET /uniparc
# operationId: searchUniParc
export def "uniparc searchUniParc" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-3 # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --upi: string # UniParc ID (UPI). Comma separated values accepted up to 100
  --dbtype: string # Search by Cross reference database type, e.g EMBL, RefSeq, Ensembl, etc.
  --accession: string # UniProt accession(s). Comma separated values accepted up to 100.
  --dbid: string # All UniParc cross reference accessions, eg. AAC02967 (EMBL) or  XP_006524055 (RefSeq). Comma separated values accepted up to 100.
  --gene: string # UniProt gene name. Comma separated values accepted up to 20.
  --protein: string # UniProt protein name
  --taxid: string # Organism taxon ID. Comma separated values accepted up to 20.
  --organism: string # Organism name
  --sequencechecksum: string # Sequence CRC64 checksum. eg 4104A3A57D1B08E3
  --ipr: string # Search by InterPro identifier(s). Comma separated values accepted up to 20.
  --signaturetype: string # Search by signature database type, e.g. SMART, SUPFAM, Pfam, PIRSF, PROSITE, etc. Comma separated values accepted up to 20.
  --signatureid: string # Search by signature database id, e.g. SM00044, SSF55073, PF00211, PIRSF039050, PS00452, etc. Comma separated values accepted up to 20.
  --upid: string # UniProt proteome UPID(s). Comma separated values accepted up to 100.
  --seqLength: string # Sequence length. Sequence length can be a single length value such as 123 or range 123-234
  --rfDdtype: string # Response filter by Cross reference database type, e.g EMBL, RefSeq, Ensembl, etc. Comma separated values accepted.
  --rfDbid: string # Response filter by all UniParc cross reference accessions, eg. AAC02967 (EMBL) or  XP_006524055 (RefSeq). Comma separated values accepted.
  --rfActive: string # Response filter by Active(true) or not Active(false) Cross reference.
  --rfTaxId: string # Response filter by organism taxon ID. Comma separated values accepted.
]: nothing -> table<name: string, property: list<record>, representativeMember: record<dbReference: record, sequence: record>, member: list<record>, id: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "upi" $upi "scalar") (serialize-qp "dbtype" $dbtype "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "dbid" $dbid "scalar") (serialize-qp "gene" $gene "scalar") (serialize-qp "protein" $protein "scalar") (serialize-qp "taxid" $taxid "scalar") (serialize-qp "organism" $organism "scalar") (serialize-qp "sequencechecksum" $sequencechecksum "scalar") (serialize-qp "ipr" $ipr "scalar") (serialize-qp "signaturetype" $signaturetype "scalar") (serialize-qp "signatureid" $signatureid "scalar") (serialize-qp "upid" $upid "scalar") (serialize-qp "seqLength" $seqLength "scalar") (serialize-qp "rfDdtype" $rfDdtype "scalar") (serialize-qp "rfDbid" $rfDbid "scalar") (serialize-qp "rfActive" $rfActive "scalar") (serialize-qp "rfTaxId" $rfTaxId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/uniparc" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get UniRef entry by UniProtKB accession
#
# GET /uniref/accession/{accession}/dataset/{dataset}
# operationId: getUniRefEntryByAccession
export def "uniref-accession-dataset get" [
  accession: string
  dataset: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, property: table<type: string, value: string>, representativeMember: record<dbReference: record<property: list, id: string, type: string>, sequence: record<value: string, length: int, checksum: string>>, member: table<dbReference: record, sequence: record>, id: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/uniref/accession/($accession)/dataset/($dataset)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get UniRef entry by UniRef cluster ID
#
# GET /uniref/clusterId/{clusterId}
# operationId: getUniRefEntryByClusterId
export def "uniref-cluster-id get" [
  clusterId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, property: table<type: string, value: string>, representativeMember: record<dbReference: record<property: list, id: string, type: string>, sequence: record<value: string, length: int, checksum: string>>, member: table<dbReference: record, sequence: record>, id: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/uniref/clusterId/($clusterId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get UniRef entry by UniParc ID
#
# GET /uniref/upi/{upi}/dataset/{dataset}
# operationId: getUniRefEntryByUpId
export def "uniref-upi-dataset get" [
  upi: string
  dataset: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, property: table<type: string, value: string>, representativeMember: record<dbReference: record<property: list, id: string, type: string>, sequence: record<value: string, length: int, checksum: string>>, member: table<dbReference: record, sequence: record>, id: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/uniref/upi/($upi)/dataset/($dataset)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search UniRef entries
#
# GET /uniref
# operationId: searchUniRef
export def "uniref searchUniRef" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --clusterId: string # UniRef cluster ID. Comma separated values accepted up to 100.
  --clusterName: string # UniRef cluster name
  --dataset: string # UniRef dataset by identity level: UniRef100, UniRef90 or UniRef50
  --repMemberId: string # Representative cluster member's ID. Comma separated values accepted up to 100.
  --repMemberEntryId: string # Representative cluster member's entry ID. Comma separated values accepted up to 100.
  --repMemberProteinName: string # Representative cluster member’s protein name
  --repMemberOrganismName: string # Representative cluster member’s organism name
  --repMemberTaxId: string # Representative cluster member’s taxonomy ID. Comma separated values accepted up to 100.
  --memberId: string # Cluster member’s ID. Comma separated values accepted up to 100.
  --memberEntryId: string # Cluster member's entry ID. Comma separated values accepted up to 100.
  --memberProteinName: string # Cluster member’s protein name
  --memberOrganismName: string # Cluster member’s organism name
  --memberTaxId: string # Cluster member’s taxonomy ID. Comma separated values accepted up to 100.
]: nothing -> table<name: string, property: list<record>, representativeMember: record<dbReference: record, sequence: record>, member: list<record>, id: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "clusterId" $clusterId "scalar") (serialize-qp "clusterName" $clusterName "scalar") (serialize-qp "dataset" $dataset "scalar") (serialize-qp "repMemberId" $repMemberId "scalar") (serialize-qp "repMemberEntryId" $repMemberEntryId "scalar") (serialize-qp "repMemberProteinName" $repMemberProteinName "scalar") (serialize-qp "repMemberOrganismName" $repMemberOrganismName "scalar") (serialize-qp "repMemberTaxId" $repMemberTaxId "scalar") (serialize-qp "memberId" $memberId "scalar") (serialize-qp "memberEntryId" $memberEntryId "scalar") (serialize-qp "memberProteinName" $memberProteinName "scalar") (serialize-qp "memberOrganismName" $memberOrganismName "scalar") (serialize-qp "memberTaxId" $memberTaxId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/uniref" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get LLM protein variants by accession
#
# GET /variant_summary/{accession}
# operationId: getByAccession_12
export def "variant-summary get-by-accession" [
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: table<type: string, category: string, cvId: string, ftId: string, description: string, alternativeSequence: string, begin: string, end: string, molecule: string, ligand: record, ligandPart: record, xrefs: list, evidences: list, dbReferenceType: list, variantType: record, rnaEditingInfo: record, locationType: record, variant: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/variant_summary/($accession)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Llm protein variation
#
# GET /variant_summary
# operationId: search_13
export def "variant-summary search-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --accession: string # UniProt accession(s). Comma separated values accepted up to 100.
  --pmid: string # Organism taxon ID. Comma separated values accepted up to 20.
  --variant: string # Protein variant.
  --summary: string # Woords in summary
]: nothing -> table<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "pmid" $pmid "scalar") (serialize-qp "variant" $variant "scalar") (serialize-qp "summary" $summary "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/variant_summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get natural variants by UniProt accession
#
# GET /variation/{accession}
# operationId: getVariation
export def "variation get" [
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sourcetype: string # Filter by the sourceType for variants: uniprot, large scale study, mixed, clinvar, nci-tcga, cosmic curated, ensembl, gnomad, topmed and exac. Comma separated values accepted up to 2.
  --consequencetype: string # Filter by consequenceType for variants: missense, stop gained or stop lost. Comma separated values accepted up to 2.
  --wildtype: string # Search by specific wildType amino acid. Options: Any single letter amino acid and * for stop codon. Comma separated values accepted up to 20.
  --alternativesequence: string # Filter by the alternativeSequence amino acid. Any single letter amino acid and * for stopcodon and - for deletions. Comma separated values accepted up to 20.
  --location: string # Filter by the amino acid range position in the sequence(s). Any valid amino acid range position within the length of the protein sequence such as 10-60 (start position to end position)
]: nothing -> record<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: table<type: string, category: string, cvId: string, ftId: string, description: string, alternativeSequence: string, begin: string, end: string, molecule: string, ligand: record, ligandPart: record, xrefs: list, evidences: list, dbReferenceType: list, variantType: record, rnaEditingInfo: record, locationType: record, variant: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sourcetype" $sourcetype "scalar") (serialize-qp "consequencetype" $consequencetype "scalar") (serialize-qp "wildtype" $wildtype "scalar") (serialize-qp "alternativesequence" $alternativesequence "scalar") (serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/variation/($accession)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get natural variants by list of accession and its locations
#
# GET /variation/accession_locations/{accession_locations}
# operationId: getVariationForAccessionLocation
export def "variation-accession-locations get" [
  accession_locations: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: table<type: string, category: string, cvId: string, ftId: string, description: string, alternativeSequence: string, begin: string, end: string, molecule: string, ligand: record, ligandPart: record, xrefs: list, evidences: list, dbReferenceType: list, variantType: record, rnaEditingInfo: record, locationType: record, variant: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/variation/accession_locations/($accession_locations)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search natural variants in UniProt
#
# GET /variation
# operationId: search_14
export def "variation search-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-4 # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --sourcetype: string # Filter by the sourceType for variants: uniprot, large scale study, mixed, clinvar, nci-tcga, cosmic curated, ensembl, gnomad, topmed and exac. Comma separated values accepted up to 2.
  --consequencetype: string # Filter by consequenceType for variants: missense, stop gained or stop lost. Comma separated values accepted up to 2.
  --wildtype: string # Search by specific wildType amino acid. Options: Any single letter amino acid and * for stop codon. Comma separated values accepted up to 20.
  --alternativesequence: string # Filter by the alternativeSequence amino acid. Any single letter amino acid and * for stopcodon and - for deletions. Comma separated values accepted up to 20.
  --location: string # Filter by the amino acid range position in the sequence(s). Any valid amino acid range position within the length of the protein sequence such as 10-60 (start position to end position)
  --accession: string # UniProt accession(s). Comma separated values accepted up to 100.
  --disease: string # Search by disease name/ acronym for associated variants , e.g. alzheimer disease 1 or AD1. Partial names allowed.
  --omim: string # Search by MIM ID, e.g. 104300. Comma separated values accepted up to 20.
  --evidence: string # Search by PubMed ID, e.g. 22472873. Comma separated values accepted up to 20.
  --taxid: string # Organism taxon ID. Comma separated values accepted up to 20.
  --dbtype: string # Cross reference database type, e.g, dbSNP, cosmic curate or ClinVar. Comma separated values accepted up to 2.
  --dbid: string # Cross-reference database ID, e.g. rs121918508 for dbSNP, COSM29836 for cosmic curated, rcv61200 for ClinVar. Comma separated values accepted up to 20.
]: nothing -> table<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sourcetype" $sourcetype "scalar") (serialize-qp "consequencetype" $consequencetype "scalar") (serialize-qp "wildtype" $wildtype "scalar") (serialize-qp "alternativesequence" $alternativesequence "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "disease" $disease "scalar") (serialize-qp "omim" $omim "scalar") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "taxid" $taxid "scalar") (serialize-qp "dbtype" $dbtype "scalar") (serialize-qp "dbid" $dbid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/variation" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get natural variants in UniProt by NIH-NCBI SNP database identifier
#
# GET /variation/dbsnp/{dbid}
# operationId: searchByDbSNP
export def "variation-dbsnp searchByDbSNP" [
  dbid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-4 # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --sourcetype: string # Filter by the sourceType for variants: uniprot, large scale study, mixed, clinvar, nci-tcga, cosmic curated, ensembl, gnomad, topmed and exac. Comma separated values accepted up to 2.
  --consequencetype: string # Filter by consequenceType for variants: missense, stop gained or stop lost. Comma separated values accepted up to 2.
  --wildtype: string # Search by specific wildType amino acid. Options: Any single letter amino acid and * for stop codon. Comma separated values accepted up to 20.
  --alternativesequence: string # Filter by the alternativeSequence amino acid. Any single letter amino acid and * for stopcodon and - for deletions. Comma separated values accepted up to 20.
  --location: string # Filter by the amino acid range position in the sequence(s). Any valid amino acid range position within the length of the protein sequence such as 10-60 (start position to end position)
]: nothing -> table<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sourcetype" $sourcetype "scalar") (serialize-qp "consequencetype" $consequencetype "scalar") (serialize-qp "wildtype" $wildtype "scalar") (serialize-qp "alternativesequence" $alternativesequence "scalar") (serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/variation/dbsnp/($dbid)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get natural variants in UniProt by HGVS expression
#
# GET /variation/hgvs/{hgvs}
# operationId: searchByHgvs
export def "variation-hgvs searchByHgvs" [
  hgvs: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-4 # Response content type
  --offset: int # Off set, page starting point, with default value 0 (format: int32, default: 0, e.g. 0)
  --size: int # Page size with default value 100. When page size is -1, it returns all records and offset will be ignored (format: int32, default: 100, e.g. 100)
  --sourcetype: string # Filter by the sourceType for variants: uniprot, large scale study, mixed, clinvar, nci-tcga, cosmic curated, ensembl, gnomad, topmed and exac. Comma separated values accepted up to 2.
  --consequencetype: string # Filter by consequenceType for variants: missense, stop gained or stop lost. Comma separated values accepted up to 2.
  --wildtype: string # Search by specific wildType amino acid. Options: Any single letter amino acid and * for stop codon. Comma separated values accepted up to 20.
  --alternativesequence: string # Filter by the alternativeSequence amino acid. Any single letter amino acid and * for stopcodon and - for deletions. Comma separated values accepted up to 20.
  --location: string # Filter by the amino acid range position in the sequence(s). Any valid amino acid range position within the length of the protein sequence such as 10-60 (start position to end position)
]: nothing -> table<version: string, accession: string, entryName: string, proteinName: string, geneName: string, organismName: string, proteinExistence: string, sequence: string, sequenceChecksum: string, sequenceVersion: int, geteGeneId: string, geteProteinId: string, taxid: int, features: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sourcetype" $sourcetype "scalar") (serialize-qp "consequencetype" $consequencetype "scalar") (serialize-qp "wildtype" $wildtype "scalar") (serialize-qp "alternativesequence" $alternativesequence "scalar") (serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/variation/hgvs/($hgvs)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
