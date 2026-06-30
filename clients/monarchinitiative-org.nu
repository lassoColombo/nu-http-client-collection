# Auto-generated client for BioLink API v1.1.14
# Source: https://api.apis.guru/v2/specs/monarchinitiative.org/1.1.14/openapi.json
# Auth: --token flag or $env.BIOLINK_API_TOKEN

const BASE_URL = "http://localhost/api"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o BIOLINK_API_TOKEN | default "" }
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

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://localhost/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def association-type-completer [] { ["both" "causal" "non_causal"] }
def relationship-type-completer [] { ["acts_upstream_of_or_within" "involved_in" "involved_in_regulation_of"] }
def homology-type-completer [] { ["LDO" "O" "P"] }
def relationship-type-completer-1 [] { ["acts_upstream_of_or_within" "involved_in"] }
def direction-completer [] { ["BOTH" "INCOMING" "OUTGOING"] }
def graph-completer [] { ["data" "ontology"] }
def graph-type-completer [] { ["neighborhood_graph" "neighborhood_limited_graph" "regulates_transitivity_graph" "topology_graph"] }
def metric-completer [] { ["jaccard" "phenodigm" "resnik" "simGIC" "symmetric_resnik"] }
def per-page-completer [] { ["10" "2" "20" "30" "40" "50"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "association-between get" } } | get name | first)
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

# Returns associations connecting two entities
#
# GET /association/between/{subject}/{object}
# operationId: get_associations_between
export def "association-between get" [
  subject: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
]: nothing -> table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subject | is-empty) { error make --unspanned { msg: "path parameter 'subject' must be non-empty" } }
  if ($object | is-empty) { error make --unspanned { msg: "path parameter 'object' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subject: (encode-path-segment $subject), object: (encode-path-segment $object)} | format pattern "/association/between/{subject}/{object}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "evidence": $evidence, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "use_compact_associations": $use_compact_associations} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of matching associations for a given subject category
#
# GET /association/find/{subject_category}
# operationId: get_association_by_subject_category_search
export def "association-find get-by-list" [
  subject_category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --subject-taxon: string # Subject taxon ID, e.g. NCBITaxon:9606 (Includes inferred associations, by default)
  --object-taxon: string # Object taxon ID, e.g. NCBITaxon:10090 (Includes inferred associations, by default)
  --relation: string # Filter by relation CURIE, e.g. RO:0002200 (has_phenotype), RO:0002607 (is marker for), RO:HOM0000017 (orthologous to), etc.
]: nothing -> table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subject_category | is-empty) { error make --unspanned { msg: "path parameter 'subject_category' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "subject_taxon" $subject_taxon "scalar") (serialize-qp "object_taxon" $object_taxon "scalar") (serialize-qp "relation" $relation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subject_category: (encode-path-segment $subject_category)} | format pattern "/association/find/{subject_category}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "evidence": $evidence, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "use_compact_associations": $use_compact_associations, "subject_taxon": $subject_taxon, "object_taxon": $object_taxon, "relation": $relation} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of matching associations between a given subject and object category
#
# GET /association/find/{subject_category}/{object_category}
# operationId: get_association_by_subject_and_object_category_search
export def "association-find get-by-and-list" [
  subject_category: string
  object_category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --subject: string # Subject CURIE
  --object: string # Object CURIE
  --subject-taxon: string # Subject taxon ID, e.g. NCBITaxon:9606 (Includes inferred associations, by default)
  --object-taxon: string # Object taxon ID, e.g. NCBITaxon:10090 (Includes inferred associations, by default)
  --relation: string # Filter by relation CURIE, e.g. RO:0002200 (has_phenotype), RO:0002607 (is marker for), RO:HOM0000017 (orthologous to), etc.
]: nothing -> table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subject_category | is-empty) { error make --unspanned { msg: "path parameter 'subject_category' must be non-empty" } }
  if ($object_category | is-empty) { error make --unspanned { msg: "path parameter 'object_category' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "subject" $subject "scalar") (serialize-qp "object" $object "scalar") (serialize-qp "subject_taxon" $subject_taxon "scalar") (serialize-qp "object_taxon" $object_taxon "scalar") (serialize-qp "relation" $relation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subject_category: (encode-path-segment $subject_category), object_category: (encode-path-segment $object_category)} | format pattern "/association/find/{subject_category}/{object_category}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "evidence": $evidence, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "use_compact_associations": $use_compact_associations, "subject": $subject, "object": $object, "subject_taxon": $subject_taxon, "object_taxon": $object_taxon, "relation": $relation} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of matching associations starting from a given subject (source)
#
# GET /association/from/{subject}
# operationId: get_associations_from
export def "association-from get" [
  subject: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --object-taxon: string # Object taxon ID, e.g. NCBITaxon:10090 (Includes inferred associations, by default)
  --relation: string # Filter by relation CURIE, e.g. RO:0002200 (has_phenotype), RO:0002607 (is marker for), RO:HOM0000017 (orthologous to), etc.
]: nothing -> table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subject | is-empty) { error make --unspanned { msg: "path parameter 'subject' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "object_taxon" $object_taxon "scalar") (serialize-qp "relation" $relation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subject: (encode-path-segment $subject)} | format pattern "/association/from/{subject}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "evidence": $evidence, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "use_compact_associations": $use_compact_associations, "object_taxon": $object_taxon, "relation": $relation} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of matching associations pointing to a given object (target)
#
# GET /association/to/{object}
# operationId: get_associations_to
export def "association-to get" [
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
]: nothing -> table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object | is-empty) { error make --unspanned { msg: "path parameter 'object' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({object: (encode-path-segment $object)} | format pattern "/association/to/{object}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "evidence": $evidence, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "use_compact_associations": $use_compact_associations} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of matching associations of a given type
#
# GET /association/type/{association_type}
# operationId: get_association_by_subject_and_assoc_type
export def "association-type get-by-subject-and-assoc" [
  association_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --subject: string # Subject CURIE
  --object: string # Object CURIE
]: nothing -> table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($association_type | is-empty) { error make --unspanned { msg: "path parameter 'association_type' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "subject" $subject "scalar") (serialize-qp "object" $object "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({association_type: (encode-path-segment $association_type)} | format pattern "/association/type/{association_type}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "evidence": $evidence, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "use_compact_associations": $use_compact_associations, "subject": $subject, "object": $object} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the association with a given identifier
#
# GET /association/{id}
# operationId: get_association_object
export def "association get-object" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/association/{id}") $auth.query)
  let accept_val = "application/json"
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

# Returns genes associated with a given anatomy
#
# GET /bioentity/anatomy/{id}/genes
# operationId: get_anatomy_gene_associations
export def "bioentity-anatomy-genes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/anatomy/{id}/genes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns gene IDs for all genes associated with a given anatomy, filtered by taxon
#
# GET /bioentity/anatomy/{id}/genes/{taxid}
# DEPRECATED
# operationId: get_anatomy_gene_by_taxon_associations
@deprecated
export def "bioentity-anatomy-genes get-by-taxon-associations" [
  id: string
  taxid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($taxid | is-empty) { error make --unspanned { msg: "path parameter 'taxid' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), taxid: (encode-path-segment $taxid)} | format pattern "/bioentity/anatomy/{id}/genes/{taxid}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns diseases associated with a case
#
# GET /bioentity/case/{id}/diseases
# operationId: get_case_disease_associations
export def "bioentity-case-diseases get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/case/{id}/diseases") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns genotypes associated with a case
#
# GET /bioentity/case/{id}/genotypes
# operationId: get_case_genotype_associations
export def "bioentity-case-genotypes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/case/{id}/genotypes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns models associated with a case
#
# GET /bioentity/case/{id}/models
# operationId: get_case_model_associations
export def "bioentity-case-models get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/case/{id}/models") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns phenotypes associated with a case
#
# GET /bioentity/case/{id}/phenotypes
# operationId: get_case_phenotype_associations
export def "bioentity-case-phenotypes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/case/{id}/phenotypes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns variants associated with a case
#
# GET /bioentity/case/{id}/variants
# operationId: get_case_variant_associations
export def "bioentity-case-variants get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/case/{id}/variants") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns cases associated with a disease
#
# GET /bioentity/disease/{id}/cases
# operationId: get_disease_case_associations
export def "bioentity-disease-cases get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/disease/{id}/cases") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns genes associated with a disease
#
# GET /bioentity/disease/{id}/genes
# operationId: get_disease_gene_associations
export def "bioentity-disease-genes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
  --association-type: string@association-type-completer # Additional filters: causal, non_causal, both (default: both)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "association_type" $association_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/disease/{id}/genes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q, "association_type": $association_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns genotypes associated with a disease
#
# GET /bioentity/disease/{id}/genotypes
# operationId: get_disease_genotype_associations
export def "bioentity-disease-genotypes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/disease/{id}/genotypes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns associations to models of the disease
#
# GET /bioentity/disease/{id}/models
# operationId: get_disease_model_associations
export def "bioentity-disease-models list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/disease/{id}/models") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns associations to models of the disease constrained by taxon
#
# GET /bioentity/disease/{id}/models/{taxon}
# DEPRECATED
# operationId: get_disease_model_taxon_associations
@deprecated
export def "bioentity-disease-models get-associations" [
  id: string
  taxon: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($taxon | is-empty) { error make --unspanned { msg: "path parameter 'taxon' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), taxon: (encode-path-segment $taxon)} | format pattern "/bioentity/disease/{id}/models/{taxon}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns pathways associated with a disease
#
# GET /bioentity/disease/{id}/pathways
# operationId: get_disease_pathway_associations
export def "bioentity-disease-pathways get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/disease/{id}/pathways") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns phenotypes associated with disease
#
# GET /bioentity/disease/{id}/phenotypes
# operationId: get_disease_phenotype_associations
export def "bioentity-disease-phenotypes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string, frequency: record, onset: record>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/disease/{id}/phenotypes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns publications associated with a disease
#
# GET /bioentity/disease/{id}/publications
# operationId: get_disease_publication_associations
export def "bioentity-disease-publications get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/disease/{id}/publications") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns substances associated with a disease
#
# GET /bioentity/disease/{id}/treatment
# operationId: get_disease_substance_associations
export def "bioentity-disease-treatment get-substance-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/disease/{id}/treatment") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns variants associated with a disease
#
# GET /bioentity/disease/{id}/variants
# operationId: get_disease_variant_associations
export def "bioentity-disease-variants get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/disease/{id}/variants") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns annotations associated to a function term
#
# GET /bioentity/function/{id}
# operationId: get_function_associations
export def "bioentity-function get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # beginning row (default: 0)
  --rows: int # number of rows (default: 100)
  --evidence: list<string> # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "evidence" $evidence "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/function/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start": $start, "rows": $rows, "evidence": $evidence} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns genes associated to a GO term
#
# GET /bioentity/function/{id}/genes
# operationId: get_function_gene_associations
export def "bioentity-function-genes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
  --relationship-type: string@relationship-type-completer # relationship type ('involved_in', 'involved_in_regulation_of' or 'acts_upstream_of_or_within') (default: involved_in)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "relationship_type" $relationship_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/function/{id}/genes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q, "relationship_type": $relationship_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns publications associated to a GO term
#
# GET /bioentity/function/{id}/publications
# operationId: get_function_publication_associations
export def "bioentity-function-publications get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # beginning row (default: 0)
  --rows: int # number of rows (default: 100)
  --evidence: list<string> # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "evidence" $evidence "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/function/{id}/publications") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start": $start, "rows": $rows, "evidence": $evidence} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns taxons associated to a GO term
#
# GET /bioentity/function/{id}/taxons
# operationId: get_function_taxon_associations
export def "bioentity-function-taxons get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # beginning row (default: 0)
  --rows: int # number of rows (default: 100)
  --evidence: list<string> # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "evidence" $evidence "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/function/{id}/taxons") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start": $start, "rows": $rows, "evidence": $evidence} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns anatomical entities associated with a gene
#
# GET /bioentity/gene/{id}/anatomy
# operationId: get_gene_anatomy_associations
export def "bioentity-gene-anatomy get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/gene/{id}/anatomy") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns cases associated with a gene
#
# GET /bioentity/gene/{id}/cases
# operationId: get_gene_case_associations
export def "bioentity-gene-cases get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/gene/{id}/cases") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns diseases associated with gene
#
# GET /bioentity/gene/{id}/diseases
# operationId: get_gene_disease_associations
export def "bioentity-gene-diseases get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
  --association-type: string@association-type-completer # Additional filters: causal, non_causal, both (default: both)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "association_type" $association_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/gene/{id}/diseases") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q, "association_type": $association_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns expression events for a gene
