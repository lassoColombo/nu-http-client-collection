# Auto-generated client for CROssBAR Data API v1.0
# Source: https://api.apis.guru/v2/specs/ebi.ac.uk/1.0/swagger.json
# Auth: --token flag or $env.CROSSBAR_DATA_API_TOKEN

const BASE_URL = "https://www.ebi.ac.uk/Tools/crossbar"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CROSSBAR_DATA_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://www.ebi.ac.uk/Tools/crossbar"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "activities get-activities-using-get" } } | get name | first)
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
export def "activities get-activities-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assay-chembl-id: list # assayChemblId
  --limit: int # limit (format: int32, default: 10)
  --molecule-chembl-id: list # moleculeChemblId
  --page: int # page (format: int32, default: 0)
  --pchembl-value: float # pchemblValue (format: double)
  --target-chembl-id: list # targetChemblId
]: nothing -> record<activities: table<assay_chembl_id: string, data_validity_comment: string, molecule_chembl_id: string, pchembl_value: float, standard_flag: bool, standard_relation: string, standard_units: string, standard_value: float, target_chembl_id: string>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assayChemblId" $assay_chembl_id "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "moleculeChemblId" $molecule_chembl_id "multi") (serialize-qp "page" $page "scalar") (serialize-qp "pchemblValue" $pchembl_value "scalar") (serialize-qp "targetChemblId" $target_chembl_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/activities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get ChEMBL assays
#
# GET /assays
# operationId: getAssaysUsingGET
export def "assays get-assays-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assay-chembl-id: list # assayChemblId
  --assay-org: list # assayOrg
  --assay-type: list # assayType
  --limit: int # limit (format: int32, default: 10)
  --page: int # page (format: int32, default: 0)
  --target-chembl-id: list # targetChemblId
]: nothing -> record<assays: table<assay_chembl_id: string, assay_id: string, assay_organism: string, assay_type: string, confidence_score: float, target_chembl_id: string>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assayChemblId" $assay_chembl_id "multi") (serialize-qp "assayOrg" $assay_org "multi") (serialize-qp "assayType" $assay_type "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "targetChemblId" $target_chembl_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/assays" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# drugs collected from Drugbank
#
# GET /drugs
# operationId: getDrugsUsingGET
export def "drugs get-drugs-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accession: list # accession
  --chembl-id: list # chemblId
  --identifier: list # identifier
  --limit: int # limit (format: int32, default: 10)
  --name: list # name
  --page: int # page (format: int32, default: 0)
  --pubchem-cid: list # pubchemCid
]: nothing -> record<drugs: table<alogp: float, canonical_smiles: string, chembl_id: string, full_mwt: float, identifier: string, inchi_key: string, kegg_cid: string, molecule_type: string, name: string, pathway: list, pb_structures: list, polar_surface_area: float, pubchem_cid: string, pubchem_sid: string, standard_inchi: string, targets: list, uniprot_accession: string>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accession" $accession "multi") (serialize-qp "chemblId" $chembl_id "multi") (serialize-qp "identifier" $identifier "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "name" $name "multi") (serialize-qp "page" $page "scalar") (serialize-qp "pubchemCid" $pubchem_cid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/drugs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get EFO diseases data
#
# GET /efo
# operationId: getEFOUsingGET
export def "efo get-efo-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doid: list # doid
  --label: list # label
  --limit: int # limit (format: int32, default: 10)
  --mesh: list # mesh
  --obo-id: list # oboId
  --omim-id: list # omimId
  --page: int # page (format: int32, default: 0)
  --synonym: list # synonym
]: nothing -> record<diseases: table<description: list, doid: list, icd9: list, label: string, mesh: list, ncit: list, obo_id: string, omim: list, short_form: string, snowmed: list, synonyms: list, umls: list>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doid" $doid "multi") (serialize-qp "label" $label "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "mesh" $mesh "multi") (serialize-qp "oboId" $obo_id "multi") (serialize-qp "omimId" $omim_id "multi") (serialize-qp "page" $page "scalar") (serialize-qp "synonym" $synonym "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/efo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get HPO phenotypes data
#
# GET /hpo
# operationId: getHpoUsingGET
export def "hpo get-hpo-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --genesymbol: list # genesymbol
  --hpotermname: list # hpotermname
  --limit: int # limit (format: int32, default: 10)
  --page: int # page (format: int32, default: 0)
  --synonym: list # synonym
]: nothing -> record<hpo: table<db_references: list, gene: list, hpo_id: string, synonyms: list, term_name: string>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "genesymbol" $genesymbol "multi") (serialize-qp "hpotermname" $hpotermname "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "synonym" $synonym "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/hpo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Molecular Interactions collected from IntAct
#
# GET /intact
# operationId: getIntactUsingGET
export def "intact get-intact-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accession: list # accession
  --confidence: float # confidence (format: double)
  --gene: list # gene
  --limit: int # limit (format: int32, default: 10)
  --page: int # page (format: int32, default: 0)
]: nothing -> record<interactions: table<confidence: float, interaction_ac: list, interactor_a: record, interactor_b: record, method: string, source_db: string>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accession" $accession "multi") (serialize-qp "confidence" $confidence "scalar") (serialize-qp "gene" $gene "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/intact" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get ChEMBL molecules
#
# GET /molecules
# operationId: getMoleculesUsingGET
export def "molecules get-molecules-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --canonical-smiles: list # canonicalSmiles
  --inchi-key: list # inchiKey
  --limit: int # limit (format: int32, default: 10)
  --molecule-chembl-id: list # moleculeChemblId
  --page: int # page (format: int32, default: 0)
]: nothing -> record<molecules: table<alogp: float, canonical_smiles: string, chirality: float, full_mwt: float, heavy_atoms_count: int, inchi_key: string, max_phase: int, molecular_species: string, molecular_type: string, molecule_chembl_id: string, parent_chembl_id: string, pref_name: string, prodrug: float, standard_inchi: string, xrefs: list>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "canonicalSmiles" $canonical_smiles "multi") (serialize-qp "inchiKey" $inchi_key "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "moleculeChemblId" $molecule_chembl_id "multi") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/molecules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Proteins collected from Uniprot for selective tax ids  HUMAN(9606), MOUSE(10090), RAT(10116), BOVINE(9913), ESCHERICHIA_COLI(83333), SUS_SCROFA(9823), MYCOBACTERIUM_TUBERCULOSIS(83332), ORYCTOLAGUS_CUNICULUS(9986), SACCHAROMYCES_CEREVISIAE(559292), CVHSA(694009) & SARS2(2697049)
#
# GET /proteins
# operationId: getProteinsUsingGET
export def "proteins get-proteins-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accession: list # accession
  --ec: list # ec
  --full-name: list # fullName
  --gene: list # gene
  --go: list # go
  --interpro: list # interpro
  --limit: int # limit (format: int32, default: 10)
  --omim: list # omim
  --orphanet: list # orphanet
  --page: int # page (format: int32, default: 0)
  --pfam: list # pfam
  --reactome: list # reactome
  --tax-id: list # taxId
]: nothing -> record<pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>, proteins: table<accession: string, chromosome: string, crossreferences: record, ec_numbers: list, features: record, full_name: string, genes: list, interactions: list, length: float, mass: float, tax_id: int, variations: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accession" $accession "multi") (serialize-qp "ec" $ec "multi") (serialize-qp "fullName" $full_name "multi") (serialize-qp "gene" $gene "multi") (serialize-qp "go" $go "multi") (serialize-qp "interpro" $interpro "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "omim" $omim "multi") (serialize-qp "orphanet" $orphanet "multi") (serialize-qp "page" $page "scalar") (serialize-qp "pfam" $pfam "multi") (serialize-qp "reactome" $reactome "multi") (serialize-qp "taxId" $tax_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/proteins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pubchem bioassays
#
# GET /pubchem/bioassays
# operationId: getBioassaysUsingGET
export def "pubchem-bioassays get-bioassays-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accession: list # accession
  --assay-pubchem-id: list # assayPubchemId
  --limit: int # limit (format: int32, default: 1)
  --ncbi-protein-id: list # ncbiProteinId
  --page: int # page (format: int32, default: 0)
]: nothing -> record<bioassays: table<bioAssay: record, sidRelatedData: list>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accession" $accession "multi") (serialize-qp "assayPubchemId" $assay_pubchem_id "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "ncbiProteinId" $ncbi_protein_id "multi") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pubchem/bioassays" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pubchem bioassays associated to particular substance ids (sid) & outcome
#
# GET /pubchem/bioassays/sids
# operationId: getBioassaysUsingGET_1
export def "pubchem-bioassays-sids get-bioassays-using-get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # limit (format: int32, default: 10)
  --outcome: string # outcome
  --page: int # page (format: int32, default: 0)
  --sids: list # sids
]: nothing -> record<bioassays: table<bioAssay: record, sidRelatedData: list>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "outcome" $outcome "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sids" $sids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/pubchem/bioassays/sids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pubchem compounds
#
# GET /pubchem/compounds
# operationId: getCompoundsUsingGET
export def "pubchem-compounds get-compounds-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --canonical-smiles: list # canonicalSmiles
  --cid: list # cid
  --inchi-key: list # inchiKey
  --limit: int # limit (format: int32, default: 10)
  --page: int # page (format: int32, default: 0)
]: nothing -> record<compounds: table<alogp: float, atom_chiral_count: int, atom_chiral_def_count: int, bond_chiral_count: int, bond_chiral_def_count: int, bond_chiral_undef_count: int, canonical_smiles: string, cid: int, covalent_unit_count: int, finger_print: string, full_mwt: float, heavy_atoms_count: int, inchi_key: string, isotope_atom_count: int, polar_surface_area: float, standard_inchi: string, tautomers_count: int>, pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "canonicalSmiles" $canonical_smiles "multi") (serialize-qp "cid" $cid "multi") (serialize-qp "inchiKey" $inchi_key "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pubchem/compounds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pubchem substances
#
# GET /pubchem/substances
# operationId: getSubstancesUsingGET
export def "pubchem-substances get-substances-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cid: list # cid
  --limit: int # limit (format: int32, default: 10)
  --page: int # page (format: int32, default: 0)
  --sid: list # sid
]: nothing -> record<pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>, substances: table<chembl_cmpd_xref: string, cids: list, sid: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cid" $cid "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sid" $sid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/pubchem/substances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get ChEMBL targets
#
# GET /targets
# operationId: getTargetsUsingGET
export def "targets get-targets-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accession: list # accession
  --limit: int # limit (format: int32, default: 10)
  --page: int # page (format: int32, default: 0)
  --target-ids: list # targetIds
]: nothing -> record<pageMeta: record<currentElements: int, currentPage: int, limit: int, totalElements: int, totalPages: int>, targets: table<accession: string, target_chembl_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accession" $accession "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "targetIds" $target_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/targets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
