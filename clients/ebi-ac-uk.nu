# Auto-generated client for CROssBAR Data API v1.0
# Source: https://api.apis.guru/v2/specs/ebi.ac.uk/1.0/swagger.json
# Auth: --token flag or $env.CROSSBAR_DATA_API_TOKEN

const BASE_URL = "https://www.ebi.ac.uk/Tools/crossbar"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CROSSBAR_DATA_API_TOKEN | default "" }
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

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://www.ebi.ac.uk/Tools/crossbar"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "activities get-using" } } | get name | first)
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

# Get ChEMBL activities
#
# GET /activities
# operationId: getActivitiesUsingGET
export def "activities get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assay-chembl-id: list<string> # assayChemblId
  --limit: int # limit (format: int32, default: 10)
  --molecule-chembl-id: list<string> # moleculeChemblId
  --page: int # page (format: int32, default: 0)
  --pchembl-value: float # pchemblValue (format: double)
  --target-chembl-id: list<string> # targetChemblId
]: nothing -> record<activities: table<assay_chembl_id: string, data_validity_comment: string, molecule_chembl_id: string, pchembl_value: float, standard_flag: bool, standard_relation: string, standard_units: string, standard_value: float, target_chembl_id: string>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assayChemblId" $assay_chembl_id "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "moleculeChemblId" $molecule_chembl_id "multi") (serialize-qp "page" $page "scalar") (serialize-qp "pchemblValue" $pchembl_value "scalar") (serialize-qp "targetChemblId" $target_chembl_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/activities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"assayChemblId": $assay_chembl_id, "limit": $limit, "moleculeChemblId": $molecule_chembl_id, "page": $page, "pchemblValue": $pchembl_value, "targetChemblId": $target_chembl_id} | compact), body: null}
}

# Get ChEMBL assays
#
# GET /assays
# operationId: getAssaysUsingGET
export def "assays get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assay-chembl-id: list<string> # assayChemblId
  --assay-org: list<string> # assayOrg
  --assay-type: list<string> # assayType
  --limit: int # limit (format: int32, default: 10)
  --page: int # page (format: int32, default: 0)
  --target-chembl-id: list<string> # targetChemblId
]: nothing -> record<assays: table<assay_chembl_id: string, assay_id: string, assay_organism: string, assay_type: string, confidence_score: float, target_chembl_id: string>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assayChemblId" $assay_chembl_id "multi") (serialize-qp "assayOrg" $assay_org "multi") (serialize-qp "assayType" $assay_type "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "targetChemblId" $target_chembl_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/assays" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"assayChemblId": $assay_chembl_id, "assayOrg": $assay_org, "assayType": $assay_type, "limit": $limit, "page": $page, "targetChemblId": $target_chembl_id} | compact), body: null}
}

# drugs collected from Drugbank
#
# GET /drugs
# operationId: getDrugsUsingGET
export def "drugs get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accession: list<string> # accession
  --chembl-id: list<string> # chemblId
  --identifier: list<string> # identifier
  --limit: int # limit (format: int32, default: 10)
  --name: list<string> # name
  --page: int # page (format: int32, default: 0)
  --pubchem-cid: list<string> # pubchemCid
]: nothing -> record<drugs: table<alogp: float, canonical_smiles: string, chembl_id: string, full_mwt: float, identifier: string, inchi_key: string, kegg_cid: string, molecule_type: string, name: string, pathway: list, pb_structures: list, polar_surface_area: float, pubchem_cid: string, pubchem_sid: string, standard_inchi: string, targets: list, uniprot_accession: string>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accession" $accession "multi") (serialize-qp "chemblId" $chembl_id "multi") (serialize-qp "identifier" $identifier "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "name" $name "multi") (serialize-qp "page" $page "scalar") (serialize-qp "pubchemCid" $pubchem_cid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/drugs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accession": $accession, "chemblId": $chembl_id, "identifier": $identifier, "limit": $limit, "name": $name, "page": $page, "pubchemCid": $pubchem_cid} | compact), body: null}
}