#
# GET /bioentity/gene/{id}/expression/anatomy
# operationId: get_gene_expression_associations
export def "bioentity-gene-expression-anatomy get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/gene/{id}/expression/anatomy") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns function associations for a gene
#
# GET /bioentity/gene/{id}/function
# operationId: get_gene_function_associations
export def "bioentity-gene-function get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/gene/{id}/function") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns genotypes associated with a gene
#
# GET /bioentity/gene/{id}/genotypes
# operationId: get_gene_genotype_associations
export def "bioentity-gene-genotypes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/gene/{id}/genotypes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns homologs for a gene
#
# GET /bioentity/gene/{id}/homologs
# operationId: get_gene_homolog_associations
export def "bioentity-gene-homologs get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # Taxon CURIE of homolog, e.g. NCBITaxon:9606 (Can be an ancestral node in the ontology; includes inferred associations by default)
  --homology-type: string@homology-type-completer # P (paralog), O (Ortholog) or LDO (least-diverged ortholog)
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "homology_type" $homology_type "scalar") (serialize-qp "direct_taxon" $direct_taxon "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/gene/{id}/homologs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "homology_type": $homology_type, "direct_taxon": $direct_taxon} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns interactions for a gene
#
# GET /bioentity/gene/{id}/interactions
# operationId: get_gene_interactions
export def "bioentity-gene-interactions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/gene/{id}/interactions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns models associated with a gene
#
# GET /bioentity/gene/{id}/models
# operationId: get_gene_model_associations
export def "bioentity-gene-models get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/gene/{id}/models") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Return diseases associated with orthologs of a gene
#
# GET /bioentity/gene/{id}/ortholog/diseases
# operationId: get_gene_ortholog_disease_associations
export def "bioentity-gene-ortholog-diseases get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/gene/{id}/ortholog/diseases") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Return phenotypes associated with orthologs for a gene
#
# GET /bioentity/gene/{id}/ortholog/phenotypes
# operationId: get_gene_ortholog_phenotype_associations
export def "bioentity-gene-ortholog-phenotypes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/gene/{id}/ortholog/phenotypes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns pathways associated with gene
#
# GET /bioentity/gene/{id}/pathways
# operationId: get_gene_pathway_associations
export def "bioentity-gene-pathways get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/gene/{id}/pathways") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns phenotypes associated with gene
#
# GET /bioentity/gene/{id}/phenotypes
# operationId: get_gene_phenotype_associations
export def "bioentity-gene-phenotypes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/gene/{id}/phenotypes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns publications associated with a gene
#
# GET /bioentity/gene/{id}/publications
# operationId: get_gene_publication_associations
export def "bioentity-gene-publications get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/gene/{id}/publications") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns variants associated with a gene
#
# GET /bioentity/gene/{id}/variants
# operationId: get_gene_variant_associations
export def "bioentity-gene-variants get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/gene/{id}/variants") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns cases associated with a genotype
#
# GET /bioentity/genotype/{id}/cases
# operationId: get_genotype_case_associations
export def "bioentity-genotype-cases get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/genotype/{id}/cases") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns diseases associated with a genotype
#
# GET /bioentity/genotype/{id}/diseases
# operationId: get_genotype_disease_associations
export def "bioentity-genotype-diseases get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/genotype/{id}/diseases") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns genes associated with a genotype
#
# GET /bioentity/genotype/{id}/genes
# operationId: get_genotype_gene_associations
export def "bioentity-genotype-genes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/genotype/{id}/genes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns genotypes-genotype associations
#
# GET /bioentity/genotype/{id}/genotypes
# operationId: get_genotype_genotype_associations
export def "bioentity-genotype-genotypes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/genotype/{id}/genotypes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns models associated with a genotype
#
# GET /bioentity/genotype/{id}/models
# operationId: get_genotype_model_associations
export def "bioentity-genotype-models get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/genotype/{id}/models") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns phenotypes associated with a genotype
#
# GET /bioentity/genotype/{id}/phenotypes
# operationId: get_genotype_phenotype_associations
export def "bioentity-genotype-phenotypes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/genotype/{id}/phenotypes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns publications associated with a genotype
#
# GET /bioentity/genotype/{id}/publications
# operationId: get_genotype_publication_associations
export def "bioentity-genotype-publications get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/genotype/{id}/publications") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns genotypes-variant associations
#
# GET /bioentity/genotype/{id}/variants
# operationId: get_genotype_variant_associations
export def "bioentity-genotype-variants get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/genotype/{id}/variants") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns associations to GO terms for a gene
#
# GET /bioentity/goterm/{id}/genes
# DEPRECATED
# operationId: get_goterm_gene_associations
@deprecated
export def "bioentity-goterm-genes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --relationship-type: string@relationship-type-completer # relationship type ('involved_in', 'involved_in_regulation_of' or 'acts_upstream_of_or_within') (default: involved_in)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "relationship_type" $relationship_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/goterm/{id}/genes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "relationship_type": $relationship_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns cases associated with a model
#
# GET /bioentity/model/{id}/cases
# operationId: get_model_case_associations
export def "bioentity-model-cases get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/model/{id}/cases") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns diseases associated with a model
#
# GET /bioentity/model/{id}/diseases
# operationId: get_model_disease_associations
export def "bioentity-model-diseases get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/model/{id}/diseases") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns genes associated with a model
#
# GET /bioentity/model/{id}/genes
# operationId: get_model_gene_associations
export def "bioentity-model-genes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/model/{id}/genes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns genotypes associated with a model
#
# GET /bioentity/model/{id}/genotypes
# operationId: get_model_genotype_associations
export def "bioentity-model-genotypes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/model/{id}/genotypes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns phenotypes associated with a model
#
# GET /bioentity/model/{id}/phenotypes
# operationId: get_model_phenotype_associations
export def "bioentity-model-phenotypes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/model/{id}/phenotypes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns publications associated with a model
#
# GET /bioentity/model/{id}/publications
# operationId: get_model_publication_associations
export def "bioentity-model-publications get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/model/{id}/publications") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns variants associated with a model
#
# GET /bioentity/model/{id}/variants
# operationId: get_model_variant_associations
export def "bioentity-model-variants get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/model/{id}/variants") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns diseases associated with a pathway
#
# GET /bioentity/pathway/{id}/diseases
# operationId: get_pathway_disease_associations
export def "bioentity-pathway-diseases get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/pathway/{id}/diseases") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns genes associated with a pathway
#
# GET /bioentity/pathway/{id}/genes
# operationId: get_pathway_gene_associations
export def "bioentity-pathway-genes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/pathway/{id}/genes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns phenotypes associated with a pathway
#
# GET /bioentity/pathway/{id}/phenotypes
# operationId: get_pathway_phenotype_associations
export def "bioentity-pathway-phenotypes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/pathway/{id}/phenotypes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns anatomical entities associated with a phenotype
#
# GET /bioentity/phenotype/{id}/anatomy
# operationId: get_phenotype_anatomy_associations
export def "bioentity-phenotype-anatomy get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> table<category: list<string>, id: string, iri: string, label: string, consider: list<string>, deprecated: bool, description: string, replaced_by: list<string>, synonyms: list<record>, types: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/phenotype/{id}/anatomy") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns cases associated with a phenotype
#
# GET /bioentity/phenotype/{id}/cases
# operationId: get_phenotype_case_associations
export def "bioentity-phenotype-cases get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/phenotype/{id}/cases") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns diseases associated with a phenotype
#
# GET /bioentity/phenotype/{id}/diseases
# operationId: get_phenotype_disease_associations
export def "bioentity-phenotype-diseases get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string, frequency: record, onset: record>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/phenotype/{id}/diseases") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns gene IDs for all genes associated with a given phenotype, filtered by taxon
#
# GET /bioentity/phenotype/{id}/gene/{taxid}/ids
# DEPRECATED
# operationId: get_phenotype_gene_by_taxon_associations
@deprecated
export def "bioentity-phenotype-gene-ids get-by-taxon-associations" [
  id: string
  taxid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($taxid | is-empty) { error make --unspanned { msg: "path parameter 'taxid' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), taxid: (encode-path-segment $taxid)} | format pattern "/bioentity/phenotype/{id}/gene/{taxid}/ids") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns genes associated with a phenotype
#
# GET /bioentity/phenotype/{id}/genes
# operationId: get_phenotype_gene_associations
export def "bioentity-phenotype-genes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/phenotype/{id}/genes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns genotypes associated with a phenotype
#
# GET /bioentity/phenotype/{id}/genotypes
# operationId: get_phenotype_genotype_associations
export def "bioentity-phenotype-genotypes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/phenotype/{id}/genotypes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns pathways associated with a phenotype
#
# GET /bioentity/phenotype/{id}/pathways
# operationId: get_phenotype_pathway_associations
export def "bioentity-phenotype-pathways get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/phenotype/{id}/pathways") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns publications associated with a phenotype
#
# GET /bioentity/phenotype/{id}/publications
# operationId: get_phenotype_publication_associations
export def "bioentity-phenotype-publications get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/phenotype/{id}/publications") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns variants associated with a phenotype
#
# GET /bioentity/phenotype/{id}/variants
# operationId: get_phenotype_variant_associations
export def "bioentity-phenotype-variants get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/phenotype/{id}/variants") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns diseases associated with a publication
#
# GET /bioentity/publication/{id}/diseases
# operationId: get_publication_disease_associations
export def "bioentity-publication-diseases get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/publication/{id}/diseases") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns genes associated with a publication
#
# GET /bioentity/publication/{id}/genes
# operationId: get_publication_gene_associations
export def "bioentity-publication-genes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/publication/{id}/genes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns genotypes associated with a publication
#
# GET /bioentity/publication/{id}/genotypes
# operationId: get_publication_genotype_associations
export def "bioentity-publication-genotypes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/publication/{id}/genotypes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns models associated with a publication
#
# GET /bioentity/publication/{id}/models
# operationId: get_publication_model_associations
export def "bioentity-publication-models get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/publication/{id}/models") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns phenotypes associated with a publication
#
# GET /bioentity/publication/{id}/phenotypes
# operationId: get_publication_phenotype_associations
export def "bioentity-publication-phenotypes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/publication/{id}/phenotypes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns variants associated with a publication
#
# GET /bioentity/publication/{id}/variants
# operationId: get_publication_variant_associations
export def "bioentity-publication-variants get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/publication/{id}/variants") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns associations between an activity and process and the specified substance
#
# GET /bioentity/substance/{id}/participant_in
# operationId: get_substance_participant_in_associations
export def "bioentity-substance-participant-in get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record, slim: list<string>, subject: record, subject_eq: list<string>, subject_extensions: list<record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/substance/{id}/participant_in") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns associations between given drug and roles
#
# GET /bioentity/substance/{id}/roles
# operationId: get_substance_role_associations
export def "bioentity-substance-roles get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record, slim: list<string>, subject: record, subject_eq: list<string>, subject_extensions: list<record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/substance/{id}/roles") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns substances associated with a disease
#
# GET /bioentity/substance/{id}/treats
# operationId: get_substance_treats_associations
export def "bioentity-substance-treats get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/substance/{id}/treats") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns cases associated with a variant
#
# GET /bioentity/variant/{id}/cases
# operationId: get_variant_case_associations
export def "bioentity-variant-cases get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/variant/{id}/cases") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns diseases associated with a variant
#
# GET /bioentity/variant/{id}/diseases
# operationId: get_variant_disease_associations
export def "bioentity-variant-diseases get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/variant/{id}/diseases") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns genes associated with a variant
#
# GET /bioentity/variant/{id}/genes
# operationId: get_variant_gene_associations
export def "bioentity-variant-genes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/variant/{id}/genes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns genotypes associated with a variant
#
# GET /bioentity/variant/{id}/genotypes
# operationId: get_variant_genotype_associations
export def "bioentity-variant-genotypes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/variant/{id}/genotypes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns models associated with a variant
#
# GET /bioentity/variant/{id}/models
# operationId: get_variant_model_associations
export def "bioentity-variant-models get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/variant/{id}/models") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns phenotypes associated with a variant
#
# GET /bioentity/variant/{id}/phenotypes
# operationId: get_variant_phenotype_associations
export def "bioentity-variant-phenotypes get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/variant/{id}/phenotypes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns publications associated with a variant
#
# GET /bioentity/variant/{id}/publications
# operationId: get_variant_publication_associations
export def "bioentity-variant-publications get-associations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/variant/{id}/publications") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns basic info on object of any type
#
# GET /bioentity/{id}
# operationId: get_generic_object
export def "bioentity list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> record<association_counts: record, taxon: record<id: string, label: string>, xrefs: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns associations for an entity regardless of the type
#
# GET /bioentity/{id}/associations
# operationId: get_generic_associations
export def "bioentity-associations get-generic" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --qp-sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "taxon" $taxon "multi") (serialize-qp "direct_taxon" $direct_taxon "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bioentity/{id}/associations") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "taxon": $taxon, "direct_taxon": $direct_taxon, "relation": $relation, "sort": $qp_sort, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Return basic info on an object for a given type
#
# GET /bioentity/{type}/{id}
# operationId: get_generic_object_by_type
export def "bioentity get-generic-object" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --get-association-counts: oneof<nothing, bool> # Get association counts (default: false)
  --distinct-counts: oneof<nothing, bool> # Get distinct counts for associations (to be used in conjunction with 'get_association_counts' parameter) (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facet_fields" $facet_fields "multi") (serialize-qp "unselect_evidence" $unselect_evidence "scalar") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "fetch_objects" $fetch_objects "scalar") (serialize-qp "use_compact_associations" $use_compact_associations "scalar") (serialize-qp "slim" $slim "multi") (serialize-qp "evidence" $evidence "scalar") (serialize-qp "direct" $direct "scalar") (serialize-qp "get_association_counts" $get_association_counts "scalar") (serialize-qp "distinct_counts" $distinct_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/bioentity/{type}/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "facet": $facet, "facet_fields": $facet_fields, "unselect_evidence": $unselect_evidence, "exclude_automatic_assertions": $exclude_automatic_assertions, "fetch_objects": $fetch_objects, "use_compact_associations": $use_compact_associations, "slim": $slim, "evidence": $evidence, "direct": $direct, "get_association_counts": $get_association_counts, "distinct_counts": $distinct_counts} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns compact associations for a given input set
