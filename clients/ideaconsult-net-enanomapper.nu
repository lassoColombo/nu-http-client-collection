# Auto-generated client for eNanoMapper database v4.0.0
# Source: https://api.apis.guru/v2/specs/ideaconsult.net/enanomapper/4.0.0/openapi.json
# Auth: --token flag or $env.ENANOMAPPER_DATABASE_TOKEN

const BASE_URL = "https://api.ideaconsult.net/enanomapper"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ENANOMAPPER_DATABASE_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.ideaconsult.net/enanomapper"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["byassay" "bycitation" "byinvestigation" "byprovider" "bystructure_inchikey" "bystructure_name" "bystructure_smiles" "bystudytype" "bysubstance" "bysubstance_name" "bysubstance_type"] }
def accept-completer [] { ["application/json" "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" "application/x-javascript" "text/csv" "text/plain"] }
def type-completer-1 [] { ["mol" "smiles" "url"] }
def top-completer [] { ["ECOTOX" "ENV FATE" "EXPOSURE" "P-CHEM" "TOX"] }
def type-completer-2 [] { ["CompTox" "DOI" "citation" "citationowner" "endpointcategory" "facet" "isRobustStudy" "like" "name" "owner_name" "owner_uuid" "params" "purposeFlag" "reference" "regexp" "related" "reliability" "studyResultType" "substancetype" "topcategory" "uuif"] }
def wt-completer [] { ["csv" "json" "xml"] }
def accept-completer-1 [] { ["application/json" "application/xml"] }
def wt-completer-1 [] { ["json" "xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "enm-investigation get" } } | get name | first)
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

# Details of multiple studies
#
# GET /enm/{db}/investigation
# operationId: getInvestigationResults
export def "enm-investigation get" [
  db: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer # query type (e.g. bystudytype)
  --search: string # Search parameter, UUID of the investigation or a substance (e.g. PC_GRANULOMETRY_SECTION)
  --inchikey: string # Search parameter, InChI key(s) of the substance component(s), comma delimited (e.g. YUYCVXFAYWRXLS-UHFFFAOYSA-N)
  --id: string # Search parameter, chemical structure or substance identifier(s), comma delimited
  --page: int # Starting page (e.g. 0)
  --pagesize: int # Page size (e.g. 10)
]: nothing -> record<_childDocuments_: record, assay: string, document_uuid: string, effectendpoint: string, endpoint: string, endpointcategory: string, err: float, errQualifier: string, guidance: string, investigation: string, loQualifier: string, loValue: float, name: string, owner_name: string, publicname: string, reference: string, reference_owner: string, reference_year: string, resulttype: string, s_uuid: string, studyResultType: string, substanceType: string, textValue: string, topcategory: string, type_s: string, unit: string, upQualifier: string, upValue: float, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "inchikey" $inchikey "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enm/($db)/investigation" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Exact chemical structure search
#
# GET /enm/{db}/query/compound/{term}/{representation}
# Docs: http://ambit.sf.net — Learn more about operations provided by this API.
# operationId: searchByIdentifier
export def "enm-query-compound searchByIdentifier" [
  db: string
  term: string
  representation: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Compound identifier (SMILES, InChI, name, registry identifiers)
  --b64search: string # Base64 encoded mol file; if included, will be used instead of the 'search' parameter
  --casesens: oneof<nothing, bool> # Case sensitive search if yes
  --bundle-uri: string # Bundle URI
  --sameas: string # Ontology URI to define groups of columns
  --page: int # Starting page (e.g. 0)
  --pagesize: int # Page size (e.g. 10)
]: nothing -> record<dataEntry: record, feature: record, model_uri: string, query: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "b64search" $b64search "scalar") (serialize-qp "casesens" $casesens "scalar") (serialize-qp "bundle_uri" $bundle_uri "scalar") (serialize-qp "sameas" $sameas "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enm/($db)/query/compound/($term)/($representation)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Exact similarity search
#
# GET /enm/{db}/query/similarity
# Docs: http://ambit.sf.net — Learn more about operations provided by this API.
# operationId: searchBySimilarity
export def "enm-query-similarity searchBySimilarity" [
  db: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Compound identifier (SMILES, InChI, name, registry identifiers)
  --b64search: string # Base64 encoded mol file; if included, will be used instead of the 'search' parameter
  --type: string@type-completer-1 # Defines the expected content of the search parameter
  --threshold: float # Similarity threshold
  --dataset-uri: string # Restrict the search within the AMBIT dataset specified with the URI
  --filterBySubstance: oneof<nothing, bool> # Restrict the search within the set of structures with assigned substances
  --bundle-uri: string # If the structure is used in the specified bundle URI, the selection tag will be returned
  --sameas: string # Ontology URI to define groups of columns
  --mol: oneof<nothing, bool> # Only for application/json; to include mol as JSON field
  --page: int # Starting page (e.g. 0)
  --pagesize: int # Page size (e.g. 10)
]: nothing -> record<dataEntry: record, feature: record, model_uri: string, query: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "b64search" $b64search "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "threshold" $threshold "scalar") (serialize-qp "dataset_uri" $dataset_uri "scalar") (serialize-qp "filterBySubstance" $filterBySubstance "scalar") (serialize-qp "bundle_uri" $bundle_uri "scalar") (serialize-qp "sameas" $sameas "scalar") (serialize-qp "mol" $mol "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enm/($db)/query/similarity" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Substructure search
#
# GET /enm/{db}/query/smarts
# Docs: http://ambit.sf.net — Learn more about operations provided by this API.
# operationId: searchBySmarts
export def "enm-query-smarts searchBySmarts" [
  db: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Compound identifier (SMILES, InChI, name, registry identifiers)
  --b64search: string # Base64 encoded mol file; if included, will be used instead of the 'search' parameter
  --type: string@type-completer-1 # Defines the expected content of the search parameter
  --dataset-uri: string # Restrict the search within the AMBIT dataset specified with the URI
  --filterBySubstance: oneof<nothing, bool> # Restrict the search within the set of structures with assigned substances
  --bundle-uri: string # If the structure is used in the specified bundle URI, the selection tag will be returned
  --sameas: string # Ontology URI to define groups of columns
  --mol: oneof<nothing, bool> # Only for application/json; to include mol as JSON field
  --page: int # Starting page (e.g. 0)
  --pagesize: int # Page size (e.g. 10)
]: nothing -> record<dataEntry: record, feature: record, model_uri: string, query: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "b64search" $b64search "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "dataset_uri" $dataset_uri "scalar") (serialize-qp "filterBySubstance" $filterBySubstance "scalar") (serialize-qp "bundle_uri" $bundle_uri "scalar") (serialize-qp "sameas" $sameas "scalar") (serialize-qp "mol" $mol "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enm/($db)/query/smarts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search endpoint summary
#
# GET /enm/{db}/query/study
# operationId: getEndpointSummary
export def "enm-query-study get" [
  db: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: string@top-completer # Top endpoint category
  --category: string # Endpoint category (The value in the protocol.category.code field)
]: nothing -> record<facet: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "top" $top "scalar") (serialize-qp "category" $category "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enm/($db)/query/study" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List substances
#
# GET /enm/{db}/substance
# operationId: getSubstances
export def "enm-substance list" [
  db: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search parameter
  --type: string@type-completer-2
  --compound-uri: string # If type=related finds all substances containing this compound; if typ =reference - finds all substances with this compound as reference structure
  --bundle-uri: string # Retrieves if selected in this bundle
  --addDummySubstance: oneof<nothing, bool> # Adds a compound record as substance in JSON; only if type=related
  --studysummary: oneof<nothing, bool> # If true retrieves study summary for each substance
  --page: int # Starting page (e.g. 0)
  --pagesize: int # Page size (e.g. 10)
]: nothing -> record<substance: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "compound_uri" $compound_uri "scalar") (serialize-qp "bundle_uri" $bundle_uri "scalar") (serialize-qp "addDummySubstance" $addDummySubstance "scalar") (serialize-qp "studysummary" $studysummary "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enm/($db)/substance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a substance
#
# GET /enm/{db}/substance/{uuid}
# operationId: getSubstanceByUUID
export def "enm-substance get" [
  db: string
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --property-uris: string # Property URIs
  --page: int # Starting page (e.g. 0)
  --pagesize: int # Page size (e.g. 10)
]: nothing -> record<substance: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "property_uris[]" $property_uris "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enm/($db)/substance/($uuid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Substance composition
#
# GET /enm/{db}/substance/{uuid}/composition
# operationId: getSubstanceComposition
export def "enm-substance-composition get" [
  db: string
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # true (Show all compositions) false (do not show hidden compositions)
  --page: int # Starting page (e.g. 0)
  --pagesize: int # Page size (e.g. 10)
]: nothing -> record<composition: record, feature: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enm/($db)/substance/($uuid)/composition" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get substance composition as a dataset
#
# GET /enm/{db}/substance/{uuid}/structures
# operationId: getSubstanceStructures
export def "enm-substance-structures get" [
  db: string
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Starting page (e.g. 0)
  --pagesize: int # Page size (e.g. 10)
]: nothing -> record<dataEntry: record, feature: record, model_uri: string, query: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enm/($db)/substance/($uuid)/structures" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get substance study
#
# GET /enm/{db}/substance/{uuid}/study
# operationId: getSubstanceStudy
export def "enm-substance-study get" [
  db: string
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: string@top-completer # Top endpoint category
  --category: string # Endpoint category (The value in the protocol.category.code field)
  --property-uri: string # Property URI https://data.enanomapper.net/property/{UUID} , see Property service
  --property: string # Property UUID
  --investigation-uuid: string # Investigation UUID, a code to link different studies
  --page: int # Starting page (e.g. 0)
  --pagesize: int # Page size (e.g. 10)
]: nothing -> record<study: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "top" $top "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "property_uri" $property_uri "scalar") (serialize-qp "property" $property "scalar") (serialize-qp "investigation_uuid" $investigation_uuid "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enm/($db)/substance/($uuid)/study" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get study summary for the substance
#
# GET /enm/{db}/substance/{uuid}/studySummary
# operationId: getSubstanceStudySummary
export def "enm-substance-study-summary get" [
  db: string
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: string@top-completer # Top endpoint category
  --category: string # Endpoint category (The value in the protocol.category.code field)
  --property-uri: string # Property URI https://data.enanomapper.net/property/{UUID} , see Property service
  --property: string # Property UUID, see Property service
  --result: oneof<nothing, bool> # If true will group by topcategory,endpointcategory,interpretation result
  --page: int # Starting page (e.g. 0)
  --pagesize: int # Page size (e.g. 10)
]: nothing -> record<facet: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "top" $top "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "property_uri" $property_uri "scalar") (serialize-qp "property" $property "scalar") (serialize-qp "result" $result "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enm/($db)/substance/($uuid)/studySummary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Apache Solr powered search
#
# GET /select
# operationId: solrquery_get
export def "select get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --q: string # The query (e.g. *:*)
  --fq: string # Filter query
  --fl: string # Field list (e.g. *)
  --start: int # Starting page (e.g. 0)
  --rows: int # Page size (e.g. 10)
  --wt: string@wt-completer # Response format (default: xml, e.g. json)
]: nothing -> record<response: record<docs: list<record>, maxScore: float, numFound: int, start: int>, responseHeader: record<QTime: int, params: record, status: int, zkConnected: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "fq" $fq "scalar") (serialize-qp "fl" $fl "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "wt" $wt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/select" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Apache Solr powered search
#
# POST /select
# operationId: solrquery_post
# --params shape: {fl?: list, rows?: int}
export def "select post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --wt: string@wt-completer-1 # Response format (default: xml, e.g. json)
  --facet: record
  --params: record # shape: {fl?: list, rows?: int}
]: any -> record<response: record<docs: list<record>, maxScore: float, numFound: int, start: int>, responseHeader: record<QTime: int, params: record, status: int, zkConnected: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wt" $wt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/select" $qp)
  let body = {facet: $facet, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