# Get EFO diseases data
#
# GET /efo
# operationId: getEFOUsingGET
export def "efo get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --doid: list<string> # doid
  --label: list<string> # label
  --limit: int # limit (format: int32, default: 10)
  --mesh: list<string> # mesh
  --obo-id: list<string> # oboId
  --omim-id: list<string> # omimId
  --page: int # page (format: int32, default: 0)
  --synonym: list<string> # synonym
]: nothing -> record<diseases: table<description: list, doid: list, icd9: list, label: string, mesh: list, ncit: list, obo_id: string, omim: list, short_form: string, snowmed: list, synonyms: list, umls: list>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doid" $doid "multi") (serialize-qp "label" $label "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "mesh" $mesh "multi") (serialize-qp "oboId" $obo_id "multi") (serialize-qp "omimId" $omim_id "multi") (serialize-qp "page" $page "scalar") (serialize-qp "synonym" $synonym "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/efo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"doid": $doid, "label": $label, "limit": $limit, "mesh": $mesh, "oboId": $obo_id, "omimId": $omim_id, "page": $page, "synonym": $synonym} | compact), body: null}
}

# Get HPO phenotypes data
#
# GET /hpo
# operationId: getHpoUsingGET
export def "hpo get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --genesymbol: list<string> # genesymbol
  --hpotermname: list<string> # hpotermname
  --limit: int # limit (format: int32, default: 10)
  --page: int # page (format: int32, default: 0)
  --synonym: list<string> # synonym
]: nothing -> record<hpo: table<db_references: list, gene: list, hpo_id: string, synonyms: list, term_name: string>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "genesymbol" $genesymbol "multi") (serialize-qp "hpotermname" $hpotermname "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "synonym" $synonym "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/hpo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"genesymbol": $genesymbol, "hpotermname": $hpotermname, "limit": $limit, "page": $page, "synonym": $synonym} | compact), body: null}
}

# Molecular Interactions collected from IntAct
#
# GET /intact
# operationId: getIntactUsingGET
export def "intact get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accession: list<string> # accession
  --confidence: float # confidence (format: double)
  --gene: list<string> # gene
  --limit: int # limit (format: int32, default: 10)
  --page: int # page (format: int32, default: 0)
]: nothing -> record<interactions: table<confidence: float, interaction_ac: list, interactor_a: record, interactor_b: record, method: string, source_db: string>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accession" $accession "multi") (serialize-qp "confidence" $confidence "scalar") (serialize-qp "gene" $gene "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/intact" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accession": $accession, "confidence": $confidence, "gene": $gene, "limit": $limit, "page": $page} | compact), body: null}
}

# Get ChEMBL molecules
#
# GET /molecules
# operationId: getMoleculesUsingGET
export def "molecules get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --canonical-smiles: list<string> # canonicalSmiles
  --inchi-key: list<string> # inchiKey
  --limit: int # limit (format: int32, default: 10)
  --molecule-chembl-id: list<string> # moleculeChemblId
  --page: int # page (format: int32, default: 0)
]: nothing -> record<molecules: table<alogp: float, canonical_smiles: string, chirality: float, full_mwt: float, heavy_atoms_count: int, inchi_key: string, max_phase: int, molecular_species: string, molecular_type: string, molecule_chembl_id: string, parent_chembl_id: string, pref_name: string, prodrug: float, standard_inchi: string, xrefs: list>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "canonicalSmiles" $canonical_smiles "multi") (serialize-qp "inchiKey" $inchi_key "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "moleculeChemblId" $molecule_chembl_id "multi") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/molecules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"canonicalSmiles": $canonical_smiles, "inchiKey": $inchi_key, "limit": $limit, "moleculeChemblId": $molecule_chembl_id, "page": $page} | compact), body: null}
}

# Proteins collected from Uniprot for selective tax ids HUMAN(9606), MOUSE(10090), RAT(10116), BOVINE(9913), ESCHERICHIA_COLI(83333), SUS_SCROFA(9823), MYCOBACTERIUM_TUBERCULOSIS(83332), ORYCTOLAGUS_CUNICULUS(9986), SACCHAROMYCES_CEREVISIAE(559292), CVHSA(694009) & SARS2(2697049)
#
# GET /proteins
# operationId: getProteinsUsingGET
export def "proteins get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accession: list<string> # accession
  --ec: list<string> # ec
  --full-name: list<string> # fullName
  --gene: list<string> # gene
  --go: list<string> # go
  --interpro: list<string> # interpro
  --limit: int # limit (format: int32, default: 10)
  --omim: list<string> # omim
  --orphanet: list<string> # orphanet
  --page: int # page (format: int32, default: 0)
  --pfam: list<string> # pfam
  --reactome: list<string> # reactome
  --tax-id: list<int> # taxId
]: nothing -> record<pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>, proteins: table<accession: string, chromosome: string, crossreferences: record, ec_numbers: list, features: record, full_name: string, genes: list, interactions: list, length: float, mass: float, tax_id: int, variations: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accession" $accession "multi") (serialize-qp "ec" $ec "multi") (serialize-qp "fullName" $full_name "multi") (serialize-qp "gene" $gene "multi") (serialize-qp "go" $go "multi") (serialize-qp "interpro" $interpro "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "omim" $omim "multi") (serialize-qp "orphanet" $orphanet "multi") (serialize-qp "page" $page "scalar") (serialize-qp "pfam" $pfam "multi") (serialize-qp "reactome" $reactome "multi") (serialize-qp "taxId" $tax_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/proteins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accession": $accession, "ec": $ec, "fullName": $full_name, "gene": $gene, "go": $go, "interpro": $interpro, "limit": $limit, "omim": $omim, "orphanet": $orphanet, "page": $page, "pfam": $pfam, "reactome": $reactome, "taxId": $tax_id} | compact), body: null}
}