#
# GET /bioentityset/associations
# operationId: get_entity_set_associations
export def "bioentityset-associations get-entity-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: list<string> # Entity ids to be examined, e.g. NCBIGene:9342, NCBIGene:7227, NCBIGene:8131, NCBIGene:157570, NCBIGene:51164, NCBIGene:6689, NCBIGene:6387
  --background: list<string> # Entity ids in background set, e.g. NCBIGene:84570, NCBIGene:3630; used in over-representation tests
  --object-category: string # E.g. phenotype, function
  --object-slim: string # Slim or subset to which the descriptors are to be mapped, NOT IMPLEMENTED
]: nothing -> table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subject" $subject "multi") (serialize-qp "background" $background "multi") (serialize-qp "object_category" $object_category "scalar") (serialize-qp "object_slim" $object_slim "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bioentityset/associations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"subject": $subject, "background": $background, "object_category": $object_category, "object_slim": $object_slim} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Summary statistics for objects associated
#
# GET /bioentityset/descriptor/counts
# operationId: get_entity_set_summary
export def "bioentityset-descriptor-counts get-entity-update-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: list<string> # Entity ids to be examined, e.g. NCBIGene:9342, NCBIGene:7227, NCBIGene:8131, NCBIGene:157570, NCBIGene:51164, NCBIGene:6689, NCBIGene:6387
  --background: list<string> # Entity ids in background set, e.g. NCBIGene:84570, NCBIGene:3630; used in over-representation tests
  --object-category: string # E.g. phenotype, function
  --object-slim: string # Slim or subset to which the descriptors are to be mapped, NOT IMPLEMENTED
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subject" $subject "multi") (serialize-qp "background" $background "multi") (serialize-qp "object_category" $object_category "scalar") (serialize-qp "object_slim" $object_slim "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bioentityset/descriptor/counts" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"subject": $subject, "background": $background, "object_category": $object_category, "object_slim": $object_slim} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# TODO Graph object spanning all entities
#
# GET /bioentityset/graph
# operationId: get_entity_set_graph_resource
export def "bioentityset-graph get-entity-update-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: list<string> # Entity ids to be examined, e.g. NCBIGene:9342, NCBIGene:7227, NCBIGene:8131, NCBIGene:157570, NCBIGene:51164, NCBIGene:6689, NCBIGene:6387
  --background: list<string> # Entity ids in background set, e.g. NCBIGene:84570, NCBIGene:3630; used in over-representation tests
  --object-category: string # E.g. phenotype, function
  --object-slim: string # Slim or subset to which the descriptors are to be mapped, NOT IMPLEMENTED
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subject" $subject "multi") (serialize-qp "background" $background "multi") (serialize-qp "object_category" $object_category "scalar") (serialize-qp "object_slim" $object_slim "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bioentityset/graph" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"subject": $subject, "background": $background, "object_category": $object_category, "object_slim": $object_slim} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns homology associations for a given input set of genes
#
# GET /bioentityset/homologs/
# operationId: get_entity_set_homologs
export def "bioentityset-homologs get-entity-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: list<string> # Entity ids to be examined, e.g. NCBIGene:9342, NCBIGene:7227, NCBIGene:8131, NCBIGene:157570, NCBIGene:51164, NCBIGene:6689, NCBIGene:6387
]: nothing -> table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subject" $subject "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/bioentityset/homologs/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"subject": $subject} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Summary statistics for objects associated
#
# GET /bioentityset/overrepresentation
# operationId: get_over_representation
export def "bioentityset-overrepresentation get-over-representation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --object-category: string # E.g. phenotype, function
  --subject: list<string> # Entity ids to be examined, e.g. NCBIGene:9342, NCBIGene:7227, NCBIGene:8131, NCBIGene:157570, NCBIGene:51164, NCBIGene:6689, NCBIGene:6387
  --background: list<string> # Entity ids in background set, e.g. NCBIGene:84570, NCBIGene:3630; used in over-representation tests
  --subject-category: string # Default: gene. Other types may be used e.g. disease but statistics may not make sense (default: gene)
  --max-p-value: string # Exclude results with p-value greater than this (default: 0.05)
  --ontology: string # ontology id. Must be obo id. Examples: go, mp, hp, uberon (optional: will be inferred if left blank)
  --taxon: string # must be NCBITaxon CURIE. Example: NCBITaxon:9606
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "object_category" $object_category "scalar") (serialize-qp "subject" $subject "multi") (serialize-qp "background" $background "multi") (serialize-qp "subject_category" $subject_category "scalar") (serialize-qp "max_p_value" $max_p_value "scalar") (serialize-qp "ontology" $ontology "scalar") (serialize-qp "taxon" $taxon "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bioentityset/overrepresentation" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"object_category": $object_category, "subject": $subject, "background": $background, "subject_category": $subject_category, "max_p_value": $max_p_value, "ontology": $ontology, "taxon": $taxon} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# For a given gene(s), summarize its annotations over a defined set of slim
#
# GET /bioentityset/slimmer/anatomy
# operationId: get_entity_set_anatomy_slimmer
export def "bioentityset-slimmer-anatomy get-entity-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: list<string> # Entity ids to be examined, e.g. NCBIGene:9342, NCBIGene:7227, NCBIGene:8131, NCBIGene:157570, NCBIGene:51164, NCBIGene:6689, NCBIGene:6387
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID (IMPLEMENTED) or subset ID (TODO)
  --exclude-automatic-assertions: oneof<nothing, bool> # If set, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subject" $subject "multi") (serialize-qp "slim" $slim "multi") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bioentityset/slimmer/anatomy" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"subject": $subject, "slim": $slim, "exclude_automatic_assertions": $exclude_automatic_assertions, "rows": $rows, "start": $start} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# For a given gene(s), summarize its annotations over a defined set of slim
