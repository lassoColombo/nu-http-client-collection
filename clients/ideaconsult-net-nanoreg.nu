# Auto-generated client for eNanoMapper database v4.0.0
# Source: https://api.apis.guru/v2/specs/ideaconsult.net/nanoreg/4.0.0/openapi.json
# Auth: --token flag or $env.ENANOMAPPER_DATABASE_TOKEN

const BASE_URL = "https://api.ideaconsult.net/nanoreg1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o ENANOMAPPER_DATABASE_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.ideaconsult.net/nanoreg1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["byassay" "bycitation" "byinvestigation" "byprovider" "bystructure_inchikey" "bystructure_name" "bystructure_smiles" "bystudytype" "bysubstance" "bysubstance_name" "bysubstance_type"] }
def accept-completer [] { ["application/json" "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" "application/x-javascript" "text/csv" "text/plain"] }
def type-completer-1 [] { ["mol" "smiles" "url"] }
def top-completer [] { ["ECOTOX" "ENV FATE" "EXPOSURE" "P-CHEM" "TOX"] }
def type-completer-2 [] { ["CompTox" "DOI" "citation" "citationowner" "endpointcategory" "facet" "isRobustStudy" "like" "name" "owner_name" "owner_uuid" "params" "purposeFlag" "reference" "regexp" "related" "reliability" "studyResultType" "substancetype" "topcategory" "uuif"] }
def wt-completer [] { ["json" "xml"] }
def accept-completer-1 [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "enm-investigation get-results" } } | get name | first)
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
export def "enm-investigation get-results" [
  db: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($db | is-empty) { error make --unspanned { msg: "path parameter 'db' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "inchikey" $inchikey "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({db: (encode-path-segment $db)} | format pattern "/enm/{db}/investigation") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "search": $search, "inchikey": $inchikey, "id": $id, "page": $page, "pagesize": $pagesize} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Exact chemical structure search
#
# GET /enm/{db}/query/compound/{term}/{representation}
# Docs: http://ambit.sf.net — Learn more about operations provided by this API.
# operationId: searchByIdentifier
export def "enm-query-compound list-by-identifier" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($db | is-empty) { error make --unspanned { msg: "path parameter 'db' must be non-empty" } }
  if ($term | is-empty) { error make --unspanned { msg: "path parameter 'term' must be non-empty" } }
  if ($representation | is-empty) { error make --unspanned { msg: "path parameter 'representation' must be non-empty" } }
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "b64search" $b64search "scalar") (serialize-qp "casesens" $casesens "scalar") (serialize-qp "bundle_uri" $bundle_uri "scalar") (serialize-qp "sameas" $sameas "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({db: (encode-path-segment $db), term: (encode-path-segment $term), representation: (encode-path-segment $representation)} | format pattern "/enm/{db}/query/compound/{term}/{representation}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"search": $search, "b64search": $b64search, "casesens": $casesens, "bundle_uri": $bundle_uri, "sameas": $sameas, "page": $page, "pagesize": $pagesize} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Exact similarity search
#
# GET /enm/{db}/query/similarity
# Docs: http://ambit.sf.net — Learn more about operations provided by this API.
# operationId: searchBySimilarity
export def "enm-query-similarity list" [
  db: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Compound identifier (SMILES, InChI, name, registry identifiers)
  --b64search: string # Base64 encoded mol file; if included, will be used instead of the 'search' parameter
  --type: string@type-completer-1 # Defines the expected content of the search parameter
  --threshold: float # Similarity threshold
  --dataset-uri: string # Restrict the search within the AMBIT dataset specified with the URI
  --filter-by-substance: oneof<nothing, bool> # Restrict the search within the set of structures with assigned substances
  --bundle-uri: string # If the structure is used in the specified bundle URI, the selection tag will be returned
  --sameas: string # Ontology URI to define groups of columns
  --mol: oneof<nothing, bool> # Only for application/json; to include mol as JSON field
  --page: int # Starting page (e.g. 0)
  --pagesize: int # Page size (e.g. 10)
]: nothing -> record<dataEntry: record, feature: record, model_uri: string, query: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db | is-empty) { error make --unspanned { msg: "path parameter 'db' must be non-empty" } }
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "b64search" $b64search "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "threshold" $threshold "scalar") (serialize-qp "dataset_uri" $dataset_uri "scalar") (serialize-qp "filterBySubstance" $filter_by_substance "scalar") (serialize-qp "bundle_uri" $bundle_uri "scalar") (serialize-qp "sameas" $sameas "scalar") (serialize-qp "mol" $mol "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({db: (encode-path-segment $db)} | format pattern "/enm/{db}/query/similarity") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"search": $search, "b64search": $b64search, "type": $type, "threshold": $threshold, "dataset_uri": $dataset_uri, "filterBySubstance": $filter_by_substance, "bundle_uri": $bundle_uri, "sameas": $sameas, "mol": $mol, "page": $page, "pagesize": $pagesize} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Substructure search
#
# GET /enm/{db}/query/smarts
# Docs: http://ambit.sf.net — Learn more about operations provided by this API.
# operationId: searchBySmarts
export def "enm-query-smarts list" [
  db: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Compound identifier (SMILES, InChI, name, registry identifiers)
  --b64search: string # Base64 encoded mol file; if included, will be used instead of the 'search' parameter
  --type: string@type-completer-1 # Defines the expected content of the search parameter
  --dataset-uri: string # Restrict the search within the AMBIT dataset specified with the URI
  --filter-by-substance: oneof<nothing, bool> # Restrict the search within the set of structures with assigned substances
  --bundle-uri: string # If the structure is used in the specified bundle URI, the selection tag will be returned
  --sameas: string # Ontology URI to define groups of columns
  --mol: oneof<nothing, bool> # Only for application/json; to include mol as JSON field
  --page: int # Starting page (e.g. 0)
  --pagesize: int # Page size (e.g. 10)
]: nothing -> record<dataEntry: record, feature: record, model_uri: string, query: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db | is-empty) { error make --unspanned { msg: "path parameter 'db' must be non-empty" } }
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "b64search" $b64search "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "dataset_uri" $dataset_uri "scalar") (serialize-qp "filterBySubstance" $filter_by_substance "scalar") (serialize-qp "bundle_uri" $bundle_uri "scalar") (serialize-qp "sameas" $sameas "scalar") (serialize-qp "mol" $mol "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({db: (encode-path-segment $db)} | format pattern "/enm/{db}/query/smarts") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"search": $search, "b64search": $b64search, "type": $type, "dataset_uri": $dataset_uri, "filterBySubstance": $filter_by_substance, "bundle_uri": $bundle_uri, "sameas": $sameas, "mol": $mol, "page": $page, "pagesize": $pagesize} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search endpoint summary
#
# GET /enm/{db}/query/study
# operationId: getEndpointSummary
export def "enm-query-study get-endpoint-summary" [
  db: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: string@top-completer # Top endpoint category
  --category: string # Endpoint category (The value in the protocol.category.code field)
]: nothing -> record<facet: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db | is-empty) { error make --unspanned { msg: "path parameter 'db' must be non-empty" } }
  let qp = [(serialize-qp "top" $top "scalar") (serialize-qp "category" $category "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({db: (encode-path-segment $db)} | format pattern "/enm/{db}/query/study") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"top": $top, "category": $category} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search parameter
  --type: string@type-completer-2
  --compound-uri: string # If type=related finds all substances containing this compound; if typ =reference - finds all substances with this compound as reference structure
  --bundle-uri: string # Retrieves if selected in this bundle
  --add-dummy-substance: oneof<nothing, bool> # Adds a compound record as substance in JSON; only if type=related
  --studysummary: oneof<nothing, bool> # If true retrieves study summary for each substance
  --page: int # Starting page (e.g. 0)
  --pagesize: int # Page size (e.g. 10)
]: nothing -> record<substance: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db | is-empty) { error make --unspanned { msg: "path parameter 'db' must be non-empty" } }
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "compound_uri" $compound_uri "scalar") (serialize-qp "bundle_uri" $bundle_uri "scalar") (serialize-qp "addDummySubstance" $add_dummy_substance "scalar") (serialize-qp "studysummary" $studysummary "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({db: (encode-path-segment $db)} | format pattern "/enm/{db}/substance") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"search": $search, "type": $type, "compound_uri": $compound_uri, "bundle_uri": $bundle_uri, "addDummySubstance": $add_dummy_substance, "studysummary": $studysummary, "page": $page, "pagesize": $pagesize} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --property-uris: string # Property URIs
  --page: int # Starting page (e.g. 0)
  --pagesize: int # Page size (e.g. 10)
]: nothing -> record<substance: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db | is-empty) { error make --unspanned { msg: "path parameter 'db' must be non-empty" } }
  if ($uuid | is-empty) { error make --unspanned { msg: "path parameter 'uuid' must be non-empty" } }
  let qp = [(serialize-qp "property_uris[]" $property_uris "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({db: (encode-path-segment $db), uuid: (encode-path-segment $uuid)} | format pattern "/enm/{db}/substance/{uuid}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"property_uris[]": $property_uris, "page": $page, "pagesize": $pagesize} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # true (Show all compositions) false (do not show hidden compositions)
  --page: int # Starting page (e.g. 0)
  --pagesize: int # Page size (e.g. 10)
]: nothing -> record<composition: record, feature: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db | is-empty) { error make --unspanned { msg: "path parameter 'db' must be non-empty" } }
  if ($uuid | is-empty) { error make --unspanned { msg: "path parameter 'uuid' must be non-empty" } }
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({db: (encode-path-segment $db), uuid: (encode-path-segment $uuid)} | format pattern "/enm/{db}/substance/{uuid}/composition") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"all": $all, "page": $page, "pagesize": $pagesize} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Starting page (e.g. 0)
  --pagesize: int # Page size (e.g. 10)
]: nothing -> record<dataEntry: record, feature: record, model_uri: string, query: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db | is-empty) { error make --unspanned { msg: "path parameter 'db' must be non-empty" } }
  if ($uuid | is-empty) { error make --unspanned { msg: "path parameter 'uuid' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({db: (encode-path-segment $db), uuid: (encode-path-segment $uuid)} | format pattern "/enm/{db}/substance/{uuid}/structures") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pagesize": $pagesize} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($db | is-empty) { error make --unspanned { msg: "path parameter 'db' must be non-empty" } }
  if ($uuid | is-empty) { error make --unspanned { msg: "path parameter 'uuid' must be non-empty" } }
  let qp = [(serialize-qp "top" $top "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "property_uri" $property_uri "scalar") (serialize-qp "property" $property "scalar") (serialize-qp "investigation_uuid" $investigation_uuid "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({db: (encode-path-segment $db), uuid: (encode-path-segment $uuid)} | format pattern "/enm/{db}/substance/{uuid}/study") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"top": $top, "category": $category, "property_uri": $property_uri, "property": $property, "investigation_uuid": $investigation_uuid, "page": $page, "pagesize": $pagesize} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($db | is-empty) { error make --unspanned { msg: "path parameter 'db' must be non-empty" } }
  if ($uuid | is-empty) { error make --unspanned { msg: "path parameter 'uuid' must be non-empty" } }
  let qp = [(serialize-qp "top" $top "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "property_uri" $property_uri "scalar") (serialize-qp "property" $property "scalar") (serialize-qp "result" $result "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({db: (encode-path-segment $db), uuid: (encode-path-segment $uuid)} | format pattern "/enm/{db}/substance/{uuid}/studySummary") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"top": $top, "category": $category, "property_uri": $property_uri, "property": $property, "result": $result, "page": $page, "pagesize": $pagesize} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Apache Solr powered search
#
# GET /select
# operationId: solrquery_get
export def "select get-solrquery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --q: string # The query (e.g. *:*)
  --start: int # Starting page (e.g. 0)
  --rows: int # Page size (e.g. 10)
  --wt: string@wt-completer # Response format (default: xml, e.g. json)
]: nothing -> record<response: record<docs: list<record>, maxScore: float, numFound: int, start: int>, responseHeader: record<QTime: int, params: record, status: int, zkConnected: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "wt" $wt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/select" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q, "start": $start, "rows": $rows, "wt": $wt} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Apache Solr powered search
#
# POST /select
# operationId: solrquery_post
# --params shape: {fl?: list<string>, rows?: int}
export def "select create-solrquery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --wt: string@wt-completer # Response format (default: xml, e.g. json)
  --facet: record
  --params: record # shape: {fl?: list<string>, rows?: int}
]: any -> record<response: record<docs: list<record>, maxScore: float, numFound: int, start: int>, responseHeader: record<QTime: int, params: record, status: int, zkConnected: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wt" $wt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/select" $qp $auth.query)
  let req_body = {"facet": $facet, "params": $params} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"wt": $wt} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