# Get pubchem bioassays
#
# GET /pubchem/bioassays
# operationId: getBioassaysUsingGET
export def "pubchem-bioassays get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accession: list<string> # accession
  --assay-pubchem-id: list<string> # assayPubchemId
  --limit: int # limit (format: int32, default: 1)
  --ncbi-protein-id: list<string> # ncbiProteinId
  --page: int # page (format: int32, default: 0)
]: nothing -> record<bioassays: table<bioAssay: record, sidRelatedData: list>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accession" $accession "multi") (serialize-qp "assayPubchemId" $assay_pubchem_id "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "ncbiProteinId" $ncbi_protein_id "multi") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pubchem/bioassays" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accession": $accession, "assayPubchemId": $assay_pubchem_id, "limit": $limit, "ncbiProteinId": $ncbi_protein_id, "page": $page} | compact), body: null}
}

# Get pubchem bioassays associated to particular substance ids (sid) & outcome
#
# GET /pubchem/bioassays/sids
# operationId: getBioassaysUsingGET_1
export def "pubchem-bioassays-sids get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # limit (format: int32, default: 10)
  --outcome: string # outcome
  --page: int # page (format: int32, default: 0)
  --sids: list<string> # sids
]: nothing -> record<bioassays: table<bioAssay: record, sidRelatedData: list>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "outcome" $outcome "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sids" $sids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/pubchem/bioassays/sids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "outcome": $outcome, "page": $page, "sids": $sids} | compact), body: null}
}

# Get pubchem compounds
#
# GET /pubchem/compounds
# operationId: getCompoundsUsingGET
export def "pubchem-compounds get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --canonical-smiles: list<string> # canonicalSmiles
  --cid: list<string> # cid
  --inchi-key: list<string> # inchiKey
  --limit: int # limit (format: int32, default: 10)
  --page: int # page (format: int32, default: 0)
]: nothing -> record<compounds: table<alogp: float, atom_chiral_count: int, atom_chiral_def_count: int, bond_chiral_count: int, bond_chiral_def_count: int, bond_chiral_undef_count: int, canonical_smiles: string, cid: int, covalent_unit_count: int, finger_print: string, full_mwt: float, heavy_atoms_count: int, inchi_key: string, isotope_atom_count: int, polar_surface_area: float, standard_inchi: string, tautomers_count: int>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "canonicalSmiles" $canonical_smiles "multi") (serialize-qp "cid" $cid "multi") (serialize-qp "inchiKey" $inchi_key "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pubchem/compounds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"canonicalSmiles": $canonical_smiles, "cid": $cid, "inchiKey": $inchi_key, "limit": $limit, "page": $page} | compact), body: null}
}

# Get pubchem substances
#
# GET /pubchem/substances
# operationId: getSubstancesUsingGET
export def "pubchem-substances get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cid: list<string> # cid
  --limit: int # limit (format: int32, default: 10)
  --page: int # page (format: int32, default: 0)
  --sid: list<string> # sid
]: nothing -> record<pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>, substances: table<chembl_cmpd_xref: string, cids: list, sid: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cid" $cid "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sid" $sid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/pubchem/substances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"cid": $cid, "limit": $limit, "page": $page, "sid": $sid} | compact), body: null}
}

# Get ChEMBL targets
#
# GET /targets
# operationId: getTargetsUsingGET
export def "targets get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accession: list<string> # accession
  --limit: int # limit (format: int32, default: 10)
  --page: int # page (format: int32, default: 0)
  --target-ids: list<string> # targetIds
]: nothing -> record<pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>, targets: table<accession: string, target_chembl_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accession" $accession "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "targetIds" $target_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/targets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accession": $accession, "limit": $limit, "page": $page, "targetIds": $target_ids} | compact), body: null}
}