#
# GET /bioentityset/slimmer/function
# operationId: get_entity_set_function_slimmer
export def "bioentityset-slimmer-function get-entity-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --relationship-type: string@relationship-type-completer-1 # relationship type ('involved_in' or 'acts_upstream_of_or_within') (default: acts_upstream_of_or_within)
  --subject: list<string> # Entity ids to be examined, e.g. NCBIGene:9342, NCBIGene:7227, NCBIGene:8131, NCBIGene:157570, NCBIGene:51164, NCBIGene:6689, NCBIGene:6387
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID (IMPLEMENTED) or subset ID (TODO)
  --exclude-automatic-assertions: oneof<nothing, bool> # If set, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "relationship_type" $relationship_type "scalar") (serialize-qp "subject" $subject "multi") (serialize-qp "slim" $slim "multi") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bioentityset/slimmer/function" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"relationship_type": $relationship_type, "subject": $subject, "slim": $slim, "exclude_automatic_assertions": $exclude_automatic_assertions, "rows": $rows, "start": $start} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# For a given gene(s), summarize its annotations over a defined set of slim
#
# GET /bioentityset/slimmer/phenotype
# operationId: get_entity_set_phenotype_slimmer
export def "bioentityset-slimmer-phenotype get-entity-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: list<string> # Entity ids to be examined, e.g. NCBIGene:9342, NCBIGene:7227, NCBIGene:8131, NCBIGene:157570, NCBIGene:51164, NCBIGene:6689, NCBIGene:6387
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID (IMPLEMENTED) or subset ID (TODO)
  --exclude-automatic-assertions: oneof<nothing, bool> # If set, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subject" $subject "multi") (serialize-qp "slim" $slim "multi") (serialize-qp "exclude_automatic_assertions" $exclude_automatic_assertions "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bioentityset/slimmer/phenotype" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"subject": $subject, "slim": $slim, "exclude_automatic_assertions": $exclude_automatic_assertions, "rows": $rows, "start": $start} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of models
#
# GET /cam/activity
# operationId: get_activity_collection
export def "cam-activity get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # string to search for in title of model
  --contributor: string # string to search for in contributor of model
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "contributor" $contributor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cam/activity" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"title": $title, "contributor": $contributor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of matches
#
# GET /cam/instance/{id}
# operationId: get_instance_object
export def "cam-instance get-object" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # string to search for in title of model
  --contributor: string # string to search for in contributor of model
]: nothing -> table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record, slim: list<string>, subject: record, subject_eq: list<string>, subject_extensions: list<record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "contributor" $contributor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/cam/instance/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"title": $title, "contributor": $contributor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of all instances
#
# GET /cam/instances
# operationId: get_model_instances
export def "cam-instances get-model" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cam/instances" $auth.query)
  let accept_val = "application/json"
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

# Returns list of ALL models
#
# GET /cam/model
# operationId: get_model_collection
export def "cam-model get-collection" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cam/model" $auth.query)
  let accept_val = "application/json"
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

# Returns list of all contributors across all models
#
# GET /cam/model/contributors
# operationId: get_model_contributors
export def "cam-model-contributors get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cam/model/contributors" $auth.query)
  let accept_val = "application/json"
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

# Returns list of all properties used across all models
#
# GET /cam/model/properties
# operationId: get_model_properties
export def "cam-model-properties get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # string to search for in title of model
  --contributor: string # string to search for in contributor of model
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "contributor" $contributor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cam/model/properties" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"title": $title, "contributor": $contributor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list property-values for all models
#
# GET /cam/model/property_values
# operationId: get_model_property_values
export def "cam-model-property-values get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # string to search for in title of model
  --contributor: string # string to search for in contributor of model
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "contributor" $contributor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cam/model/property_values" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"title": $title, "contributor": $contributor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of models matching query
#
# GET /cam/model/query
# operationId: get_model_query
export def "cam-model-query get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # string to search for in title of model
  --contributor: string # string to search for in contributor of model
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "contributor" $contributor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cam/model/query" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"title": $title, "contributor": $contributor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a complete model
#
# GET /cam/model/{id}
# operationId: get_model_object
export def "cam-model get-object" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/cam/model/{id}") $auth.query)
  let accept_val = "application/json"
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

# Returns list of models
#
# GET /cam/physical_interaction
# operationId: get_physical_interaction
export def "cam-physical-interaction get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # string to search for in title of model
  --contributor: string # string to search for in contributor of model
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "contributor" $contributor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cam/physical_interaction" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"title": $title, "contributor": $contributor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns evidence graph object for a given association
#
# GET /evidence/graph/{id}
# operationId: get_evidence_graph_object
export def "evidence-graph get-object" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<edges: list<record>, nodes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/evidence/graph/{id}") $auth.query)
  let accept_val = "application/json"
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

# Returns evidence as a association_results object given an association
#
# GET /evidence/graph/{id}/table
# operationId: get_evidence_graph_table
export def "evidence-graph-table get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-publication: oneof<nothing, bool> # If true, considers dc:source as edge (default: false)
]: nothing -> table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "is_publication" $is_publication "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/evidence/graph/{id}/table") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"is_publication": $is_publication} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of matches
#
# GET /genome/features/within/{build}/{reference}/{begin}/{end}
# operationId: get_features_within_resource
export def "genome-features-within get-resource" [
  build: string
  reference: string
  begin: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<homology_associations: list<record>, locations: list<record>, seq: record<alphabet: string, md5checksum: string, residues: string, seqlen: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($build | is-empty) { error make --unspanned { msg: "path parameter 'build' must be non-empty" } }
  if ($reference | is-empty) { error make --unspanned { msg: "path parameter 'reference' must be non-empty" } }
  if ($begin | is-empty) { error make --unspanned { msg: "path parameter 'begin' must be non-empty" } }
  if ($end | is-empty) { error make --unspanned { msg: "path parameter 'end' must be non-empty" } }
  let full_url = (build-url $base ({build: (encode-path-segment $build), reference: (encode-path-segment $reference), begin: (encode-path-segment $begin), end: (encode-path-segment $end)} | format pattern "/genome/features/within/{build}/{reference}/{begin}/{end}") $auth.query)
  let accept_val = "application/json"
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

# Returns edges emanating from a given node
#
# GET /graph/edges/from/{id}
# operationId: get_edge_resource
export def "graph-edges-from get-resource" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --depth: int # How far to traverse for neighbors (default: 1)
  --direction: string@direction-completer # Which direction to traverse (used only if relationship_type is defined) (default: BOTH)
  --relationship-type: list<string> # Relationship type to traverse
  --entail: oneof<nothing, bool> # Include sub-properties and equivalent properties (default: false)
  --graph: string@graph-completer # Which monarch graph to query (default: data)
]: nothing -> table<edges: list<record>, nodes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "depth" $depth "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "relationship_type" $relationship_type "multi") (serialize-qp "entail" $entail "scalar") (serialize-qp "graph" $graph "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/graph/edges/from/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"depth": $depth, "direction": $direction, "relationship_type": $relationship_type, "entail": $entail, "graph": $graph} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a graph node
#
# GET /graph/node/{id}
# operationId: get_node_resource
export def "graph-node get-resource" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<association_counts: record, taxon: record<id: string, label: string>, xrefs: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/graph/node/{id}") $auth.query)
  let accept_val = "application/json"
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

# TODO maps a list of identifiers from a source to a target
#
# GET /identifier/mapper/{source}/{target}/
# operationId: get_identifier_mapper
export def "identifier-mapper get" [
  source: string
  target: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record, slim: list<string>, subject: record, subject_eq: list<string>, subject_extensions: list<record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source | is-empty) { error make --unspanned { msg: "path parameter 'source' must be non-empty" } }
  if ($target | is-empty) { error make --unspanned { msg: "path parameter 'target' must be non-empty" } }
  let full_url = (build-url $base ({source: (encode-path-segment $source), target: (encode-path-segment $target)} | format pattern "/identifier/mapper/{source}/{target}/") $auth.query)
  let accept_val = "application/json"
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

# Returns list of prefixes
#
# GET /identifier/prefixes/
# operationId: get_prefix_collection
export def "identifier-prefixes get-prefix-collection" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/identifier/prefixes/" $auth.query)
  let accept_val = "application/json"
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

# Returns contracted URI
#
# GET /identifier/prefixes/contract/{uri}
# operationId: get_prefix_contract
export def "identifier-prefixes-contract get-prefix" [
  uri: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($uri | is-empty) { error make --unspanned { msg: "path parameter 'uri' must be non-empty" } }
  let full_url = (build-url $base ({uri: (encode-path-segment $uri)} | format pattern "/identifier/prefixes/contract/{uri}") $auth.query)
  let accept_val = "application/json"
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

# Returns expanded URI
#
# GET /identifier/prefixes/expand/{id}
# operationId: get_prefix_expand
export def "identifier-prefixes-expand get-prefix" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/identifier/prefixes/expand/{id}") $auth.query)
  let accept_val = "application/json"
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

# Returns list of matches
#
# GET /individual/pedigree/{id}
# operationId: get_pedigree
export def "individual-pedigree get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record, slim: list<string>, subject: record, subject_eq: list<string>, subject_extensions: list<record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/individual/pedigree/{id}") $auth.query)
  let accept_val = "application/json"
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

# Returns list of matches
#
# GET /individual/{id}
# operationId: get_individual
export def "individual get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record, slim: list<string>, subject: record, subject_eq: list<string>, subject_extensions: list<record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/individual/{id}") $auth.query)
  let accept_val = "application/json"
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

# Bulk download of case associations
#
# GET /mart/case/{object_category}/{taxon}
# operationId: get_mart_case_associations_resource
export def "mart-case get-associations-resource" [
  object_category: string
  taxon: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_category | is-empty) { error make --unspanned { msg: "path parameter 'object_category' must be non-empty" } }
  if ($taxon | is-empty) { error make --unspanned { msg: "path parameter 'taxon' must be non-empty" } }
  let qp = [(serialize-qp "slim" $slim "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({object_category: (encode-path-segment $object_category), taxon: (encode-path-segment $taxon)} | format pattern "/mart/case/{object_category}/{taxon}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"slim": $slim} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Bulk download of disease associations
#
# GET /mart/disease/{object_category}/{taxon}
# operationId: get_mart_disease_associations_resource
export def "mart-disease get-associations-resource" [
  object_category: string
  taxon: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_category | is-empty) { error make --unspanned { msg: "path parameter 'object_category' must be non-empty" } }
  if ($taxon | is-empty) { error make --unspanned { msg: "path parameter 'taxon' must be non-empty" } }
  let qp = [(serialize-qp "slim" $slim "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({object_category: (encode-path-segment $object_category), taxon: (encode-path-segment $taxon)} | format pattern "/mart/disease/{object_category}/{taxon}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"slim": $slim} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Bulk download of gene associations
#
# GET /mart/gene/{object_category}/{taxon}
# operationId: get_mart_gene_associations_resource
export def "mart-gene get-associations-resource" [
  object_category: string
  taxon: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_category | is-empty) { error make --unspanned { msg: "path parameter 'object_category' must be non-empty" } }
  if ($taxon | is-empty) { error make --unspanned { msg: "path parameter 'taxon' must be non-empty" } }
  let qp = [(serialize-qp "slim" $slim "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({object_category: (encode-path-segment $object_category), taxon: (encode-path-segment $taxon)} | format pattern "/mart/gene/{object_category}/{taxon}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"slim": $slim} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Bulk download of orthologs
#
# GET /mart/ortholog/{taxon1}/{taxon2}
# operationId: get_mart_ortholog_associations_resource
export def "mart-ortholog get-associations-resource" [
  taxon1: string
  taxon2: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($taxon1 | is-empty) { error make --unspanned { msg: "path parameter 'taxon1' must be non-empty" } }
  if ($taxon2 | is-empty) { error make --unspanned { msg: "path parameter 'taxon2' must be non-empty" } }
  let full_url = (build-url $base ({taxon1: (encode-path-segment $taxon1), taxon2: (encode-path-segment $taxon2)} | format pattern "/mart/ortholog/{taxon1}/{taxon2}") $auth.query)
  let accept_val = "application/json"
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

# Bulk download of paralogs
#
# GET /mart/paralog/{taxon1}/{taxon2}
# operationId: get_mart_paralog_associations_resource
export def "mart-paralog get-associations-resource" [
  taxon1: string
  taxon2: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($taxon1 | is-empty) { error make --unspanned { msg: "path parameter 'taxon1' must be non-empty" } }
  if ($taxon2 | is-empty) { error make --unspanned { msg: "path parameter 'taxon2' must be non-empty" } }
  let full_url = (build-url $base ({taxon1: (encode-path-segment $taxon1), taxon2: (encode-path-segment $taxon2)} | format pattern "/mart/paralog/{taxon1}/{taxon2}") $auth.query)
  let accept_val = "application/json"
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

# Get metadata for all datasets from SciGraph
#
# GET /metadata/datasets
# operationId: get_metadata_for_datasets
export def "metadata-datasets get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata/datasets" $auth.query)
  let accept_val = "application/json"
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

# Match a patient to diseases based on their phenotypes
#
# POST /mme/disease
# operationId: post_disease_mme
export def "mme-disease create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mme/disease" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Match a patient to fruit fly genes based on similar phenotypes
#
# POST /mme/fly
# operationId: post_fly_mme
export def "mme-fly create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mme/fly" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Match a patient to mouse genes based on similar phenotypes
#
# POST /mme/mouse
# operationId: post_mouse_mme
export def "mme-mouse create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mme/mouse" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Match a patient to nematode genes based on similar phenotypes
#
# POST /mme/nematode
# operationId: post_nematode_mme
export def "mme-nematode create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mme/nematode" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Match a patient to zebrafish genes based on similar phenotypes
#
# POST /mme/zebrafish
# operationId: post_zebrafish_mme
export def "mme-zebrafish create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mme/zebrafish" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Annotate a given text using SciGraph annotator
#
# GET /nlp/annotate/
# operationId: get_annotate
export def "nlp-annotate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # The text content to annotate
  --include-category: list<string> # Categories to include for annotation
  --exclude-category: list<string> # Categories to exclude for annotation
  --min-length: string # The minimum number of characters in the annotated entity (default: 4)
  --longest-only: oneof<nothing, bool> # Should only the longest entity be returned for an overlapping group (default: false)
  --include-abbreviation: oneof<nothing, bool> # Should abbreviations be included (default: false)
  --include-acronym: oneof<nothing, bool> # Should acronyms be included (default: false)
  --include-numbers: oneof<nothing, bool> # Should numbers be included (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "content" $content "scalar") (serialize-qp "include_category" $include_category "multi") (serialize-qp "exclude_category" $exclude_category "multi") (serialize-qp "min_length" $min_length "scalar") (serialize-qp "longest_only" $longest_only "scalar") (serialize-qp "include_abbreviation" $include_abbreviation "scalar") (serialize-qp "include_acronym" $include_acronym "scalar") (serialize-qp "include_numbers" $include_numbers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nlp/annotate/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"content": $content, "include_category": $include_category, "exclude_category": $exclude_category, "min_length": $min_length, "longest_only": $longest_only, "include_abbreviation": $include_abbreviation, "include_acronym": $include_acronym, "include_numbers": $include_numbers} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Annotate a given text using SciGraph annotator
#
# POST /nlp/annotate/
# operationId: post_annotate
export def "nlp-annotate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # The text content to annotate
  --include-category: list<string> # Categories to include for annotation
  --exclude-category: list<string> # Categories to exclude for annotation
  --min-length: string # The minimum number of characters in the annotated entity (default: 4)
  --longest-only: oneof<nothing, bool> # Should only the longest entity be returned for an overlapping group (default: false)
  --include-abbreviation: oneof<nothing, bool> # Should abbreviations be included (default: false)
  --include-acronym: oneof<nothing, bool> # Should acronyms be included (default: false)
  --include-numbers: oneof<nothing, bool> # Should numbers be included (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "content" $content "scalar") (serialize-qp "include_category" $include_category "multi") (serialize-qp "exclude_category" $exclude_category "multi") (serialize-qp "min_length" $min_length "scalar") (serialize-qp "longest_only" $longest_only "scalar") (serialize-qp "include_abbreviation" $include_abbreviation "scalar") (serialize-qp "include_acronym" $include_acronym "scalar") (serialize-qp "include_numbers" $include_numbers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nlp/annotate/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"content": $content, "include_category": $include_category, "exclude_category": $exclude_category, "min_length": $min_length, "longest_only": $longest_only, "include_abbreviation": $include_abbreviation, "include_acronym": $include_acronym, "include_numbers": $include_numbers} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Annotate a given content using SciGraph annotator and get all entities from content
#
# GET /nlp/annotate/entities
# operationId: get_annotate_entities
export def "nlp-annotate-entities get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # The text content to annotate
  --include-category: list<string> # Categories to include for annotation
  --exclude-category: list<string> # Categories to exclude for annotation
  --min-length: string # The minimum number of characters in the annotated entity (default: 4)
  --longest-only: oneof<nothing, bool> # Should only the longest entity be returned for an overlapping group (default: false)
  --include-abbreviation: oneof<nothing, bool> # Should abbreviations be included (default: false)
  --include-acronym: oneof<nothing, bool> # Should acronyms be included (default: false)
  --include-numbers: oneof<nothing, bool> # Should numbers be included (default: false)
]: nothing -> record<content: string, spans: table<end: int, start: int, text: string, token: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "content" $content "scalar") (serialize-qp "include_category" $include_category "multi") (serialize-qp "exclude_category" $exclude_category "multi") (serialize-qp "min_length" $min_length "scalar") (serialize-qp "longest_only" $longest_only "scalar") (serialize-qp "include_abbreviation" $include_abbreviation "scalar") (serialize-qp "include_acronym" $include_acronym "scalar") (serialize-qp "include_numbers" $include_numbers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nlp/annotate/entities" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"content": $content, "include_category": $include_category, "exclude_category": $exclude_category, "min_length": $min_length, "longest_only": $longest_only, "include_abbreviation": $include_abbreviation, "include_acronym": $include_acronym, "include_numbers": $include_numbers} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Annotate a given content using SciGraph annotator and get all entities from content
#
# POST /nlp/annotate/entities
# operationId: post_annotate_entities
export def "nlp-annotate-entities create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # The text content to annotate
  --include-category: list<string> # Categories to include for annotation
  --exclude-category: list<string> # Categories to exclude for annotation
  --min-length: string # The minimum number of characters in the annotated entity (default: 4)
  --longest-only: oneof<nothing, bool> # Should only the longest entity be returned for an overlapping group (default: false)
  --include-abbreviation: oneof<nothing, bool> # Should abbreviations be included (default: false)
  --include-acronym: oneof<nothing, bool> # Should acronyms be included (default: false)
  --include-numbers: oneof<nothing, bool> # Should numbers be included (default: false)
]: nothing -> record<content: string, spans: table<end: int, start: int, text: string, token: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "content" $content "scalar") (serialize-qp "include_category" $include_category "multi") (serialize-qp "exclude_category" $exclude_category "multi") (serialize-qp "min_length" $min_length "scalar") (serialize-qp "longest_only" $longest_only "scalar") (serialize-qp "include_abbreviation" $include_abbreviation "scalar") (serialize-qp "include_acronym" $include_acronym "scalar") (serialize-qp "include_numbers" $include_numbers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nlp/annotate/entities" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"content": $content, "include_category": $include_category, "exclude_category": $exclude_category, "min_length": $min_length, "longest_only": $longest_only, "include_abbreviation": $include_abbreviation, "include_acronym": $include_acronym, "include_numbers": $include_numbers} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Fetches a map from CURIEs/IDs to labels
#
# GET /ontol/identifier/
# operationId: get_ontol_identifier_resource
export def "ontol-identifier get-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: list<string> # List of labels
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "label" $label "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/ontol/identifier/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"label": $label} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fetches a map from CURIEs/IDs to labels
#
# POST /ontol/identifier/
# operationId: post_ontol_identifier_resource
export def "ontol-identifier create-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: list<string> # List of labels
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "label" $label "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/ontol/identifier/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"label": $label} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Returns information content (IC) for a set of relevant ontology classes
#
# GET /ontol/information_content/{subject_category}/{object_category}/{subject_taxon}
# operationId: get_information_content_resource
export def "ontol-information-content get-resource" [
  subject_category: string
  object_category: string
  subject_taxon: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting ibject, e.g. ZFIN:ZDB-PUB-060503-2.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subject_category | is-empty) { error make --unspanned { msg: "path parameter 'subject_category' must be non-empty" } }
  if ($object_category | is-empty) { error make --unspanned { msg: "path parameter 'object_category' must be non-empty" } }
  if ($subject_taxon | is-empty) { error make --unspanned { msg: "path parameter 'subject_taxon' must be non-empty" } }
  let qp = [(serialize-qp "evidence" $evidence "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subject_category: (encode-path-segment $subject_category), object_category: (encode-path-segment $object_category), subject_taxon: (encode-path-segment $subject_taxon)} | format pattern "/ontol/information_content/{subject_category}/{object_category}/{subject_taxon}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"evidence": $evidence} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fetches a map from CURIEs/IDs to labels
#
# GET /ontol/labeler/
# operationId: get_ontol_labeler_resource
export def "ontol-labeler get-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # List of ids
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/ontol/labeler/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Extract a subgraph from an ontology
#
# GET /ontol/subgraph/{ontology}/{node}
# operationId: get_extract_ontology_subgraph_resource
export def "ontol-subgraph get-extract-resource" [
  ontology: string
  node: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cnode: list<string> # Additional classes
  --include-ancestors: oneof<nothing, bool> # Include Ancestors (default: true)
  --include-descendants: oneof<nothing, bool> # Include Descendants
  --relation: list<string> # Additional classes (default: [subClassOf, BFO:0000050])
  --include-meta: oneof<nothing, bool> # Include metadata in response (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ontology | is-empty) { error make --unspanned { msg: "path parameter 'ontology' must be non-empty" } }
  if ($node | is-empty) { error make --unspanned { msg: "path parameter 'node' must be non-empty" } }
  let qp = [(serialize-qp "cnode" $cnode "multi") (serialize-qp "include_ancestors" $include_ancestors "scalar") (serialize-qp "include_descendants" $include_descendants "scalar") (serialize-qp "relation" $relation "multi") (serialize-qp "include_meta" $include_meta "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ontology: (encode-path-segment $ontology), node: (encode-path-segment $node)} | format pattern "/ontol/subgraph/{ontology}/{node}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cnode": $cnode, "include_ancestors": $include_ancestors, "include_descendants": $include_descendants, "relation": $relation, "include_meta": $include_meta} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Extract a subgraph from an ontology
#
# POST /ontol/subgraph/{ontology}/{node}
# operationId: post_extract_ontology_subgraph_resource
export def "ontol-subgraph create-extract-resource" [
  ontology: string
  node: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cnode: list<string> # Additional classes
  --include-ancestors: oneof<nothing, bool> # Include Ancestors (default: true)
  --include-descendants: oneof<nothing, bool> # Include Descendants
  --relation: list<string> # Additional classes (default: [subClassOf, BFO:0000050])
  --include-meta: oneof<nothing, bool> # Include metadata in response (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ontology | is-empty) { error make --unspanned { msg: "path parameter 'ontology' must be non-empty" } }
  if ($node | is-empty) { error make --unspanned { msg: "path parameter 'node' must be non-empty" } }
  let qp = [(serialize-qp "cnode" $cnode "multi") (serialize-qp "include_ancestors" $include_ancestors "scalar") (serialize-qp "include_descendants" $include_descendants "scalar") (serialize-qp "relation" $relation "multi") (serialize-qp "include_meta" $include_meta "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ontology: (encode-path-segment $ontology), node: (encode-path-segment $node)} | format pattern "/ontol/subgraph/{ontology}/{node}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"cnode": $cnode, "include_ancestors": $include_ancestors, "include_descendants": $include_descendants, "relation": $relation, "include_meta": $include_meta} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Returns the ancestor ontology terms shared by two ontology terms
#
# GET /ontology/shared/{subject}/{object}
# operationId: get_ontology_terms_shared_ancestor
export def "ontology-shared get-terms-ancestor" [
  subject: string
  object: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subject | is-empty) { error make --unspanned { msg: "path parameter 'subject' must be non-empty" } }
  if ($object | is-empty) { error make --unspanned { msg: "path parameter 'object' must be non-empty" } }
  let full_url = (build-url $base ({subject: (encode-path-segment $subject), object: (encode-path-segment $object)} | format pattern "/ontology/shared/{subject}/{object}") $auth.query)
  let accept_val = "application/json"
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

# Returns meta data of an ontology subset (slim)
#
# GET /ontology/subset/{id}
# operationId: get_ontology_subset
export def "ontology-subset get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ontology/subset/{id}") $auth.query)
  let accept_val = "application/json"
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

# Returns meta data of an ontology term
#
# GET /ontology/term/{id}
# operationId: get_ontology_term
export def "ontology-term get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ontology/term/{id}") $auth.query)
  let accept_val = "application/json"
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

# Returns graph of an ontology term
#
# GET /ontology/term/{id}/graph
# operationId: get_ontology_term_graph
export def "ontology-term-graph get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --graph-type: string@graph-type-completer # graph type ('topology_graph', 'regulates_transitivity_graph' or 'neighborhood_graph') (default: topology_graph)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "graph_type" $graph_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ontology/term/{id}/graph") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"graph_type": $graph_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Extract a subgraph from an ontology term
#
# GET /ontology/term/{id}/subgraph
# operationId: get_ontology_term_subgraph
export def "ontology-term-subgraph get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cnode: list<string> # Additional classes
  --include-ancestors: oneof<nothing, bool> # Include Ancestors (default: true)
  --include-descendants: oneof<nothing, bool> # Include Descendants
  --relation: list<string> # Additional classes (default: [subClassOf, BFO:0000050])
  --include-meta: oneof<nothing, bool> # Include metadata in response (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "cnode" $cnode "multi") (serialize-qp "include_ancestors" $include_ancestors "scalar") (serialize-qp "include_descendants" $include_descendants "scalar") (serialize-qp "relation" $relation "multi") (serialize-qp "include_meta" $include_meta "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ontology/term/{id}/subgraph") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cnode": $cnode, "include_ancestors": $include_ancestors, "include_descendants": $include_descendants, "relation": $relation, "include_meta": $include_meta} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns subsets (slims) associated to an ontology term
#
# GET /ontology/term/{id}/subsets
# operationId: get_ontology_term_subsets
export def "ontology-term-subsets get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ontology/term/{id}/subsets") $auth.query)
  let accept_val = "application/json"
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

# Placeholder - use OWLery for now
#
# GET /owl/ontology/dlquery/{query}
# operationId: get_dl_query
export def "owl-ontology-dlquery get-dl" [
  query: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record, slim: list<string>, subject: record, subject_eq: list<string>, subject_extensions: list<record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($query | is-empty) { error make --unspanned { msg: "path parameter 'query' must be non-empty" } }
  let full_url = (build-url $base ({query: (encode-path-segment $query)} | format pattern "/owl/ontology/dlquery/{query}") $auth.query)
  let accept_val = "application/json"
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

# Placeholder - use direct SPARQL endpoint for now
#
# GET /owl/ontology/sparql/{query}
# operationId: get_sparql_query
export def "owl-ontology-sparql get" [
  query: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record, slim: list<string>, subject: record, subject_eq: list<string>, subject_extensions: list<record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($query | is-empty) { error make --unspanned { msg: "path parameter 'query' must be non-empty" } }
  let full_url = (build-url $base ({query: (encode-path-segment $query)} | format pattern "/owl/ontology/sparql/{query}") $auth.query)
  let accept_val = "application/json"
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

# Get pairwise similarity
#
# GET /pair/sim/jaccard/{id1}/{id2}
# operationId: get_pair_sim_jaccard_resource
export def "pair-sim-jaccard get-resource" [
  id1: string
  id2: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --object-category: string # e.g. disease, phenotype, gene. Two subjects will be compared based on overlap between associations to objects in this category
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id1 | is-empty) { error make --unspanned { msg: "path parameter 'id1' must be non-empty" } }
  if ($id2 | is-empty) { error make --unspanned { msg: "path parameter 'id2' must be non-empty" } }
  let qp = [(serialize-qp "object_category" $object_category "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id1: (encode-path-segment $id1), id2: (encode-path-segment $id2)} | format pattern "/pair/sim/jaccard/{id1}/{id2}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"object_category": $object_category} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# All relations used plus count of associations
#
# GET /relation/usage/
# operationId: get_relation_usage_resource
export def "relation-usage get-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject-taxon: string # SUBJECT TAXON id, e.g. NCBITaxon:9606. Includes inferred by default
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting ibject, e.g. ZFIN:ZDB-PUB-060503-2.
]: nothing -> table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subject_taxon" $subject_taxon "scalar") (serialize-qp "evidence" $evidence "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/relation/usage/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"subject_taxon": $subject_taxon, "evidence": $evidence} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# All relations used plus count of associations
#
# GET /relation/usage/between/{subject_category}/{object_category}
# operationId: get_relation_usage_between_resource
export def "relation-usage-between get-resource" [
  subject_category: string
  object_category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject-taxon: string # SUBJECT TAXON id, e.g. NCBITaxon:9606. Includes inferred by default
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting ibject, e.g. ZFIN:ZDB-PUB-060503-2.
]: nothing -> table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subject_category | is-empty) { error make --unspanned { msg: "path parameter 'subject_category' must be non-empty" } }
  if ($object_category | is-empty) { error make --unspanned { msg: "path parameter 'object_category' must be non-empty" } }
  let qp = [(serialize-qp "subject_taxon" $subject_taxon "scalar") (serialize-qp "evidence" $evidence "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subject_category: (encode-path-segment $subject_category), object_category: (encode-path-segment $object_category)} | format pattern "/relation/usage/between/{subject_category}/{object_category}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"subject_taxon": $subject_taxon, "evidence": $evidence} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Relation usage count for all subj x obj category combinations
#
# GET /relation/usage/pivot
# operationId: get_relation_usage_pivot_resource
export def "relation-usage-pivot get-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject-taxon: string # SUBJECT TAXON id, e.g. NCBITaxon:9606. Includes inferred by default
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting ibject, e.g. ZFIN:ZDB-PUB-060503-2.
]: nothing -> table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subject_taxon" $subject_taxon "scalar") (serialize-qp "evidence" $evidence "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/relation/usage/pivot" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"subject_taxon": $subject_taxon, "evidence": $evidence} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Relation usage count for all subj x obj category combinations, showing label
#
# GET /relation/usage/pivot/label
# operationId: get_relation_usage_pivot_label_resource
export def "relation-usage-pivot-label get-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject-taxon: string # SUBJECT TAXON id, e.g. NCBITaxon:9606. Includes inferred by default
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting ibject, e.g. ZFIN:ZDB-PUB-060503-2.
]: nothing -> table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subject_taxon" $subject_taxon "scalar") (serialize-qp "evidence" $evidence "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/relation/usage/pivot/label" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"subject_taxon": $subject_taxon, "evidence": $evidence} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of matching concepts or entities using lexical search
#
# GET /search/entity/autocomplete/{term}
# operationId: get_autocomplete
export def "search-entity-autocomplete get" [
  term: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fq: list<string> # fq string passed directly to solr, note that multiple filters will be combined with an AND operator. Combining fq_string with other parameters may result in unexpected behavior.
  --category: list<string> # e.g. gene, disease
  --prefix: list<string> # ontology prefix: HP, -MONDO
  --include-eqs: oneof<nothing, bool> # Include equivalent ids in prefix filter (default: false)
  --boost-fx: list<string> # boost function e.g. pow(edges,0.334)
  --boost-q: list<string> # boost query e.g. category:genotype^-10
  --taxon: list<string> # taxon filter, eg NCBITaxon:9606, includes inferred taxa
  --rows: int # number of rows (default: 20)
  --start: string # row number to start from (default: 0)
  --highlight-class: string # highlight class
  --min-match: string # minimum should match parameter, see solr docs for details
  --exclude-groups: oneof<nothing, bool> # Exclude grouping classes (classes with subclasses) (default: false)
  --minimal-tokenizer: oneof<nothing, bool> # set to true to use the minimal tokenizer, good for variants and genotypes (default: false)
]: nothing -> record<docs: table<category: list, equivalent_ids: list, has_highlight: bool, highlight: string, id: string, label: list, match: string, taxon: string, taxon_label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($term | is-empty) { error make --unspanned { msg: "path parameter 'term' must be non-empty" } }
  let qp = [(serialize-qp "fq" $fq "multi") (serialize-qp "category" $category "multi") (serialize-qp "prefix" $prefix "multi") (serialize-qp "include_eqs" $include_eqs "scalar") (serialize-qp "boost_fx" $boost_fx "multi") (serialize-qp "boost_q" $boost_q "multi") (serialize-qp "taxon" $taxon "multi") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "highlight_class" $highlight_class "scalar") (serialize-qp "min_match" $min_match "scalar") (serialize-qp "exclude_groups" $exclude_groups "scalar") (serialize-qp "minimal_tokenizer" $minimal_tokenizer "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({term: (encode-path-segment $term)} | format pattern "/search/entity/autocomplete/{term}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fq": $fq, "category": $category, "prefix": $prefix, "include_eqs": $include_eqs, "boost_fx": $boost_fx, "boost_q": $boost_q, "taxon": $taxon, "rows": $rows, "start": $start, "highlight_class": $highlight_class, "min_match": $min_match, "exclude_groups": $exclude_groups, "minimal_tokenizer": $minimal_tokenizer} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of matching concepts or entities using lexical search
#
# GET /search/entity/hpo-pl/{term}
# operationId: get_search_hpo_entities
export def "search-entity-hpo-pl get-entities" [
  term: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 10)
  --start: string # row number to start from (default: 0)
  --phenotype-group: string # phenotype group id
  --phenotype-group-label: string # phenotype group label
  --anatomical-system: string # anatomical system id
  --anatomical-system-label: string # anatomical system label
  --highlight-class: string # highlight class
]: nothing -> record<results: table<highlight: string, id: string, label: string, matched_synonym: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($term | is-empty) { error make --unspanned { msg: "path parameter 'term' must be non-empty" } }
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "phenotype_group" $phenotype_group "scalar") (serialize-qp "phenotype_group_label" $phenotype_group_label "scalar") (serialize-qp "anatomical_system" $anatomical_system "scalar") (serialize-qp "anatomical_system_label" $anatomical_system_label "scalar") (serialize-qp "highlight_class" $highlight_class "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({term: (encode-path-segment $term)} | format pattern "/search/entity/hpo-pl/{term}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rows": $rows, "start": $start, "phenotype_group": $phenotype_group, "phenotype_group_label": $phenotype_group_label, "anatomical_system": $anatomical_system, "anatomical_system_label": $anatomical_system_label, "highlight_class": $highlight_class} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of matching concepts or entities using lexical search
#
# GET /search/entity/{term}
# operationId: get_search_entities
export def "search-entity get-entities" [
  term: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fq: list<string> # fq string passed directly to solr, note that multiple filters will be combined with an AND operator. Combining fq_string with other parameters may result in unexpected behavior.
  --category: list<string> # e.g. gene, disease
  --prefix: list<string> # ontology prefix: HP, -MONDO
  --include-eqs: oneof<nothing, bool> # Include equivalent ids in prefix filter (default: false)
  --boost-fx: list<string> # boost function e.g. pow(edges,0.334)
  --boost-q: list<string> # boost query e.g. category:genotype^-10
  --taxon: list<string> # taxon filter, eg NCBITaxon:9606, includes inferred taxa
  --rows: int # number of rows (default: 20)
  --start: string # row number to start from (default: 0)
  --highlight-class: string # highlight class
  --min-match: string # minimum should match parameter, see solr docs for details
  --exclude-groups: oneof<nothing, bool> # Exclude grouping classes (classes with subclasses) (default: false)
  --minimal-tokenizer: oneof<nothing, bool> # set to true to use the minimal tokenizer, good for variants and genotypes (default: false)
]: nothing -> record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($term | is-empty) { error make --unspanned { msg: "path parameter 'term' must be non-empty" } }
  let qp = [(serialize-qp "fq" $fq "multi") (serialize-qp "category" $category "multi") (serialize-qp "prefix" $prefix "multi") (serialize-qp "include_eqs" $include_eqs "scalar") (serialize-qp "boost_fx" $boost_fx "multi") (serialize-qp "boost_q" $boost_q "multi") (serialize-qp "taxon" $taxon "multi") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "highlight_class" $highlight_class "scalar") (serialize-qp "min_match" $min_match "scalar") (serialize-qp "exclude_groups" $exclude_groups "scalar") (serialize-qp "minimal_tokenizer" $minimal_tokenizer "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({term: (encode-path-segment $term)} | format pattern "/search/entity/{term}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fq": $fq, "category": $category, "prefix": $prefix, "include_eqs": $include_eqs, "boost_fx": $boost_fx, "boost_q": $boost_q, "taxon": $taxon, "rows": $rows, "start": $start, "highlight_class": $highlight_class, "min_match": $min_match, "exclude_groups": $exclude_groups, "minimal_tokenizer": $minimal_tokenizer} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Compare a reference profile vs one profiles
#
# GET /sim/compare
# operationId: get_sim_compare
export def "sim-compare get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-feature-set: oneof<nothing, bool> # set to true if *all* input ids are phenotypic features, else set to false (default: true)
  --metric: string@metric-completer # Metric for computing similarity (default: phenodigm)
  --ref-id: list<string> # A phenotype or identifier that is composed of phenotypes (eg disease, gene) (default: [])
  --query-id: list<string> # A phenotype or identifier that is composed of phenotypes (eg disease, gene) (default: [])
]: nothing -> record<matches: list<record>, metadata: record<max_max_ic: float>, query: record<ids: list<record>, negated_ids: list<record>, reference: record, target_ids: list<list>, unresolved_ids: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "is_feature_set" $is_feature_set "scalar") (serialize-qp "metric" $metric "scalar") (serialize-qp "ref_id" $ref_id "multi") (serialize-qp "query_id" $query_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/sim/compare" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"is_feature_set": $is_feature_set, "metric": $metric, "ref_id": $ref_id, "query_id": $query_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Compare a reference profile vs one or more profiles
#
# POST /sim/compare
# operationId: post_sim_compare
export def "sim-compare create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query-ids: list # list of query profiles
  --reference-ids: list<string> # list of ids
]: any -> record<matches: list<record>, metadata: record<max_max_ic: float>, query: record<ids: list<record>, negated_ids: list<record>, reference: record, target_ids: list<list>, unresolved_ids: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sim/compare" $auth.query)
  let req_body = {"query_ids": $query_ids, "reference_ids": $reference_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get annotation score
#
# GET /sim/score
# operationId: get_annotation_score
export def "sim-score get-annotation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Phenotype identifier (eg HP:0004935)
  --absent-id: list<string> # absent phenotype (eg HP:0002828) (default: [])
]: nothing -> record<categorical_score: float, scaled_score: float, simple_score: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi") (serialize-qp "absent_id" $absent_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/sim/score" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id, "absent_id": $absent_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get annotation score
#
# POST /sim/score
# operationId: post_annotation_score
# --features item shape: {id?: string, isPresent?: bool, label?: string, type?: string}
export def "sim-score create-annotation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --features: list # list of features — item shape: {id?: string, isPresent?: bool, label?: string, type?: string}
  --id: string # curie formatted id
]: any -> record<categorical_score: float, scaled_score: float, simple_score: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sim/score" $auth.query)
  let req_body = {"features": $features, "id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Search for phenotypically similar diseases or model genes
#
# GET /sim/search
# operationId: get_sim_search
export def "sim-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-feature-set: oneof<nothing, bool> # set to true if *all* input ids are phenotypic features, else set to false (default: true)
  --metric: string@metric-completer # Metric for computing similarity (default: phenodigm)
  --id: list<string> # A phenotype or identifier that is composed of phenotypes (eg disease, gene) (default: [])
  --limit: int # number of rows, max 500 (default: 20)
  --taxon: string # ncbi taxon id
]: nothing -> record<matches: list<record>, metadata: record<max_max_ic: float>, query: record<ids: list<record>, negated_ids: list<record>, reference: record, target_ids: list<list>, unresolved_ids: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "is_feature_set" $is_feature_set "scalar") (serialize-qp "metric" $metric "scalar") (serialize-qp "id" $id "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "taxon" $taxon "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sim/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"is_feature_set": $is_feature_set, "metric": $metric, "id": $id, "limit": $limit, "taxon": $taxon} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of variant sets
#
# GET /variation/set/
# operationId: get_variant_sets_collection
export def "variation-set get-variant-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number (default: 1)
  --per-page: int@per-page-completer # Results per page {error_msg} (default: 10)
]: nothing -> record<page: int, pages: int, per_page: int, total: int, items: table<body: string, category: string, category_id: int, id: int, pub_date: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/variation/set/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new variant set
#
# POST /variation/set/
# operationId: post_variant_sets_collection
export def "variation-set create-variant-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Article content
  --category: string
  --category-id: int
  --id: int # The unique identifier of a variant set
  --pub-date: string # format: date-time
  title: string # Article title
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/variation/set/" $auth.query)
  let req_body = {"body": $body, "category": $category, "category_id": $category_id, "id": $id, "pub_date": $pub_date, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns list of matches
#
# GET /variation/set/analyze/{id}
# operationId: get_variant_analyze
export def "variation-set-analyze get-variant" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record, slim: list<string>, subject: record, subject_eq: list<string>, subject_extensions: list<record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/variation/set/analyze/{id}") $auth.query)
  let accept_val = "application/json"
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

# Returns list of variant sets from a specified time period
#
# GET /variation/set/archive/{year}/{month}/{day}
# operationId: get_variant_sets_archive_collection
export def "variation-set-archive get-variant-collection" [
  year: int
  month: int
  day: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number (default: 1)
  --per-page: int@per-page-completer # Results per page {error_msg} (default: 10)
]: nothing -> record<page: int, pages: int, per_page: int, total: int, items: table<body: string, category: string, category_id: int, id: int, pub_date: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  if ($month | is-empty) { error make --unspanned { msg: "path parameter 'month' must be non-empty" } }
  if ($day | is-empty) { error make --unspanned { msg: "path parameter 'day' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({year: (encode-path-segment $year), month: (encode-path-segment $month), day: (encode-path-segment $day)} | format pattern "/variation/set/archive/{year}/{month}/{day}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes variant set
#
# DELETE /variation/set/{id}
# operationId: delete_variant_set_item
export def "variation-set delete-variant-item" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/variation/set/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Returns a variant set
#
# GET /variation/set/{id}
# operationId: get_variant_set_item
export def "variation-set get-variant-item" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<body: string, category: string, category_id: int, id: int, pub_date: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/variation/set/{id}") $auth.query)
  let accept_val = "application/json"
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

# Updates a variant set
#
# PUT /variation/set/{id}
# operationId: put_variant_set_item
export def "variation-set update-variant-item" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Article content
  --category: string
  --category-id: int
  --body-id: int # The unique identifier of a variant set
  --pub-date: string # format: date-time
  title: string # Article title
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/variation/set/{id}") $auth.query)
  let req_body = {"body": $body, "category": $category, "category_id": $category_id, "id": $body_id, "pub_date": $pub_date, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}
