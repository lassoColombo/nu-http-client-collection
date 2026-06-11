# Auto-generated client for iNaturalist API v1.3.0
# Source: https://api.inaturalist.org/v1/swagger.json
# Auth: --token flag or $env.INATURALIST_API_TOKEN

const BASE_URL = "http://localhost/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o INATURALIST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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
def base-url-completer [] { ["http://localhost/v1" "https://localhost/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def vote-completer [] { ["down" "up"] }
def rank-completer [] { ["class" "epifamily" "family" "form" "genus" "genushybrid" "hybrid" "infraorder" "kingdom" "order" "phylum" "species" "stateofmatter" "subclass" "subfamily" "suborder" "subphylum" "subspecies" "subtribe" "superclass" "superfamily" "superorder" "supertribe" "tribe" "variety"] }
def observation-rank-completer [] { ["class" "epifamily" "family" "form" "genus" "genushybrid" "hybrid" "infraorder" "kingdom" "order" "phylum" "species" "stateofmatter" "subclass" "subfamily" "suborder" "subphylum" "subspecies" "subtribe" "superclass" "superfamily" "superorder" "supertribe" "tribe" "variety"] }
def current-completer [] { ["any" "false" "true"] }
def category-completer [] { ["improving" "leading" "maverick" "supporting"] }
def quality-grade-completer [] { ["casual" "needs_id" "research"] }
def lrank-completer [] { ["class" "epifamily" "family" "form" "genus" "genushybrid" "hybrid" "infraorder" "kingdom" "order" "phylum" "species" "stateofmatter" "subclass" "subfamily" "suborder" "subphylum" "subspecies" "subtribe" "superclass" "superfamily" "superorder" "supertribe" "tribe" "variety"] }
def hrank-completer [] { ["class" "epifamily" "family" "form" "genus" "genushybrid" "hybrid" "infraorder" "kingdom" "order" "phylum" "species" "stateofmatter" "subclass" "subfamily" "suborder" "subphylum" "subspecies" "subtribe" "superclass" "superfamily" "superorder" "supertribe" "tribe" "variety"] }
def observation-lrank-completer [] { ["class" "epifamily" "family" "form" "genus" "genushybrid" "hybrid" "infraorder" "kingdom" "order" "phylum" "species" "stateofmatter" "subclass" "subfamily" "suborder" "subphylum" "subspecies" "subtribe" "superclass" "superfamily" "superorder" "supertribe" "tribe" "variety"] }
def observation-hrank-completer [] { ["class" "epifamily" "family" "form" "genus" "genushybrid" "hybrid" "infraorder" "kingdom" "order" "phylum" "species" "stateofmatter" "subclass" "subfamily" "suborder" "subphylum" "subspecies" "subtribe" "superclass" "superfamily" "superorder" "supertribe" "tribe" "variety"] }
def order-completer [] { ["asc" "desc"] }
def order-by-completer [] { ["created_at" "id"] }
def taxon-of-completer [] { ["identification" "observation"] }
def license-completer [] { ["cc-by" "cc-by-nc" "cc-by-nc-nd" "cc-by-nc-sa" "cc-by-nd" "cc-by-sa" "cc0"] }
def photo-license-completer [] { ["cc-by" "cc-by-nc" "cc-by-nc-nd" "cc-by-nc-sa" "cc-by-nd" "cc-by-sa" "cc0"] }
def sound-license-completer [] { ["cc-by" "cc-by-nc" "cc-by-nc-nd" "cc-by-nc-sa" "cc-by-nd" "cc-by-sa" "cc0"] }
def csi-completer [] { ["CR" "EN" "EW" "EX" "LC" "NT" "VU"] }
def geoprivacy-completer [] { ["obscured" "obscured_private" "open" "private"] }
def taxon-geoprivacy-completer [] { ["obscured" "obscured_private" "open" "private"] }
def obscuration-completer [] { ["none" "obscured" "private"] }
def iconic-taxa-completer [] { ["Actinopterygii" "Amphibia" "Animalia" "Arachnida" "Aves" "Chromista" "Fungi" "Insecta" "Mammalia" "Mollusca" "Plantae" "Protozoa" "Reptilia" "unknown"] }
def identifications-completer [] { ["most_agree" "most_disagree" "some_agree"] }
def search-on-completer [] { ["description" "names" "place" "tags"] }
def box-completer [] { ["any" "inbox" "sent"] }
def scope-completer [] { ["needs_id"] }
def order-by-completer-1 [] { ["created_at" "geo_score" "id" "observed_on" "random" "species_guess" "updated_at" "votes"] }
def date-field-completer [] { ["created" "observed"] }
def interval-completer [] { ["day" "hour" "month" "month_of_year" "week" "week_of_year" "year"] }
def observations-by-completer [] { ["following" "owner"] }
def admin-level-completer [] { ["-10" "0" "10" "100" "20" "30"] }
def order-by-completer-2 [] { ["area"] }
def featured-completer [] { ["true"] }
def noteworthy-completer [] { ["true"] }
def rule-details-completer [] { ["true"] }
def type-completer [] { ["collection" "umbrella"] }
def order-by-completer-3 [] { ["created" "distance" "featured" "recent_posts" "updated"] }
def role-completer [] { ["curator" "manager"] }
def sources-completer [] { ["places" "projects" "taxa" "users"] }
def order-by-completer-4 [] { ["created_at" "id" "observations_count"] }
def project-type-completer [] { ["collection" "traditional" "umbrella"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "annotations post" } } | get name | first)
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

# Annotation Create
#
# POST /annotations
# --annotation shape: {resource_type?: "Observation", resource_id?: int, controlled_attribute_id?: int, controlled_value_id?: int}
export def "annotations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --annotation: record # shape: {resource_type?: "Observation", resource_id?: int, controlled_attribute_id?: int, controlled_value_id?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/annotations")
  let body = {annotation: $annotation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Annotation Delete
#
# DELETE /annotations/{id}
export def "annotations delete" [
  id: string
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
  let full_url = (build-url $base $"/annotations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Annotation Vote
#
# POST /votes/vote/annotation/{id}
export def "votes-vote-annotation post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --vote: string@vote-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/votes/vote/annotation/($id)")
  let body = {vote: $vote} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Annotation Unvote
#
# DELETE /votes/unvote/annotation/{id}
export def "votes-unvote-annotation delete" [
  id: string
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
  let full_url = (build-url $base $"/votes/unvote/annotation/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Comment Create
#
# POST /comments
# --comment shape: {parent_type?: "Observation"|"ListedTaxon"|"AssessmentSection"|"ObservationField"|"Post"|"TaxonChange", parent_id?: int, body?: string}
export def "comments post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --comment: record # shape: {parent_type?: "Observation"|"ListedTaxon"|"AssessmentSection"|"ObservationField"|"Post"|"TaxonChange", parent_id?: int, body?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/comments")
  let body = {comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Comment Update
#
# PUT /comments/{id}
# --comment shape: {parent_type?: "Observation"|"ListedTaxon"|"AssessmentSection"|"ObservationField"|"Post"|"TaxonChange", parent_id?: int, body?: string}
export def "comments put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --comment: record # shape: {parent_type?: "Observation"|"ListedTaxon"|"AssessmentSection"|"ObservationField"|"Post"|"TaxonChange", parent_id?: int, body?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comments/($id)")
  let body = {comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Comment Delete
#
# DELETE /comments/{id}
export def "comments delete" [
  id: int
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
  let full_url = (build-url $base $"/comments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Terms Index
#
# GET /controlled_terms
export def "controlled-terms get" [
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
  let full_url = (build-url $base "/controlled_terms")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Terms for Taxon
#
# GET /controlled_terms/for_taxon
export def "controlled-terms-for-taxon get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --taxon-id: int # Filter by this taxon
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "taxon_id" $taxon_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/controlled_terms/for_taxon" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Flag Create
#
# POST /flags
# --flag shape: {flaggable_type?: "Comment"|"Identification"|"Message"|"Observation"|"Post"|"Taxon", flaggable_id?: int, flag?: "spam"|"inappropriate"|"other"}
export def "flags post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --flag: record # shape: {flaggable_type?: "Comment"|"Identification"|"Message"|"Observation"|"Post"|"Taxon", flaggable_id?: int, flag?: "spam"|"inappropriate"|"other"}
  --flag-explanation: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/flags")
  let body = {flag: $flag, flag_explanation: $flag_explanation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Flag Update
#
# PUT /flags/{id}
# --flag shape: {resolved?: bool}
export def "flags put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --flag: record # shape: {resolved?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/flags/($id)")
  let body = {flag: $flag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Flag Delete
#
# DELETE /flags/{id}
export def "flags delete" [
  id: int
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
  let full_url = (build-url $base $"/flags/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Identification Details
#
# GET /identifications/{id}
export def "identifications get" [
  id: list
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
  let full_url = (build-url $base $"/identifications/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Identification Update
#
# PUT /identifications/{id}
# --identification shape: {observation_id?: int, taxon_id?: int, current?: bool, body?: string}
export def "identifications put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identification: record # shape: {observation_id?: int, taxon_id?: int, current?: bool, body?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/identifications/($id)")
  let body = {identification: $identification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Identification Delete
#
# DELETE /identifications/{id}
export def "identifications delete" [
  id: int
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
  let full_url = (build-url $base $"/identifications/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Identification Create
#
# POST /identifications
# --identification shape: {observation_id?: int, taxon_id?: int, current?: bool, body?: string}
export def "identifications post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identification: record # shape: {observation_id?: int, taxon_id?: int, current?: bool, body?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/identifications")
  let body = {identification: $identification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Identification Search
#
# GET /identifications
export def "identifications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --current-taxon: string@bool-completer # ID's taxon is the same it's observation's taxon
  --own-observation: string@bool-completer # ID was added by the observer
  --is-change: string@bool-completer # ID was created as a results of a taxon change
  --taxon-active: string@bool-completer # ID's taxon is currently an active taxon
  --observation-taxon-active: string@bool-completer # Observation's taxon is currently an active taxon
  --id: list # Identification ID
  --rank: list@rank-completer # ID's taxon must have this rank
  --observation-rank: list@observation-rank-completer # Observation's taxon must have this rank
  --user-id: list # Identifier must have this user ID
  --user-login: list # Identifier must have this login
  --current: string@bool-completer # Most recent ID on a observation by a user (default: true)
  --category: list@category-completer # Type of identification
  --place-id: list # Observation must occur in this place
  --quality-grade: list@quality-grade-completer # Observation must have this quality grade
  --taxon-change-id: list # Only return identifications that were created as part of the specified taxon change
  --taxon-id: list # ID taxa must match the given taxa or their descendants
  --observation-taxon-id: list # Observation taxa must match the given taxa or their descendants
  --iconic-taxon-id: list # ID iconic taxon ID
  --observation-iconic-taxon-id: list # Observation iconic taxon ID
  --lrank: string@lrank-completer # ID taxon must have this rank or higher
  --hrank: string@hrank-completer # ID taxon must have this rank or lower
  --observation-lrank: string@observation-lrank-completer # Observation taxon must have this rank or higher
  --observation-hrank: string@observation-hrank-completer # Observation taxon must have this rank or lower
  --without-taxon-id: list # Exclude IDs of these taxa and their descendants
  --without-observation-taxon-id: list # Exclude IDs of observations of these taxa and their descendants
  --d1: string # ID created on or after this time (format: date)
  --d2: string # ID created on or before this time (format: date)
  --observation-created-d1: string # Observation created on or after this date (format: date)
  --observation-created-d2: string # Observation created on or before this date (format: date)
  --observed-d1: string # Observation observed on or after this date (format: date)
  --observed-d2: string # Observation observed on or before this date (format: date)
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --page: string # Pagination `page` number
  --per-page: string # Number of results to return in a `page`. The maximum value is generally 200 unless otherwise noted
  --order: string@order-completer # Sort order (default: desc)
  --order-by: string@order-by-completer # Sort field (default: created_at)
  --only-id: string@bool-completer # Return only the record IDs
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "current_taxon" $current_taxon "scalar") (serialize-qp "own_observation" $own_observation "scalar") (serialize-qp "is_change" $is_change "scalar") (serialize-qp "taxon_active" $taxon_active "scalar") (serialize-qp "observation_taxon_active" $observation_taxon_active "scalar") (serialize-qp "id" $id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "observation_rank" $observation_rank "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "current" $current "scalar") (serialize-qp "category" $category "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "quality_grade" $quality_grade "csv") (serialize-qp "taxon_change_id" $taxon_change_id "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "observation_taxon_id" $observation_taxon_id "csv") (serialize-qp "iconic_taxon_id" $iconic_taxon_id "csv") (serialize-qp "observation_iconic_taxon_id" $observation_iconic_taxon_id "csv") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "observation_lrank" $observation_lrank "scalar") (serialize-qp "observation_hrank" $observation_hrank "scalar") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "without_observation_taxon_id" $without_observation_taxon_id "csv") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "observation_created_d1" $observation_created_d1 "scalar") (serialize-qp "observation_created_d2" $observation_created_d2 "scalar") (serialize-qp "observed_d1" $observed_d1 "scalar") (serialize-qp "observed_d2" $observed_d2 "scalar") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "only_id" $only_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/identifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Identification Categories
#
# GET /identifications/categories
export def "identifications-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --current-taxon: string@bool-completer # ID's taxon is the same it's observation's taxon
  --own-observation: string@bool-completer # ID was added by the observer
  --is-change: string@bool-completer # ID was created as a results of a taxon change
  --taxon-active: string@bool-completer # ID's taxon is currently an active taxon
  --observation-taxon-active: string@bool-completer # Observation's taxon is currently an active taxon
  --id: list # Identification ID
  --rank: list@rank-completer # ID's taxon must have this rank
  --observation-rank: list@observation-rank-completer # Observation's taxon must have this rank
  --user-id: list # Identifier must have this user ID
  --user-login: list # Identifier must have this login
  --current: string@bool-completer # Most recent ID on a observation by a user (default: true)
  --category: list@category-completer # Type of identification
  --place-id: list # Observation must occur in this place
  --quality-grade: list@quality-grade-completer # Observation must have this quality grade
  --taxon-change-id: list # Only return identifications that were created as part of the specified taxon change
  --taxon-id: list # ID taxa must match the given taxa or their descendants
  --observation-taxon-id: list # Observation taxa must match the given taxa or their descendants
  --iconic-taxon-id: list # ID iconic taxon ID
  --observation-iconic-taxon-id: list # Observation iconic taxon ID
  --lrank: string@lrank-completer # ID taxon must have this rank or higher
  --hrank: string@hrank-completer # ID taxon must have this rank or lower
  --observation-lrank: string@observation-lrank-completer # Observation taxon must have this rank or higher
  --observation-hrank: string@observation-hrank-completer # Observation taxon must have this rank or lower
  --without-taxon-id: list # Exclude IDs of these taxa and their descendants
  --without-observation-taxon-id: list # Exclude IDs of observations of these taxa and their descendants
  --d1: string # ID created on or after this time (format: date)
  --d2: string # ID created on or before this time (format: date)
  --observation-created-d1: string # Observation created on or after this date (format: date)
  --observation-created-d2: string # Observation created on or before this date (format: date)
  --observed-d1: string # Observation observed on or after this date (format: date)
  --observed-d2: string # Observation observed on or before this date (format: date)
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --page: string # Pagination `page` number
  --per-page: string # Number of results to return in a `page`. The maximum value is generally 200 unless otherwise noted
  --order: string@order-completer # Sort order (default: desc)
  --order-by: string@order-by-completer # Sort field (default: created_at)
  --only-id: string@bool-completer # Return only the record IDs
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "current_taxon" $current_taxon "scalar") (serialize-qp "own_observation" $own_observation "scalar") (serialize-qp "is_change" $is_change "scalar") (serialize-qp "taxon_active" $taxon_active "scalar") (serialize-qp "observation_taxon_active" $observation_taxon_active "scalar") (serialize-qp "id" $id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "observation_rank" $observation_rank "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "current" $current "scalar") (serialize-qp "category" $category "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "quality_grade" $quality_grade "csv") (serialize-qp "taxon_change_id" $taxon_change_id "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "observation_taxon_id" $observation_taxon_id "csv") (serialize-qp "iconic_taxon_id" $iconic_taxon_id "csv") (serialize-qp "observation_iconic_taxon_id" $observation_iconic_taxon_id "csv") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "observation_lrank" $observation_lrank "scalar") (serialize-qp "observation_hrank" $observation_hrank "scalar") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "without_observation_taxon_id" $without_observation_taxon_id "csv") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "observation_created_d1" $observation_created_d1 "scalar") (serialize-qp "observation_created_d2" $observation_created_d2 "scalar") (serialize-qp "observed_d1" $observed_d1 "scalar") (serialize-qp "observed_d2" $observed_d2 "scalar") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "only_id" $only_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/identifications/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Identification Species Counts
#
# GET /identifications/species_counts
export def "identifications-species-counts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --current-taxon: string@bool-completer # ID's taxon is the same it's observation's taxon
  --own-observation: string@bool-completer # ID was added by the observer
  --is-change: string@bool-completer # ID was created as a results of a taxon change
  --taxon-active: string@bool-completer # ID's taxon is currently an active taxon
  --observation-taxon-active: string@bool-completer # Observation's taxon is currently an active taxon
  --id: list # Identification ID
  --rank: list@rank-completer # ID's taxon must have this rank
  --observation-rank: list@observation-rank-completer # Observation's taxon must have this rank
  --user-id: list # Identifier must have this user ID
  --user-login: list # Identifier must have this login
  --current: string@bool-completer # Most recent ID on a observation by a user (default: true)
  --category: list@category-completer # Type of identification
  --place-id: list # Observation must occur in this place
  --quality-grade: list@quality-grade-completer # Observation must have this quality grade
  --taxon-change-id: list # Only return identifications that were created as part of the specified taxon change
  --taxon-id: list # ID taxa must match the given taxa or their descendants
  --observation-taxon-id: list # Observation taxa must match the given taxa or their descendants
  --iconic-taxon-id: list # ID iconic taxon ID
  --observation-iconic-taxon-id: list # Observation iconic taxon ID
  --lrank: string@lrank-completer # ID taxon must have this rank or higher
  --hrank: string@hrank-completer # ID taxon must have this rank or lower
  --observation-lrank: string@observation-lrank-completer # Observation taxon must have this rank or higher
  --observation-hrank: string@observation-hrank-completer # Observation taxon must have this rank or lower
  --without-taxon-id: list # Exclude IDs of these taxa and their descendants
  --without-observation-taxon-id: list # Exclude IDs of observations of these taxa and their descendants
  --d1: string # ID created on or after this time (format: date)
  --d2: string # ID created on or before this time (format: date)
  --observation-created-d1: string # Observation created on or after this date (format: date)
  --observation-created-d2: string # Observation created on or before this date (format: date)
  --observed-d1: string # Observation observed on or after this date (format: date)
  --observed-d2: string # Observation observed on or before this date (format: date)
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --page: string # Pagination `page` number
  --per-page: string # Number of results to return in a `page`. The maximum value is generally 200 unless otherwise noted
  --order: string@order-completer # Sort order (default: desc)
  --order-by: string@order-by-completer # Sort field (default: created_at)
  --only-id: string@bool-completer # Return only the record IDs
  --taxon-of: string@taxon-of-completer # Source of the taxon for counting (default: identification)
  --order: string@order-completer # Sort order (default: desc)
]: nothing -> record<total_results: int, page: int, per_page: int, results: table<count: int, taxon: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "current_taxon" $current_taxon "scalar") (serialize-qp "own_observation" $own_observation "scalar") (serialize-qp "is_change" $is_change "scalar") (serialize-qp "taxon_active" $taxon_active "scalar") (serialize-qp "observation_taxon_active" $observation_taxon_active "scalar") (serialize-qp "id" $id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "observation_rank" $observation_rank "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "current" $current "scalar") (serialize-qp "category" $category "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "quality_grade" $quality_grade "csv") (serialize-qp "taxon_change_id" $taxon_change_id "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "observation_taxon_id" $observation_taxon_id "csv") (serialize-qp "iconic_taxon_id" $iconic_taxon_id "csv") (serialize-qp "observation_iconic_taxon_id" $observation_iconic_taxon_id "csv") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "observation_lrank" $observation_lrank "scalar") (serialize-qp "observation_hrank" $observation_hrank "scalar") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "without_observation_taxon_id" $without_observation_taxon_id "csv") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "observation_created_d1" $observation_created_d1 "scalar") (serialize-qp "observation_created_d2" $observation_created_d2 "scalar") (serialize-qp "observed_d1" $observed_d1 "scalar") (serialize-qp "observed_d2" $observed_d2 "scalar") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "only_id" $only_id "scalar") (serialize-qp "taxon_of" $taxon_of "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/identifications/species_counts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Identification Identifiers
#
# GET /identifications/identifiers
export def "identifications-identifiers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --current-taxon: string@bool-completer # ID's taxon is the same it's observation's taxon
  --own-observation: string@bool-completer # ID was added by the observer
  --is-change: string@bool-completer # ID was created as a results of a taxon change
  --taxon-active: string@bool-completer # ID's taxon is currently an active taxon
  --observation-taxon-active: string@bool-completer # Observation's taxon is currently an active taxon
  --id: list # Identification ID
  --rank: list@rank-completer # ID's taxon must have this rank
  --observation-rank: list@observation-rank-completer # Observation's taxon must have this rank
  --user-id: list # Identifier must have this user ID
  --user-login: list # Identifier must have this login
  --current: string@bool-completer # Most recent ID on a observation by a user (default: true)
  --category: list@category-completer # Type of identification
  --place-id: list # Observation must occur in this place
  --quality-grade: list@quality-grade-completer # Observation must have this quality grade
  --taxon-change-id: list # Only return identifications that were created as part of the specified taxon change
  --taxon-id: list # ID taxa must match the given taxa or their descendants
  --observation-taxon-id: list # Observation taxa must match the given taxa or their descendants
  --iconic-taxon-id: list # ID iconic taxon ID
  --observation-iconic-taxon-id: list # Observation iconic taxon ID
  --lrank: string@lrank-completer # ID taxon must have this rank or higher
  --hrank: string@hrank-completer # ID taxon must have this rank or lower
  --observation-lrank: string@observation-lrank-completer # Observation taxon must have this rank or higher
  --observation-hrank: string@observation-hrank-completer # Observation taxon must have this rank or lower
  --without-taxon-id: list # Exclude IDs of these taxa and their descendants
  --without-observation-taxon-id: list # Exclude IDs of observations of these taxa and their descendants
  --d1: string # ID created on or after this time (format: date)
  --d2: string # ID created on or before this time (format: date)
  --observation-created-d1: string # Observation created on or after this date (format: date)
  --observation-created-d2: string # Observation created on or before this date (format: date)
  --observed-d1: string # Observation observed on or after this date (format: date)
  --observed-d2: string # Observation observed on or before this date (format: date)
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --page: string # Pagination `page` number
  --per-page: string # Number of results to return in a `page`. The maximum value is generally 200 unless otherwise noted
  --order: string@order-completer # Sort order (default: desc)
  --order-by: string@order-by-completer # Sort field (default: created_at)
  --only-id: string@bool-completer # Return only the record IDs
]: nothing -> record<total_results: int, page: int, per_page: int, results: table<count: int, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "current_taxon" $current_taxon "scalar") (serialize-qp "own_observation" $own_observation "scalar") (serialize-qp "is_change" $is_change "scalar") (serialize-qp "taxon_active" $taxon_active "scalar") (serialize-qp "observation_taxon_active" $observation_taxon_active "scalar") (serialize-qp "id" $id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "observation_rank" $observation_rank "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "current" $current "scalar") (serialize-qp "category" $category "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "quality_grade" $quality_grade "csv") (serialize-qp "taxon_change_id" $taxon_change_id "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "observation_taxon_id" $observation_taxon_id "csv") (serialize-qp "iconic_taxon_id" $iconic_taxon_id "csv") (serialize-qp "observation_iconic_taxon_id" $observation_iconic_taxon_id "csv") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "observation_lrank" $observation_lrank "scalar") (serialize-qp "observation_hrank" $observation_hrank "scalar") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "without_observation_taxon_id" $without_observation_taxon_id "csv") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "observation_created_d1" $observation_created_d1 "scalar") (serialize-qp "observation_created_d2" $observation_created_d2 "scalar") (serialize-qp "observed_d1" $observed_d1 "scalar") (serialize-qp "observed_d2" $observed_d2 "scalar") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "only_id" $only_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/identifications/identifiers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Identification Observers
#
# GET /identifications/observers
export def "identifications-observers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --current-taxon: string@bool-completer # ID's taxon is the same it's observation's taxon
  --own-observation: string@bool-completer # ID was added by the observer
  --is-change: string@bool-completer # ID was created as a results of a taxon change
  --taxon-active: string@bool-completer # ID's taxon is currently an active taxon
  --observation-taxon-active: string@bool-completer # Observation's taxon is currently an active taxon
  --id: list # Identification ID
  --rank: list@rank-completer # ID's taxon must have this rank
  --observation-rank: list@observation-rank-completer # Observation's taxon must have this rank
  --user-id: list # Identifier must have this user ID
  --user-login: list # Identifier must have this login
  --current: string@bool-completer # Most recent ID on a observation by a user (default: true)
  --category: list@category-completer # Type of identification
  --place-id: list # Observation must occur in this place
  --quality-grade: list@quality-grade-completer # Observation must have this quality grade
  --taxon-change-id: list # Only return identifications that were created as part of the specified taxon change
  --taxon-id: list # ID taxa must match the given taxa or their descendants
  --observation-taxon-id: list # Observation taxa must match the given taxa or their descendants
  --iconic-taxon-id: list # ID iconic taxon ID
  --observation-iconic-taxon-id: list # Observation iconic taxon ID
  --lrank: string@lrank-completer # ID taxon must have this rank or higher
  --hrank: string@hrank-completer # ID taxon must have this rank or lower
  --observation-lrank: string@observation-lrank-completer # Observation taxon must have this rank or higher
  --observation-hrank: string@observation-hrank-completer # Observation taxon must have this rank or lower
  --without-taxon-id: list # Exclude IDs of these taxa and their descendants
  --without-observation-taxon-id: list # Exclude IDs of observations of these taxa and their descendants
  --d1: string # ID created on or after this time (format: date)
  --d2: string # ID created on or before this time (format: date)
  --observation-created-d1: string # Observation created on or after this date (format: date)
  --observation-created-d2: string # Observation created on or before this date (format: date)
  --observed-d1: string # Observation observed on or after this date (format: date)
  --observed-d2: string # Observation observed on or before this date (format: date)
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --page: string # Pagination `page` number
  --per-page: string # Number of results to return in a `page`. The maximum value is generally 200 unless otherwise noted
  --order: string@order-completer # Sort order (default: desc)
  --order-by: string@order-by-completer # Sort field (default: created_at)
  --only-id: string@bool-completer # Return only the record IDs
]: nothing -> record<total_results: int, page: int, per_page: int, results: table<count: int, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "current_taxon" $current_taxon "scalar") (serialize-qp "own_observation" $own_observation "scalar") (serialize-qp "is_change" $is_change "scalar") (serialize-qp "taxon_active" $taxon_active "scalar") (serialize-qp "observation_taxon_active" $observation_taxon_active "scalar") (serialize-qp "id" $id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "observation_rank" $observation_rank "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "current" $current "scalar") (serialize-qp "category" $category "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "quality_grade" $quality_grade "csv") (serialize-qp "taxon_change_id" $taxon_change_id "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "observation_taxon_id" $observation_taxon_id "csv") (serialize-qp "iconic_taxon_id" $iconic_taxon_id "csv") (serialize-qp "observation_iconic_taxon_id" $observation_iconic_taxon_id "csv") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "observation_lrank" $observation_lrank "scalar") (serialize-qp "observation_hrank" $observation_hrank "scalar") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "without_observation_taxon_id" $without_observation_taxon_id "csv") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "observation_created_d1" $observation_created_d1 "scalar") (serialize-qp "observation_created_d2" $observation_created_d2 "scalar") (serialize-qp "observed_d1" $observed_d1 "scalar") (serialize-qp "observed_d2" $observed_d2 "scalar") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "only_id" $only_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/identifications/observers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Identification Recent Taxa
#
# GET /identifications/recent_taxa
export def "identifications-recent-taxa get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --current-taxon: string@bool-completer # ID's taxon is the same it's observation's taxon
  --own-observation: string@bool-completer # ID was added by the observer
  --is-change: string@bool-completer # ID was created as a results of a taxon change
  --taxon-active: string@bool-completer # ID's taxon is currently an active taxon
  --observation-taxon-active: string@bool-completer # Observation's taxon is currently an active taxon
  --id: list # Identification ID
  --rank: list@rank-completer # ID's taxon must have this rank
  --observation-rank: list@observation-rank-completer # Observation's taxon must have this rank
  --user-id: list # Identifier must have this user ID
  --user-login: list # Identifier must have this login
  --current: string@bool-completer # Most recent ID on a observation by a user (default: true)
  --category: list@category-completer # Type of identification
  --place-id: list # Observation must occur in this place
  --quality-grade: list@quality-grade-completer # Observation must have this quality grade
  --taxon-change-id: list # Only return identifications that were created as part of the specified taxon change
  --taxon-id: list # ID taxa must match the given taxa or their descendants
  --observation-taxon-id: list # Observation taxa must match the given taxa or their descendants
  --iconic-taxon-id: list # ID iconic taxon ID
  --observation-iconic-taxon-id: list # Observation iconic taxon ID
  --lrank: string@lrank-completer # ID taxon must have this rank or higher
  --hrank: string@hrank-completer # ID taxon must have this rank or lower
  --observation-lrank: string@observation-lrank-completer # Observation taxon must have this rank or higher
  --observation-hrank: string@observation-hrank-completer # Observation taxon must have this rank or lower
  --without-taxon-id: list # Exclude IDs of these taxa and their descendants
  --without-observation-taxon-id: list # Exclude IDs of observations of these taxa and their descendants
  --d1: string # ID created on or after this time (format: date)
  --d2: string # ID created on or before this time (format: date)
  --observation-created-d1: string # Observation created on or after this date (format: date)
  --observation-created-d2: string # Observation created on or before this date (format: date)
  --observed-d1: string # Observation observed on or after this date (format: date)
  --observed-d2: string # Observation observed on or before this date (format: date)
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --page: string # Pagination `page` number
  --per-page: string # Number of results to return in a `page`. The maximum value is generally 200 unless otherwise noted
  --order: string@order-completer # Sort order (default: desc)
  --order-by: string@order-by-completer # Sort field (default: created_at)
  --only-id: string@bool-completer # Return only the record IDs
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "current_taxon" $current_taxon "scalar") (serialize-qp "own_observation" $own_observation "scalar") (serialize-qp "is_change" $is_change "scalar") (serialize-qp "taxon_active" $taxon_active "scalar") (serialize-qp "observation_taxon_active" $observation_taxon_active "scalar") (serialize-qp "id" $id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "observation_rank" $observation_rank "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "current" $current "scalar") (serialize-qp "category" $category "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "quality_grade" $quality_grade "csv") (serialize-qp "taxon_change_id" $taxon_change_id "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "observation_taxon_id" $observation_taxon_id "csv") (serialize-qp "iconic_taxon_id" $iconic_taxon_id "csv") (serialize-qp "observation_iconic_taxon_id" $observation_iconic_taxon_id "csv") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "observation_lrank" $observation_lrank "scalar") (serialize-qp "observation_hrank" $observation_hrank "scalar") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "without_observation_taxon_id" $without_observation_taxon_id "csv") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "observation_created_d1" $observation_created_d1 "scalar") (serialize-qp "observation_created_d2" $observation_created_d2 "scalar") (serialize-qp "observed_d1" $observed_d1 "scalar") (serialize-qp "observed_d2" $observed_d2 "scalar") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "only_id" $only_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/identifications/recent_taxa" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Identification Similar Species
#
# GET /identifications/similar_species
export def "identifications-similar-species get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --acc: string@bool-completer # Whether or not positional accuracy / coordinate uncertainty has been specified
  --captive: string@bool-completer # Captive or cultivated observations
  --endemic: string@bool-completer # Observations whose taxa are endemic to their location
  --geo: string@bool-completer # Observations that are georeferenced
  --id-please: string@bool-completer # Observations with the deprecated `ID, Please!` flag. Note that this will return observations, but that this attribute is no longer used.
  --identified: string@bool-completer # Observations that have community identifications
  --introduced: string@bool-completer # Observations whose taxa are introduced in their location
  --mappable: string@bool-completer # Observations that show on map tiles
  --native: string@bool-completer # Observations whose taxa are native to their location
  --out-of-range: string@bool-completer # Observations whose taxa are outside their known ranges
  --pcid: string@bool-completer # Observations identified by the curator of a project. If the `project_id` parameter is also specified, this will only consider observations identified by curators of the specified project(s)
  --photos: string@bool-completer # Observations with photos
  --popular: string@bool-completer # Observations that have been favorited by at least one user
  --sounds: string@bool-completer # Observations with sounds
  --taxon-is-active: string@bool-completer # Observations of active taxon concepts
  --threatened: string@bool-completer # Observations whose taxa are threatened in their location
  --verifiable: string@bool-completer # Observations with a `quality_grade` of either `needs_id` or `research`. Equivalent to `quality_grade=needs_id,research`
  --licensed: string@bool-completer # License attribute of an observation must not be null
  --photo-licensed: string@bool-completer # License attribute of at least one photo of an observation must not be null
  --expected-nearby: string@bool-completer # Observation taxon is expected nearby
  --id: list # Must have this ID
  --not-id: list # Must not have this ID
  --license: list@license-completer # Observation must have this license
  --ofv-datatype: list # Must have an observation field value with this datatype
  --photo-license: list@photo-license-completer # Must have at least one photo with this license
  --place-id: list # Must be observed within the place with this ID
  --project-id: list # Must be added to the project this ID or slug
  --rank: list@rank-completer # Taxon must have this rank
  --site-id: list # Must be affiliated with the iNaturalist network website with this ID
  --sound-license: list@sound-license-completer # Must have at least one sound with this license
  --without-taxon-id: list # Exclude observations of these taxa and their descendants
  --taxon-name: list # Taxon must have a scientific or common name matching this string
  --user-id: list # User must have this ID or login
  --user-login: list # User must have this login
  --ident-user-id: int # Observations identified by a particular user
  --hour: list # Must be observed within this hour of the day
  --day: list # Must be observed within this day of the month
  --month: list # Must be observed within this month
  --year: list # Must be observed within this year
  --created-day: list # Must be created within this day of the month
  --created-month: list # Must be created within this month
  --created-year: list # Must be created within this year
  --term-id: list # Must have an annotation using this controlled term ID
  --term-value-id: list # Must have an annotation using this controlled value ID. Must be combined with the `term_id` parameter
  --without-term-id: int # Exclude observations with annotations using this controlled value ID.
  --without-term-value-id: list # Exclude observations with annotations using this controlled value ID. Must be combined with the `term_id` parameter
  --term-id-or-unknown: list # Must be combined with the `term_value_id` or the `without_term_value_id` parameter. Must have an annotation using this controlled term ID and associated term value IDs or be missing this annotation.
  --annotation-user-id: list # Must have an annotation created by this user
  --acc-above: string # Must have a positional accuracy above this value (meters)
  --acc-below: string # Must have a positional accuracy below this value (meters)
  --acc-below-or-unknown: string # Positional accuracy must be below this value (in meters) or be unknown
  --d1: string # Must be observed on or after this date (format: date)
  --d2: string # Must be observed on or before this date (format: date)
  --created-d1: string # Must be created at or after this time (format: date-time)
  --created-d2: string # Must be created at or before this time (format: date-time)
  --created-on: string # Must be created on this date (format: date)
  --observed-on: string # Must be observed on this date (format: date)
  --unobserved-by-user-id: int # Must not be of a taxon previously observed by this user
  --apply-project-rules-for: string # Must match the rules of the project with this ID or slug
  --cs: string # Taxon must have this conservation status code. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csa: string # Taxon must have a conservation status from this authority. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csi: list@csi-completer # Taxon must have this IUCN conservation status. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --geoprivacy: list@geoprivacy-completer # Must have this geoprivacy setting
  --taxon-geoprivacy: list@taxon-geoprivacy-completer # Filter observations by the most conservative geoprivacy applied by a conservation status associated with one of the taxa proposed in the current identifications.
  --obscuration: list@obscuration-completer # Must have `geoprivacy` or `taxon_geoprivacy` fields matching these values
  --hrank: string@hrank-completer # Taxon must have this rank or lower
  --lrank: string@lrank-completer # Taxon must have this rank or higher
  --iconic-taxa: list@iconic-taxa-completer # Taxon must by within this iconic taxon
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --identifications: string@identifications-completer # Identifications must meet these criteria
  --lat: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --lng: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --radius: string # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)
  --nelat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --nelng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --list-id: int # Taxon must be in the list with this ID
  --not-in-project: string # Must not be in the project with this ID or slug
  --not-matching-project-rules-for: string # Must not match the rules of the project with this ID or slug
  --observation-accuracy-experiment-id: list # Must included in this observation accuracy experiment
  --fails-dqa-accurate: string@bool-completer # Must be voted as not accurately depicting an organism or scene
  --fails-dqa-date: string@bool-completer # Must be voted as not having an accurate date
  --fails-dqa-evidence: string@bool-completer # Must be voted as not evidence of an organism
  --fails-dqa-location: string@bool-completer # Must be voted as not having an accurate location
  --fails-dqa-needs-id: string@bool-completer # Must be voted as the community ID cannot be improved
  --fails-dqa-recent: string@bool-completer # Must be voted as not recent evidence of an organism
  --fails-dqa-subject: string@bool-completer # Must be voted as not having evidence related to a single subject
  --fails-dqa-wild: string@bool-completer # Must be voted as not wild
  --q: string # Search observation properties. Can be combined with `search_on`
  --search-on: string@search-on-completer # Properties to search on, when combined with `q`. Searches across all properties by default
  --quality-grade: string@quality-grade-completer # Must have this quality grade
  --updated-since: string # Must be updated since this time
  --viewer-id: string # See `reviewed`
  --reviewed: string@bool-completer # Observations have been reviewed by the user with ID equal to the value of the `viewer_id` parameter
  --taxon-id: int # Only show observations of these taxa and their descendants
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "acc" $acc "scalar") (serialize-qp "captive" $captive "scalar") (serialize-qp "endemic" $endemic "scalar") (serialize-qp "geo" $geo "scalar") (serialize-qp "id_please" $id_please "scalar") (serialize-qp "identified" $identified "scalar") (serialize-qp "introduced" $introduced "scalar") (serialize-qp "mappable" $mappable "scalar") (serialize-qp "native" $native "scalar") (serialize-qp "out_of_range" $out_of_range "scalar") (serialize-qp "pcid" $pcid "scalar") (serialize-qp "photos" $photos "scalar") (serialize-qp "popular" $popular "scalar") (serialize-qp "sounds" $sounds "scalar") (serialize-qp "taxon_is_active" $taxon_is_active "scalar") (serialize-qp "threatened" $threatened "scalar") (serialize-qp "verifiable" $verifiable "scalar") (serialize-qp "licensed" $licensed "scalar") (serialize-qp "photo_licensed" $photo_licensed "scalar") (serialize-qp "expected_nearby" $expected_nearby "scalar") (serialize-qp "id" $id "csv") (serialize-qp "not_id" $not_id "csv") (serialize-qp "license" $license "csv") (serialize-qp "ofv_datatype" $ofv_datatype "csv") (serialize-qp "photo_license" $photo_license "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "project_id" $project_id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "site_id" $site_id "csv") (serialize-qp "sound_license" $sound_license "csv") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "taxon_name" $taxon_name "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "ident_user_id" $ident_user_id "scalar") (serialize-qp "hour" $hour "csv") (serialize-qp "day" $day "csv") (serialize-qp "month" $month "csv") (serialize-qp "year" $year "csv") (serialize-qp "created_day" $created_day "csv") (serialize-qp "created_month" $created_month "csv") (serialize-qp "created_year" $created_year "csv") (serialize-qp "term_id" $term_id "csv") (serialize-qp "term_value_id" $term_value_id "csv") (serialize-qp "without_term_id" $without_term_id "scalar") (serialize-qp "without_term_value_id" $without_term_value_id "csv") (serialize-qp "term_id_or_unknown" $term_id_or_unknown "csv") (serialize-qp "annotation_user_id" $annotation_user_id "csv") (serialize-qp "acc_above" $acc_above "scalar") (serialize-qp "acc_below" $acc_below "scalar") (serialize-qp "acc_below_or_unknown" $acc_below_or_unknown "scalar") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "created_d1" $created_d1 "scalar") (serialize-qp "created_d2" $created_d2 "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "observed_on" $observed_on "scalar") (serialize-qp "unobserved_by_user_id" $unobserved_by_user_id "scalar") (serialize-qp "apply_project_rules_for" $apply_project_rules_for "scalar") (serialize-qp "cs" $cs "scalar") (serialize-qp "csa" $csa "scalar") (serialize-qp "csi" $csi "csv") (serialize-qp "geoprivacy" $geoprivacy "csv") (serialize-qp "taxon_geoprivacy" $taxon_geoprivacy "csv") (serialize-qp "obscuration" $obscuration "csv") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "iconic_taxa" $iconic_taxa "csv") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "identifications" $identifications "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "nelat" $nelat "scalar") (serialize-qp "nelng" $nelng "scalar") (serialize-qp "swlat" $swlat "scalar") (serialize-qp "swlng" $swlng "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "not_in_project" $not_in_project "scalar") (serialize-qp "not_matching_project_rules_for" $not_matching_project_rules_for "scalar") (serialize-qp "observation_accuracy_experiment_id" $observation_accuracy_experiment_id "csv") (serialize-qp "fails_dqa_accurate" $fails_dqa_accurate "scalar") (serialize-qp "fails_dqa_date" $fails_dqa_date "scalar") (serialize-qp "fails_dqa_evidence" $fails_dqa_evidence "scalar") (serialize-qp "fails_dqa_location" $fails_dqa_location "scalar") (serialize-qp "fails_dqa_needs_id" $fails_dqa_needs_id "scalar") (serialize-qp "fails_dqa_recent" $fails_dqa_recent "scalar") (serialize-qp "fails_dqa_subject" $fails_dqa_subject "scalar") (serialize-qp "fails_dqa_wild" $fails_dqa_wild "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "search_on" $search_on "scalar") (serialize-qp "quality_grade" $quality_grade "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "viewer_id" $viewer_id "scalar") (serialize-qp "reviewed" $reviewed "scalar") (serialize-qp "taxon_id" $taxon_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/identifications/similar_species" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve messages for the authenticated user. This does not mark them as read.
#
# GET /messages
export def "messages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination `page` number
  --box: string@box-completer # Whether to view messages the user has received (default) or messages the user has sent (default: inbox)
  --q: string # Search query for subject and body
  --user-id: string # User ID or username of correspondent to filter by
  --threads: string@bool-completer # Groups results by `thread_id`, only shows the latest message per thread, and includes a `thread_messages_count` attribute showing the total number of messages in that thread. Note that this will not work with the `q` param, and it probably should only be used with `box=any` because the `thread_messages_count` will be inaccurate when you restrict it to `inbox` or `sent`.  (default: false)
]: nothing -> record<total_results: int, page: int, per_page: int, results: table<id: int, subject: string, body: string, user_id: int, to_user: record, from_user: record, thread_id: int, thread_messages_count: int, thread_flags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "box" $box "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "threads" $threads "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new message
#
# POST /messages
# --message shape: {to_user_id?: int, thread_id?: int, subject?: string, body?: string}
export def "messages post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message: record # shape: {to_user_id?: int, thread_id?: int, subject?: string, body?: string}
]: any -> record<id: int, subject: string, body: string, user_id: int, to_user: record<created_at: string, id: int, icon: string, icon_url: string, identifications_count: int, journal_posts_count: int, login: string, name: string, observations_count: int, orcid: string, roles: list<string>, site_id: int, species_count: int, spam: bool, suspended: bool>, from_user: record<created_at: string, id: int, icon: string, icon_url: string, identifications_count: int, journal_posts_count: int, login: string, name: string, observations_count: int, orcid: string, roles: list<string>, site_id: int, species_count: int, spam: bool, suspended: bool>, thread_id: int, thread_messages_count: int, thread_flags: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messages")
  let body = {message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve messages in a thread
#
# GET /messages/{id}
export def "messages get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<reply_to_user: record<created_at: string, id: int, icon: string, icon_url: string, identifications_count: int, journal_posts_count: int, login: string, name: string, observations_count: int, orcid: string, roles: list<string>, site_id: int, species_count: int, spam: bool, suspended: bool>, thread_id: int, flaggable_message_id: int, results: table<id: int, subject: string, body: string, user_id: int, to_user: record, from_user: record, thread_id: int, thread_messages_count: int, thread_flags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a message / thread
#
# DELETE /messages/{id}
export def "messages delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a count of messages the authenticated user has not read
#
# GET /messages/unread
export def "messages-unread get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messages/unread")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observation Details
#
# GET /observations/{id}
export def "observations get" [
  id: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<total_results: int, page: int, per_page: int, results: table<annotations: list, id: int, cached_votes_total: int, captive: bool, comments: list, comments_count: int, created_at: string, created_at_details: record, created_time_zone: string, description: string, faves_count: int, geojson: record, geoprivacy: string, taxon_geoprivacy: string, id_please: bool, identifications_count: int, identifications_most_agree: bool, identifications_most_disagree: bool, identifications_some_agree: bool, license_code: string, location: string, private_location: string, mappable: bool, non_owner_ids: list, num_identification_agreements: int, num_identification_disagreements: int, obscured: bool, observed_on: string, observed_on_details: record, observed_on_string: string, observed_time_zone: string, ofvs: list, out_of_range: bool, photos: list, place_guess: string, private_place_guess: string, place_ids: list, private_place_ids: list, positional_accuracy: int, private_geojson: record, project_ids: list, project_ids_with_curator_id: list, project_ids_without_curator_id: list, public_positional_accuracy: int, quality_grade: string, reviewed_by: list, site_id: int, sounds: list, species_guess: string, tags: list, taxon: record, time_observed_at: string, time_zone_offset: string, updated_at: string, uri: string, user: record, uuid: string, verifiable: bool, observation_photos: list, quality_metrics: list, flags: list, community_taxon_id: int, faves: list, identifications: list, oauth_application_id: int, outlinks: list, owners_identification_from_vision: bool, preferences: record, project_observations: list, spam: bool, votes: list, identification_disagreements_count: int, ident_taxon_ids: list, map_scale: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/observations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observation Update
#
# PUT /observations/{id}
# --observation shape: {species_guess?: string, taxon_id?: int, description?: string}
export def "observations put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --observation: record # shape: {species_guess?: string, taxon_id?: int, description?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/observations/($id)")
  let body = {observation: $observation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Observation Delete
#
# DELETE /observations/{id}
export def "observations delete" [
  id: int
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
  let full_url = (build-url $base $"/observations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observations Fave
#
# POST /observations/{id}/fave
export def "observations-fave post" [
  id: int
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
  let full_url = (build-url $base $"/observations/($id)/fave")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observations Unfave
#
# DELETE /observations/{id}/unfave
export def "observations-unfave delete" [
  id: int
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
  let full_url = (build-url $base $"/observations/($id)/unfave")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observations Review
#
# POST /observations/{id}/review
export def "observations-review post" [
  id: int
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
  let full_url = (build-url $base $"/observations/($id)/review")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observations Unreview
#
# DELETE /observations/{id}/review
export def "observations-review delete" [
  id: int
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
  let full_url = (build-url $base $"/observations/($id)/review")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observation Subscriptions
#
# GET /observations/{id}/subscriptions
export def "observations-subscriptions get" [
  id: int
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
  let full_url = (build-url $base $"/observations/($id)/subscriptions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Quality Metric Set
#
# POST /observations/{id}/quality/{metric}
export def "observations-quality post" [
  id: int
  metric: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agree: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/observations/($id)/quality/($metric)")
  let body = {agree: $agree} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Quality Metric Delete
#
# DELETE /observations/{id}/quality/{metric}
export def "observations-quality delete" [
  id: int
  metric: string
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
  let full_url = (build-url $base $"/observations/($id)/quality/($metric)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observation Taxon Summary
#
# GET /observations/{id}/taxon_summary
export def "observations-taxon-summary get" [
  id: int
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
  let full_url = (build-url $base $"/observations/($id)/taxon_summary")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observation Subscribe
#
# POST /subscriptions/observation/{id}/subscribe
export def "subscriptions-observation-subscribe post" [
  id: int
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
  let full_url = (build-url $base $"/subscriptions/observation/($id)/subscribe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observation Vote
#
# POST /votes/vote/observation/{id}
export def "votes-vote-observation post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --vote: string@vote-completer
  --scope: any@scope-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/votes/vote/observation/($id)")
  let body = {vote: $vote, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Observation Unvote
#
# DELETE /votes/unvote/observation/{id}
export def "votes-unvote-observation delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --vote: string@vote-completer
  --scope: any@scope-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/votes/unvote/observation/($id)")
  let body = {vote: $vote, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Observation Search
#
# GET /observations
export def "observations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --acc: string@bool-completer # Whether or not positional accuracy / coordinate uncertainty has been specified
  --captive: string@bool-completer # Captive or cultivated observations
  --endemic: string@bool-completer # Observations whose taxa are endemic to their location
  --geo: string@bool-completer # Observations that are georeferenced
  --id-please: string@bool-completer # Observations with the deprecated `ID, Please!` flag. Note that this will return observations, but that this attribute is no longer used.
  --identified: string@bool-completer # Observations that have community identifications
  --introduced: string@bool-completer # Observations whose taxa are introduced in their location
  --mappable: string@bool-completer # Observations that show on map tiles
  --native: string@bool-completer # Observations whose taxa are native to their location
  --out-of-range: string@bool-completer # Observations whose taxa are outside their known ranges
  --pcid: string@bool-completer # Observations identified by the curator of a project. If the `project_id` parameter is also specified, this will only consider observations identified by curators of the specified project(s)
  --photos: string@bool-completer # Observations with photos
  --popular: string@bool-completer # Observations that have been favorited by at least one user
  --sounds: string@bool-completer # Observations with sounds
  --taxon-is-active: string@bool-completer # Observations of active taxon concepts
  --threatened: string@bool-completer # Observations whose taxa are threatened in their location
  --verifiable: string@bool-completer # Observations with a `quality_grade` of either `needs_id` or `research`. Equivalent to `quality_grade=needs_id,research`
  --licensed: string@bool-completer # License attribute of an observation must not be null
  --photo-licensed: string@bool-completer # License attribute of at least one photo of an observation must not be null
  --expected-nearby: string@bool-completer # Observation taxon is expected nearby
  --id: list # Must have this ID
  --not-id: list # Must not have this ID
  --license: list@license-completer # Observation must have this license
  --ofv-datatype: list # Must have an observation field value with this datatype
  --photo-license: list@photo-license-completer # Must have at least one photo with this license
  --place-id: list # Must be observed within the place with this ID
  --project-id: list # Must be added to the project this ID or slug
  --rank: list@rank-completer # Taxon must have this rank
  --site-id: list # Must be affiliated with the iNaturalist network website with this ID
  --sound-license: list@sound-license-completer # Must have at least one sound with this license
  --taxon-id: list # Only show observations of these taxa and their descendants
  --without-taxon-id: list # Exclude observations of these taxa and their descendants
  --taxon-name: list # Taxon must have a scientific or common name matching this string
  --user-id: list # User must have this ID or login
  --user-login: list # User must have this login
  --ident-user-id: int # Observations identified by a particular user
  --hour: list # Must be observed within this hour of the day
  --day: list # Must be observed within this day of the month
  --month: list # Must be observed within this month
  --year: list # Must be observed within this year
  --created-day: list # Must be created within this day of the month
  --created-month: list # Must be created within this month
  --created-year: list # Must be created within this year
  --term-id: list # Must have an annotation using this controlled term ID
  --term-value-id: list # Must have an annotation using this controlled value ID. Must be combined with the `term_id` parameter
  --without-term-id: int # Exclude observations with annotations using this controlled value ID.
  --without-term-value-id: list # Exclude observations with annotations using this controlled value ID. Must be combined with the `term_id` parameter
  --term-id-or-unknown: list # Must be combined with the `term_value_id` or the `without_term_value_id` parameter. Must have an annotation using this controlled term ID and associated term value IDs or be missing this annotation.
  --annotation-user-id: list # Must have an annotation created by this user
  --acc-above: string # Must have a positional accuracy above this value (meters)
  --acc-below: string # Must have a positional accuracy below this value (meters)
  --acc-below-or-unknown: string # Positional accuracy must be below this value (in meters) or be unknown
  --d1: string # Must be observed on or after this date (format: date)
  --d2: string # Must be observed on or before this date (format: date)
  --created-d1: string # Must be created at or after this time (format: date-time)
  --created-d2: string # Must be created at or before this time (format: date-time)
  --created-on: string # Must be created on this date (format: date)
  --observed-on: string # Must be observed on this date (format: date)
  --unobserved-by-user-id: int # Must not be of a taxon previously observed by this user
  --apply-project-rules-for: string # Must match the rules of the project with this ID or slug
  --cs: string # Taxon must have this conservation status code. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csa: string # Taxon must have a conservation status from this authority. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csi: list@csi-completer # Taxon must have this IUCN conservation status. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --geoprivacy: list@geoprivacy-completer # Must have this geoprivacy setting
  --taxon-geoprivacy: list@taxon-geoprivacy-completer # Filter observations by the most conservative geoprivacy applied by a conservation status associated with one of the taxa proposed in the current identifications.
  --obscuration: list@obscuration-completer # Must have `geoprivacy` or `taxon_geoprivacy` fields matching these values
  --hrank: string@hrank-completer # Taxon must have this rank or lower
  --lrank: string@lrank-completer # Taxon must have this rank or higher
  --iconic-taxa: list@iconic-taxa-completer # Taxon must by within this iconic taxon
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --identifications: string@identifications-completer # Identifications must meet these criteria
  --lat: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --lng: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --radius: string # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)
  --nelat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --nelng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --list-id: int # Taxon must be in the list with this ID
  --not-in-project: string # Must not be in the project with this ID or slug
  --not-matching-project-rules-for: string # Must not match the rules of the project with this ID or slug
  --observation-accuracy-experiment-id: list # Must included in this observation accuracy experiment
  --fails-dqa-accurate: string@bool-completer # Must be voted as not accurately depicting an organism or scene
  --fails-dqa-date: string@bool-completer # Must be voted as not having an accurate date
  --fails-dqa-evidence: string@bool-completer # Must be voted as not evidence of an organism
  --fails-dqa-location: string@bool-completer # Must be voted as not having an accurate location
  --fails-dqa-needs-id: string@bool-completer # Must be voted as the community ID cannot be improved
  --fails-dqa-recent: string@bool-completer # Must be voted as not recent evidence of an organism
  --fails-dqa-subject: string@bool-completer # Must be voted as not having evidence related to a single subject
  --fails-dqa-wild: string@bool-completer # Must be voted as not wild
  --q: string # Search observation properties. Can be combined with `search_on`
  --search-on: string@search-on-completer # Properties to search on, when combined with `q`. Searches across all properties by default
  --quality-grade: string@quality-grade-completer # Must have this quality grade
  --updated-since: string # Must be updated since this time
  --viewer-id: string # See `reviewed`
  --reviewed: string@bool-completer # Observations have been reviewed by the user with ID equal to the value of the `viewer_id` parameter
  --locale: string # Locale preference for taxon common names
  --preferred-place-id: int # Place preference for regional taxon common names
  --ttl: string # Set the `Cache-Control` HTTP header with this value as `max-age`, in seconds. This means subsequent identical requests will be cached on iNaturalist servers, and commonly within web browsers
  --page: string # Pagination `page` number
  --per-page: string # Number of results to return in a `page`. The maximum value is generally 200 unless otherwise noted
  --order: string@order-completer # Sort order (default: desc)
  --order-by: string@order-by-completer-1 # Sort field (default: created_at)
  --only-id: string@bool-completer # Return only the record IDs
]: nothing -> record<total_results: int, page: int, per_page: int, results: table<annotations: list, id: int, cached_votes_total: int, captive: bool, comments: list, comments_count: int, created_at: string, created_at_details: record, created_time_zone: string, description: string, faves_count: int, geojson: record, geoprivacy: string, taxon_geoprivacy: string, id_please: bool, identifications_count: int, identifications_most_agree: bool, identifications_most_disagree: bool, identifications_some_agree: bool, license_code: string, location: string, private_location: string, mappable: bool, non_owner_ids: list, num_identification_agreements: int, num_identification_disagreements: int, obscured: bool, observed_on: string, observed_on_details: record, observed_on_string: string, observed_time_zone: string, ofvs: list, out_of_range: bool, photos: list, place_guess: string, private_place_guess: string, place_ids: list, private_place_ids: list, positional_accuracy: int, private_geojson: record, project_ids: list, project_ids_with_curator_id: list, project_ids_without_curator_id: list, public_positional_accuracy: int, quality_grade: string, reviewed_by: list, site_id: int, sounds: list, species_guess: string, tags: list, taxon: record, time_observed_at: string, time_zone_offset: string, updated_at: string, uri: string, user: record, uuid: string, verifiable: bool, observation_photos: list, quality_metrics: list, flags: list, community_taxon_id: int, faves: list, identifications: list, oauth_application_id: int, outlinks: list, owners_identification_from_vision: bool, preferences: record, project_observations: list, spam: bool, votes: list, identification_disagreements_count: int, ident_taxon_ids: list, map_scale: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "acc" $acc "scalar") (serialize-qp "captive" $captive "scalar") (serialize-qp "endemic" $endemic "scalar") (serialize-qp "geo" $geo "scalar") (serialize-qp "id_please" $id_please "scalar") (serialize-qp "identified" $identified "scalar") (serialize-qp "introduced" $introduced "scalar") (serialize-qp "mappable" $mappable "scalar") (serialize-qp "native" $native "scalar") (serialize-qp "out_of_range" $out_of_range "scalar") (serialize-qp "pcid" $pcid "scalar") (serialize-qp "photos" $photos "scalar") (serialize-qp "popular" $popular "scalar") (serialize-qp "sounds" $sounds "scalar") (serialize-qp "taxon_is_active" $taxon_is_active "scalar") (serialize-qp "threatened" $threatened "scalar") (serialize-qp "verifiable" $verifiable "scalar") (serialize-qp "licensed" $licensed "scalar") (serialize-qp "photo_licensed" $photo_licensed "scalar") (serialize-qp "expected_nearby" $expected_nearby "scalar") (serialize-qp "id" $id "csv") (serialize-qp "not_id" $not_id "csv") (serialize-qp "license" $license "csv") (serialize-qp "ofv_datatype" $ofv_datatype "csv") (serialize-qp "photo_license" $photo_license "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "project_id" $project_id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "site_id" $site_id "csv") (serialize-qp "sound_license" $sound_license "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "taxon_name" $taxon_name "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "ident_user_id" $ident_user_id "scalar") (serialize-qp "hour" $hour "csv") (serialize-qp "day" $day "csv") (serialize-qp "month" $month "csv") (serialize-qp "year" $year "csv") (serialize-qp "created_day" $created_day "csv") (serialize-qp "created_month" $created_month "csv") (serialize-qp "created_year" $created_year "csv") (serialize-qp "term_id" $term_id "csv") (serialize-qp "term_value_id" $term_value_id "csv") (serialize-qp "without_term_id" $without_term_id "scalar") (serialize-qp "without_term_value_id" $without_term_value_id "csv") (serialize-qp "term_id_or_unknown" $term_id_or_unknown "csv") (serialize-qp "annotation_user_id" $annotation_user_id "csv") (serialize-qp "acc_above" $acc_above "scalar") (serialize-qp "acc_below" $acc_below "scalar") (serialize-qp "acc_below_or_unknown" $acc_below_or_unknown "scalar") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "created_d1" $created_d1 "scalar") (serialize-qp "created_d2" $created_d2 "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "observed_on" $observed_on "scalar") (serialize-qp "unobserved_by_user_id" $unobserved_by_user_id "scalar") (serialize-qp "apply_project_rules_for" $apply_project_rules_for "scalar") (serialize-qp "cs" $cs "scalar") (serialize-qp "csa" $csa "scalar") (serialize-qp "csi" $csi "csv") (serialize-qp "geoprivacy" $geoprivacy "csv") (serialize-qp "taxon_geoprivacy" $taxon_geoprivacy "csv") (serialize-qp "obscuration" $obscuration "csv") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "iconic_taxa" $iconic_taxa "csv") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "identifications" $identifications "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "nelat" $nelat "scalar") (serialize-qp "nelng" $nelng "scalar") (serialize-qp "swlat" $swlat "scalar") (serialize-qp "swlng" $swlng "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "not_in_project" $not_in_project "scalar") (serialize-qp "not_matching_project_rules_for" $not_matching_project_rules_for "scalar") (serialize-qp "observation_accuracy_experiment_id" $observation_accuracy_experiment_id "csv") (serialize-qp "fails_dqa_accurate" $fails_dqa_accurate "scalar") (serialize-qp "fails_dqa_date" $fails_dqa_date "scalar") (serialize-qp "fails_dqa_evidence" $fails_dqa_evidence "scalar") (serialize-qp "fails_dqa_location" $fails_dqa_location "scalar") (serialize-qp "fails_dqa_needs_id" $fails_dqa_needs_id "scalar") (serialize-qp "fails_dqa_recent" $fails_dqa_recent "scalar") (serialize-qp "fails_dqa_subject" $fails_dqa_subject "scalar") (serialize-qp "fails_dqa_wild" $fails_dqa_wild "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "search_on" $search_on "scalar") (serialize-qp "quality_grade" $quality_grade "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "viewer_id" $viewer_id "scalar") (serialize-qp "reviewed" $reviewed "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "preferred_place_id" $preferred_place_id "scalar") (serialize-qp "ttl" $ttl "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "only_id" $only_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/observations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observation Create
#
# POST /observations
# --observation shape: {species_guess?: string, taxon_id?: int, description?: string}
export def "observations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --observation: record # shape: {species_guess?: string, taxon_id?: int, description?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/observations")
  let body = {observation: $observation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Observations Deleted
#
# GET /observations/deleted
export def "observations-deleted get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # Deleted at or after this time (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/observations/deleted" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observation Histogram
#
# GET /observations/histogram
export def "observations-histogram get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --acc: string@bool-completer # Whether or not positional accuracy / coordinate uncertainty has been specified
  --captive: string@bool-completer # Captive or cultivated observations
  --endemic: string@bool-completer # Observations whose taxa are endemic to their location
  --geo: string@bool-completer # Observations that are georeferenced
  --id-please: string@bool-completer # Observations with the deprecated `ID, Please!` flag. Note that this will return observations, but that this attribute is no longer used.
  --identified: string@bool-completer # Observations that have community identifications
  --introduced: string@bool-completer # Observations whose taxa are introduced in their location
  --mappable: string@bool-completer # Observations that show on map tiles
  --native: string@bool-completer # Observations whose taxa are native to their location
  --out-of-range: string@bool-completer # Observations whose taxa are outside their known ranges
  --pcid: string@bool-completer # Observations identified by the curator of a project. If the `project_id` parameter is also specified, this will only consider observations identified by curators of the specified project(s)
  --photos: string@bool-completer # Observations with photos
  --popular: string@bool-completer # Observations that have been favorited by at least one user
  --sounds: string@bool-completer # Observations with sounds
  --taxon-is-active: string@bool-completer # Observations of active taxon concepts
  --threatened: string@bool-completer # Observations whose taxa are threatened in their location
  --verifiable: string@bool-completer # Observations with a `quality_grade` of either `needs_id` or `research`. Equivalent to `quality_grade=needs_id,research`
  --licensed: string@bool-completer # License attribute of an observation must not be null
  --photo-licensed: string@bool-completer # License attribute of at least one photo of an observation must not be null
  --expected-nearby: string@bool-completer # Observation taxon is expected nearby
  --id: list # Must have this ID
  --not-id: list # Must not have this ID
  --license: list@license-completer # Observation must have this license
  --ofv-datatype: list # Must have an observation field value with this datatype
  --photo-license: list@photo-license-completer # Must have at least one photo with this license
  --place-id: list # Must be observed within the place with this ID
  --project-id: list # Must be added to the project this ID or slug
  --rank: list@rank-completer # Taxon must have this rank
  --site-id: list # Must be affiliated with the iNaturalist network website with this ID
  --sound-license: list@sound-license-completer # Must have at least one sound with this license
  --taxon-id: list # Only show observations of these taxa and their descendants
  --without-taxon-id: list # Exclude observations of these taxa and their descendants
  --taxon-name: list # Taxon must have a scientific or common name matching this string
  --user-id: list # User must have this ID or login
  --user-login: list # User must have this login
  --ident-user-id: int # Observations identified by a particular user
  --hour: list # Must be observed within this hour of the day
  --day: list # Must be observed within this day of the month
  --month: list # Must be observed within this month
  --year: list # Must be observed within this year
  --created-day: list # Must be created within this day of the month
  --created-month: list # Must be created within this month
  --created-year: list # Must be created within this year
  --term-id: list # Must have an annotation using this controlled term ID
  --term-value-id: list # Must have an annotation using this controlled value ID. Must be combined with the `term_id` parameter
  --without-term-id: int # Exclude observations with annotations using this controlled value ID.
  --without-term-value-id: list # Exclude observations with annotations using this controlled value ID. Must be combined with the `term_id` parameter
  --term-id-or-unknown: list # Must be combined with the `term_value_id` or the `without_term_value_id` parameter. Must have an annotation using this controlled term ID and associated term value IDs or be missing this annotation.
  --annotation-user-id: list # Must have an annotation created by this user
  --acc-above: string # Must have a positional accuracy above this value (meters)
  --acc-below: string # Must have a positional accuracy below this value (meters)
  --acc-below-or-unknown: string # Positional accuracy must be below this value (in meters) or be unknown
  --d1: string # Must be observed on or after this date (format: date)
  --d2: string # Must be observed on or before this date (format: date)
  --created-d1: string # Must be created at or after this time (format: date-time)
  --created-d2: string # Must be created at or before this time (format: date-time)
  --created-on: string # Must be created on this date (format: date)
  --observed-on: string # Must be observed on this date (format: date)
  --unobserved-by-user-id: int # Must not be of a taxon previously observed by this user
  --apply-project-rules-for: string # Must match the rules of the project with this ID or slug
  --cs: string # Taxon must have this conservation status code. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csa: string # Taxon must have a conservation status from this authority. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csi: list@csi-completer # Taxon must have this IUCN conservation status. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --geoprivacy: list@geoprivacy-completer # Must have this geoprivacy setting
  --taxon-geoprivacy: list@taxon-geoprivacy-completer # Filter observations by the most conservative geoprivacy applied by a conservation status associated with one of the taxa proposed in the current identifications.
  --obscuration: list@obscuration-completer # Must have `geoprivacy` or `taxon_geoprivacy` fields matching these values
  --hrank: string@hrank-completer # Taxon must have this rank or lower
  --lrank: string@lrank-completer # Taxon must have this rank or higher
  --iconic-taxa: list@iconic-taxa-completer # Taxon must by within this iconic taxon
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --identifications: string@identifications-completer # Identifications must meet these criteria
  --lat: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --lng: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --radius: string # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)
  --nelat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --nelng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --list-id: int # Taxon must be in the list with this ID
  --not-in-project: string # Must not be in the project with this ID or slug
  --not-matching-project-rules-for: string # Must not match the rules of the project with this ID or slug
  --observation-accuracy-experiment-id: list # Must included in this observation accuracy experiment
  --fails-dqa-accurate: string@bool-completer # Must be voted as not accurately depicting an organism or scene
  --fails-dqa-date: string@bool-completer # Must be voted as not having an accurate date
  --fails-dqa-evidence: string@bool-completer # Must be voted as not evidence of an organism
  --fails-dqa-location: string@bool-completer # Must be voted as not having an accurate location
  --fails-dqa-needs-id: string@bool-completer # Must be voted as the community ID cannot be improved
  --fails-dqa-recent: string@bool-completer # Must be voted as not recent evidence of an organism
  --fails-dqa-subject: string@bool-completer # Must be voted as not having evidence related to a single subject
  --fails-dqa-wild: string@bool-completer # Must be voted as not wild
  --q: string # Search observation properties. Can be combined with `search_on`
  --search-on: string@search-on-completer # Properties to search on, when combined with `q`. Searches across all properties by default
  --quality-grade: string@quality-grade-completer # Must have this quality grade
  --updated-since: string # Must be updated since this time
  --viewer-id: string # See `reviewed`
  --reviewed: string@bool-completer # Observations have been reviewed by the user with ID equal to the value of the `viewer_id` parameter
  --locale: string # Locale preference for taxon common names
  --preferred-place-id: int # Place preference for regional taxon common names
  --ttl: string # Set the `Cache-Control` HTTP header with this value as `max-age`, in seconds. This means subsequent identical requests will be cached on iNaturalist servers, and commonly within web browsers
  --date-field: string@date-field-completer # Histogram basis: when the observation was created or observed  (default: observed)
  --interval: string@interval-completer # Time interval for histogram, with groups starting on or contained within the group value. The year, month, week, day, and hour options will set default values for `d1` or `created_d1` depending on the value of `date_field`, to limit the number of groups returned. You can override those values if you want data from a longer or shorter time span. The `hour` interval only works with `date_field=created`, and this you should filter dates with `created_d[1,2]`  (default: month_of_year)
]: nothing -> record<code: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "acc" $acc "scalar") (serialize-qp "captive" $captive "scalar") (serialize-qp "endemic" $endemic "scalar") (serialize-qp "geo" $geo "scalar") (serialize-qp "id_please" $id_please "scalar") (serialize-qp "identified" $identified "scalar") (serialize-qp "introduced" $introduced "scalar") (serialize-qp "mappable" $mappable "scalar") (serialize-qp "native" $native "scalar") (serialize-qp "out_of_range" $out_of_range "scalar") (serialize-qp "pcid" $pcid "scalar") (serialize-qp "photos" $photos "scalar") (serialize-qp "popular" $popular "scalar") (serialize-qp "sounds" $sounds "scalar") (serialize-qp "taxon_is_active" $taxon_is_active "scalar") (serialize-qp "threatened" $threatened "scalar") (serialize-qp "verifiable" $verifiable "scalar") (serialize-qp "licensed" $licensed "scalar") (serialize-qp "photo_licensed" $photo_licensed "scalar") (serialize-qp "expected_nearby" $expected_nearby "scalar") (serialize-qp "id" $id "csv") (serialize-qp "not_id" $not_id "csv") (serialize-qp "license" $license "csv") (serialize-qp "ofv_datatype" $ofv_datatype "csv") (serialize-qp "photo_license" $photo_license "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "project_id" $project_id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "site_id" $site_id "csv") (serialize-qp "sound_license" $sound_license "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "taxon_name" $taxon_name "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "ident_user_id" $ident_user_id "scalar") (serialize-qp "hour" $hour "csv") (serialize-qp "day" $day "csv") (serialize-qp "month" $month "csv") (serialize-qp "year" $year "csv") (serialize-qp "created_day" $created_day "csv") (serialize-qp "created_month" $created_month "csv") (serialize-qp "created_year" $created_year "csv") (serialize-qp "term_id" $term_id "csv") (serialize-qp "term_value_id" $term_value_id "csv") (serialize-qp "without_term_id" $without_term_id "scalar") (serialize-qp "without_term_value_id" $without_term_value_id "csv") (serialize-qp "term_id_or_unknown" $term_id_or_unknown "csv") (serialize-qp "annotation_user_id" $annotation_user_id "csv") (serialize-qp "acc_above" $acc_above "scalar") (serialize-qp "acc_below" $acc_below "scalar") (serialize-qp "acc_below_or_unknown" $acc_below_or_unknown "scalar") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "created_d1" $created_d1 "scalar") (serialize-qp "created_d2" $created_d2 "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "observed_on" $observed_on "scalar") (serialize-qp "unobserved_by_user_id" $unobserved_by_user_id "scalar") (serialize-qp "apply_project_rules_for" $apply_project_rules_for "scalar") (serialize-qp "cs" $cs "scalar") (serialize-qp "csa" $csa "scalar") (serialize-qp "csi" $csi "csv") (serialize-qp "geoprivacy" $geoprivacy "csv") (serialize-qp "taxon_geoprivacy" $taxon_geoprivacy "csv") (serialize-qp "obscuration" $obscuration "csv") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "iconic_taxa" $iconic_taxa "csv") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "identifications" $identifications "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "nelat" $nelat "scalar") (serialize-qp "nelng" $nelng "scalar") (serialize-qp "swlat" $swlat "scalar") (serialize-qp "swlng" $swlng "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "not_in_project" $not_in_project "scalar") (serialize-qp "not_matching_project_rules_for" $not_matching_project_rules_for "scalar") (serialize-qp "observation_accuracy_experiment_id" $observation_accuracy_experiment_id "csv") (serialize-qp "fails_dqa_accurate" $fails_dqa_accurate "scalar") (serialize-qp "fails_dqa_date" $fails_dqa_date "scalar") (serialize-qp "fails_dqa_evidence" $fails_dqa_evidence "scalar") (serialize-qp "fails_dqa_location" $fails_dqa_location "scalar") (serialize-qp "fails_dqa_needs_id" $fails_dqa_needs_id "scalar") (serialize-qp "fails_dqa_recent" $fails_dqa_recent "scalar") (serialize-qp "fails_dqa_subject" $fails_dqa_subject "scalar") (serialize-qp "fails_dqa_wild" $fails_dqa_wild "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "search_on" $search_on "scalar") (serialize-qp "quality_grade" $quality_grade "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "viewer_id" $viewer_id "scalar") (serialize-qp "reviewed" $reviewed "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "preferred_place_id" $preferred_place_id "scalar") (serialize-qp "ttl" $ttl "scalar") (serialize-qp "date_field" $date_field "scalar") (serialize-qp "interval" $interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/observations/histogram" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observation Identifiers
#
# GET /observations/identifiers
export def "observations-identifiers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --acc: string@bool-completer # Whether or not positional accuracy / coordinate uncertainty has been specified
  --captive: string@bool-completer # Captive or cultivated observations
  --endemic: string@bool-completer # Observations whose taxa are endemic to their location
  --geo: string@bool-completer # Observations that are georeferenced
  --id-please: string@bool-completer # Observations with the deprecated `ID, Please!` flag. Note that this will return observations, but that this attribute is no longer used.
  --identified: string@bool-completer # Observations that have community identifications
  --introduced: string@bool-completer # Observations whose taxa are introduced in their location
  --mappable: string@bool-completer # Observations that show on map tiles
  --native: string@bool-completer # Observations whose taxa are native to their location
  --out-of-range: string@bool-completer # Observations whose taxa are outside their known ranges
  --pcid: string@bool-completer # Observations identified by the curator of a project. If the `project_id` parameter is also specified, this will only consider observations identified by curators of the specified project(s)
  --photos: string@bool-completer # Observations with photos
  --popular: string@bool-completer # Observations that have been favorited by at least one user
  --sounds: string@bool-completer # Observations with sounds
  --taxon-is-active: string@bool-completer # Observations of active taxon concepts
  --threatened: string@bool-completer # Observations whose taxa are threatened in their location
  --verifiable: string@bool-completer # Observations with a `quality_grade` of either `needs_id` or `research`. Equivalent to `quality_grade=needs_id,research`
  --licensed: string@bool-completer # License attribute of an observation must not be null
  --photo-licensed: string@bool-completer # License attribute of at least one photo of an observation must not be null
  --expected-nearby: string@bool-completer # Observation taxon is expected nearby
  --id: list # Must have this ID
  --not-id: list # Must not have this ID
  --license: list@license-completer # Observation must have this license
  --ofv-datatype: list # Must have an observation field value with this datatype
  --photo-license: list@photo-license-completer # Must have at least one photo with this license
  --place-id: list # Must be observed within the place with this ID
  --project-id: list # Must be added to the project this ID or slug
  --rank: list@rank-completer # Taxon must have this rank
  --site-id: list # Must be affiliated with the iNaturalist network website with this ID
  --sound-license: list@sound-license-completer # Must have at least one sound with this license
  --taxon-id: list # Only show observations of these taxa and their descendants
  --without-taxon-id: list # Exclude observations of these taxa and their descendants
  --taxon-name: list # Taxon must have a scientific or common name matching this string
  --user-id: list # User must have this ID or login
  --user-login: list # User must have this login
  --ident-user-id: int # Observations identified by a particular user
  --hour: list # Must be observed within this hour of the day
  --day: list # Must be observed within this day of the month
  --month: list # Must be observed within this month
  --year: list # Must be observed within this year
  --created-day: list # Must be created within this day of the month
  --created-month: list # Must be created within this month
  --created-year: list # Must be created within this year
  --term-id: list # Must have an annotation using this controlled term ID
  --term-value-id: list # Must have an annotation using this controlled value ID. Must be combined with the `term_id` parameter
  --without-term-id: int # Exclude observations with annotations using this controlled value ID.
  --without-term-value-id: list # Exclude observations with annotations using this controlled value ID. Must be combined with the `term_id` parameter
  --term-id-or-unknown: list # Must be combined with the `term_value_id` or the `without_term_value_id` parameter. Must have an annotation using this controlled term ID and associated term value IDs or be missing this annotation.
  --annotation-user-id: list # Must have an annotation created by this user
  --acc-above: string # Must have a positional accuracy above this value (meters)
  --acc-below: string # Must have a positional accuracy below this value (meters)
  --acc-below-or-unknown: string # Positional accuracy must be below this value (in meters) or be unknown
  --d1: string # Must be observed on or after this date (format: date)
  --d2: string # Must be observed on or before this date (format: date)
  --created-d1: string # Must be created at or after this time (format: date-time)
  --created-d2: string # Must be created at or before this time (format: date-time)
  --created-on: string # Must be created on this date (format: date)
  --observed-on: string # Must be observed on this date (format: date)
  --unobserved-by-user-id: int # Must not be of a taxon previously observed by this user
  --apply-project-rules-for: string # Must match the rules of the project with this ID or slug
  --cs: string # Taxon must have this conservation status code. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csa: string # Taxon must have a conservation status from this authority. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csi: list@csi-completer # Taxon must have this IUCN conservation status. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --geoprivacy: list@geoprivacy-completer # Must have this geoprivacy setting
  --taxon-geoprivacy: list@taxon-geoprivacy-completer # Filter observations by the most conservative geoprivacy applied by a conservation status associated with one of the taxa proposed in the current identifications.
  --obscuration: list@obscuration-completer # Must have `geoprivacy` or `taxon_geoprivacy` fields matching these values
  --hrank: string@hrank-completer # Taxon must have this rank or lower
  --lrank: string@lrank-completer # Taxon must have this rank or higher
  --iconic-taxa: list@iconic-taxa-completer # Taxon must by within this iconic taxon
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --identifications: string@identifications-completer # Identifications must meet these criteria
  --lat: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --lng: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --radius: string # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)
  --nelat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --nelng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --list-id: int # Taxon must be in the list with this ID
  --not-in-project: string # Must not be in the project with this ID or slug
  --not-matching-project-rules-for: string # Must not match the rules of the project with this ID or slug
  --observation-accuracy-experiment-id: list # Must included in this observation accuracy experiment
  --fails-dqa-accurate: string@bool-completer # Must be voted as not accurately depicting an organism or scene
  --fails-dqa-date: string@bool-completer # Must be voted as not having an accurate date
  --fails-dqa-evidence: string@bool-completer # Must be voted as not evidence of an organism
  --fails-dqa-location: string@bool-completer # Must be voted as not having an accurate location
  --fails-dqa-needs-id: string@bool-completer # Must be voted as the community ID cannot be improved
  --fails-dqa-recent: string@bool-completer # Must be voted as not recent evidence of an organism
  --fails-dqa-subject: string@bool-completer # Must be voted as not having evidence related to a single subject
  --fails-dqa-wild: string@bool-completer # Must be voted as not wild
  --q: string # Search observation properties. Can be combined with `search_on`
  --search-on: string@search-on-completer # Properties to search on, when combined with `q`. Searches across all properties by default
  --quality-grade: string@quality-grade-completer # Must have this quality grade
  --updated-since: string # Must be updated since this time
  --viewer-id: string # See `reviewed`
  --reviewed: string@bool-completer # Observations have been reviewed by the user with ID equal to the value of the `viewer_id` parameter
  --locale: string # Locale preference for taxon common names
  --preferred-place-id: int # Place preference for regional taxon common names
  --ttl: string # Set the `Cache-Control` HTTP header with this value as `max-age`, in seconds. This means subsequent identical requests will be cached on iNaturalist servers, and commonly within web browsers
]: nothing -> record<total_results: int, page: int, per_page: int, results: table<count: int, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "acc" $acc "scalar") (serialize-qp "captive" $captive "scalar") (serialize-qp "endemic" $endemic "scalar") (serialize-qp "geo" $geo "scalar") (serialize-qp "id_please" $id_please "scalar") (serialize-qp "identified" $identified "scalar") (serialize-qp "introduced" $introduced "scalar") (serialize-qp "mappable" $mappable "scalar") (serialize-qp "native" $native "scalar") (serialize-qp "out_of_range" $out_of_range "scalar") (serialize-qp "pcid" $pcid "scalar") (serialize-qp "photos" $photos "scalar") (serialize-qp "popular" $popular "scalar") (serialize-qp "sounds" $sounds "scalar") (serialize-qp "taxon_is_active" $taxon_is_active "scalar") (serialize-qp "threatened" $threatened "scalar") (serialize-qp "verifiable" $verifiable "scalar") (serialize-qp "licensed" $licensed "scalar") (serialize-qp "photo_licensed" $photo_licensed "scalar") (serialize-qp "expected_nearby" $expected_nearby "scalar") (serialize-qp "id" $id "csv") (serialize-qp "not_id" $not_id "csv") (serialize-qp "license" $license "csv") (serialize-qp "ofv_datatype" $ofv_datatype "csv") (serialize-qp "photo_license" $photo_license "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "project_id" $project_id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "site_id" $site_id "csv") (serialize-qp "sound_license" $sound_license "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "taxon_name" $taxon_name "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "ident_user_id" $ident_user_id "scalar") (serialize-qp "hour" $hour "csv") (serialize-qp "day" $day "csv") (serialize-qp "month" $month "csv") (serialize-qp "year" $year "csv") (serialize-qp "created_day" $created_day "csv") (serialize-qp "created_month" $created_month "csv") (serialize-qp "created_year" $created_year "csv") (serialize-qp "term_id" $term_id "csv") (serialize-qp "term_value_id" $term_value_id "csv") (serialize-qp "without_term_id" $without_term_id "scalar") (serialize-qp "without_term_value_id" $without_term_value_id "csv") (serialize-qp "term_id_or_unknown" $term_id_or_unknown "csv") (serialize-qp "annotation_user_id" $annotation_user_id "csv") (serialize-qp "acc_above" $acc_above "scalar") (serialize-qp "acc_below" $acc_below "scalar") (serialize-qp "acc_below_or_unknown" $acc_below_or_unknown "scalar") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "created_d1" $created_d1 "scalar") (serialize-qp "created_d2" $created_d2 "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "observed_on" $observed_on "scalar") (serialize-qp "unobserved_by_user_id" $unobserved_by_user_id "scalar") (serialize-qp "apply_project_rules_for" $apply_project_rules_for "scalar") (serialize-qp "cs" $cs "scalar") (serialize-qp "csa" $csa "scalar") (serialize-qp "csi" $csi "csv") (serialize-qp "geoprivacy" $geoprivacy "csv") (serialize-qp "taxon_geoprivacy" $taxon_geoprivacy "csv") (serialize-qp "obscuration" $obscuration "csv") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "iconic_taxa" $iconic_taxa "csv") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "identifications" $identifications "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "nelat" $nelat "scalar") (serialize-qp "nelng" $nelng "scalar") (serialize-qp "swlat" $swlat "scalar") (serialize-qp "swlng" $swlng "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "not_in_project" $not_in_project "scalar") (serialize-qp "not_matching_project_rules_for" $not_matching_project_rules_for "scalar") (serialize-qp "observation_accuracy_experiment_id" $observation_accuracy_experiment_id "csv") (serialize-qp "fails_dqa_accurate" $fails_dqa_accurate "scalar") (serialize-qp "fails_dqa_date" $fails_dqa_date "scalar") (serialize-qp "fails_dqa_evidence" $fails_dqa_evidence "scalar") (serialize-qp "fails_dqa_location" $fails_dqa_location "scalar") (serialize-qp "fails_dqa_needs_id" $fails_dqa_needs_id "scalar") (serialize-qp "fails_dqa_recent" $fails_dqa_recent "scalar") (serialize-qp "fails_dqa_subject" $fails_dqa_subject "scalar") (serialize-qp "fails_dqa_wild" $fails_dqa_wild "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "search_on" $search_on "scalar") (serialize-qp "quality_grade" $quality_grade "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "viewer_id" $viewer_id "scalar") (serialize-qp "reviewed" $reviewed "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "preferred_place_id" $preferred_place_id "scalar") (serialize-qp "ttl" $ttl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/observations/identifiers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observation Observers
#
# GET /observations/observers
export def "observations-observers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --acc: string@bool-completer # Whether or not positional accuracy / coordinate uncertainty has been specified
  --captive: string@bool-completer # Captive or cultivated observations
  --endemic: string@bool-completer # Observations whose taxa are endemic to their location
  --geo: string@bool-completer # Observations that are georeferenced
  --id-please: string@bool-completer # Observations with the deprecated `ID, Please!` flag. Note that this will return observations, but that this attribute is no longer used.
  --identified: string@bool-completer # Observations that have community identifications
  --introduced: string@bool-completer # Observations whose taxa are introduced in their location
  --mappable: string@bool-completer # Observations that show on map tiles
  --native: string@bool-completer # Observations whose taxa are native to their location
  --out-of-range: string@bool-completer # Observations whose taxa are outside their known ranges
  --pcid: string@bool-completer # Observations identified by the curator of a project. If the `project_id` parameter is also specified, this will only consider observations identified by curators of the specified project(s)
  --photos: string@bool-completer # Observations with photos
  --popular: string@bool-completer # Observations that have been favorited by at least one user
  --sounds: string@bool-completer # Observations with sounds
  --taxon-is-active: string@bool-completer # Observations of active taxon concepts
  --threatened: string@bool-completer # Observations whose taxa are threatened in their location
  --verifiable: string@bool-completer # Observations with a `quality_grade` of either `needs_id` or `research`. Equivalent to `quality_grade=needs_id,research`
  --licensed: string@bool-completer # License attribute of an observation must not be null
  --photo-licensed: string@bool-completer # License attribute of at least one photo of an observation must not be null
  --expected-nearby: string@bool-completer # Observation taxon is expected nearby
  --id: list # Must have this ID
  --not-id: list # Must not have this ID
  --license: list@license-completer # Observation must have this license
  --ofv-datatype: list # Must have an observation field value with this datatype
  --photo-license: list@photo-license-completer # Must have at least one photo with this license
  --place-id: list # Must be observed within the place with this ID
  --project-id: list # Must be added to the project this ID or slug
  --rank: list@rank-completer # Taxon must have this rank
  --site-id: list # Must be affiliated with the iNaturalist network website with this ID
  --sound-license: list@sound-license-completer # Must have at least one sound with this license
  --taxon-id: list # Only show observations of these taxa and their descendants
  --without-taxon-id: list # Exclude observations of these taxa and their descendants
  --taxon-name: list # Taxon must have a scientific or common name matching this string
  --user-id: list # User must have this ID or login
  --user-login: list # User must have this login
  --ident-user-id: int # Observations identified by a particular user
  --hour: list # Must be observed within this hour of the day
  --day: list # Must be observed within this day of the month
  --month: list # Must be observed within this month
  --year: list # Must be observed within this year
  --created-day: list # Must be created within this day of the month
  --created-month: list # Must be created within this month
  --created-year: list # Must be created within this year
  --term-id: list # Must have an annotation using this controlled term ID
  --term-value-id: list # Must have an annotation using this controlled value ID. Must be combined with the `term_id` parameter
  --without-term-id: int # Exclude observations with annotations using this controlled value ID.
  --without-term-value-id: list # Exclude observations with annotations using this controlled value ID. Must be combined with the `term_id` parameter
  --term-id-or-unknown: list # Must be combined with the `term_value_id` or the `without_term_value_id` parameter. Must have an annotation using this controlled term ID and associated term value IDs or be missing this annotation.
  --annotation-user-id: list # Must have an annotation created by this user
  --acc-above: string # Must have a positional accuracy above this value (meters)
  --acc-below: string # Must have a positional accuracy below this value (meters)
  --acc-below-or-unknown: string # Positional accuracy must be below this value (in meters) or be unknown
  --d1: string # Must be observed on or after this date (format: date)
  --d2: string # Must be observed on or before this date (format: date)
  --created-d1: string # Must be created at or after this time (format: date-time)
  --created-d2: string # Must be created at or before this time (format: date-time)
  --created-on: string # Must be created on this date (format: date)
  --observed-on: string # Must be observed on this date (format: date)
  --unobserved-by-user-id: int # Must not be of a taxon previously observed by this user
  --apply-project-rules-for: string # Must match the rules of the project with this ID or slug
  --cs: string # Taxon must have this conservation status code. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csa: string # Taxon must have a conservation status from this authority. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csi: list@csi-completer # Taxon must have this IUCN conservation status. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --geoprivacy: list@geoprivacy-completer # Must have this geoprivacy setting
  --taxon-geoprivacy: list@taxon-geoprivacy-completer # Filter observations by the most conservative geoprivacy applied by a conservation status associated with one of the taxa proposed in the current identifications.
  --obscuration: list@obscuration-completer # Must have `geoprivacy` or `taxon_geoprivacy` fields matching these values
  --hrank: string@hrank-completer # Taxon must have this rank or lower
  --lrank: string@lrank-completer # Taxon must have this rank or higher
  --iconic-taxa: list@iconic-taxa-completer # Taxon must by within this iconic taxon
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --identifications: string@identifications-completer # Identifications must meet these criteria
  --lat: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --lng: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --radius: string # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)
  --nelat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --nelng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --list-id: int # Taxon must be in the list with this ID
  --not-in-project: string # Must not be in the project with this ID or slug
  --not-matching-project-rules-for: string # Must not match the rules of the project with this ID or slug
  --observation-accuracy-experiment-id: list # Must included in this observation accuracy experiment
  --fails-dqa-accurate: string@bool-completer # Must be voted as not accurately depicting an organism or scene
  --fails-dqa-date: string@bool-completer # Must be voted as not having an accurate date
  --fails-dqa-evidence: string@bool-completer # Must be voted as not evidence of an organism
  --fails-dqa-location: string@bool-completer # Must be voted as not having an accurate location
  --fails-dqa-needs-id: string@bool-completer # Must be voted as the community ID cannot be improved
  --fails-dqa-recent: string@bool-completer # Must be voted as not recent evidence of an organism
  --fails-dqa-subject: string@bool-completer # Must be voted as not having evidence related to a single subject
  --fails-dqa-wild: string@bool-completer # Must be voted as not wild
  --q: string # Search observation properties. Can be combined with `search_on`
  --search-on: string@search-on-completer # Properties to search on, when combined with `q`. Searches across all properties by default
  --quality-grade: string@quality-grade-completer # Must have this quality grade
  --updated-since: string # Must be updated since this time
  --viewer-id: string # See `reviewed`
  --reviewed: string@bool-completer # Observations have been reviewed by the user with ID equal to the value of the `viewer_id` parameter
  --locale: string # Locale preference for taxon common names
  --preferred-place-id: int # Place preference for regional taxon common names
  --ttl: string # Set the `Cache-Control` HTTP header with this value as `max-age`, in seconds. This means subsequent identical requests will be cached on iNaturalist servers, and commonly within web browsers
]: nothing -> record<total_results: int, page: int, per_page: int, results: table<observation_count: int, species_count: int, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "acc" $acc "scalar") (serialize-qp "captive" $captive "scalar") (serialize-qp "endemic" $endemic "scalar") (serialize-qp "geo" $geo "scalar") (serialize-qp "id_please" $id_please "scalar") (serialize-qp "identified" $identified "scalar") (serialize-qp "introduced" $introduced "scalar") (serialize-qp "mappable" $mappable "scalar") (serialize-qp "native" $native "scalar") (serialize-qp "out_of_range" $out_of_range "scalar") (serialize-qp "pcid" $pcid "scalar") (serialize-qp "photos" $photos "scalar") (serialize-qp "popular" $popular "scalar") (serialize-qp "sounds" $sounds "scalar") (serialize-qp "taxon_is_active" $taxon_is_active "scalar") (serialize-qp "threatened" $threatened "scalar") (serialize-qp "verifiable" $verifiable "scalar") (serialize-qp "licensed" $licensed "scalar") (serialize-qp "photo_licensed" $photo_licensed "scalar") (serialize-qp "expected_nearby" $expected_nearby "scalar") (serialize-qp "id" $id "csv") (serialize-qp "not_id" $not_id "csv") (serialize-qp "license" $license "csv") (serialize-qp "ofv_datatype" $ofv_datatype "csv") (serialize-qp "photo_license" $photo_license "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "project_id" $project_id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "site_id" $site_id "csv") (serialize-qp "sound_license" $sound_license "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "taxon_name" $taxon_name "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "ident_user_id" $ident_user_id "scalar") (serialize-qp "hour" $hour "csv") (serialize-qp "day" $day "csv") (serialize-qp "month" $month "csv") (serialize-qp "year" $year "csv") (serialize-qp "created_day" $created_day "csv") (serialize-qp "created_month" $created_month "csv") (serialize-qp "created_year" $created_year "csv") (serialize-qp "term_id" $term_id "csv") (serialize-qp "term_value_id" $term_value_id "csv") (serialize-qp "without_term_id" $without_term_id "scalar") (serialize-qp "without_term_value_id" $without_term_value_id "csv") (serialize-qp "term_id_or_unknown" $term_id_or_unknown "csv") (serialize-qp "annotation_user_id" $annotation_user_id "csv") (serialize-qp "acc_above" $acc_above "scalar") (serialize-qp "acc_below" $acc_below "scalar") (serialize-qp "acc_below_or_unknown" $acc_below_or_unknown "scalar") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "created_d1" $created_d1 "scalar") (serialize-qp "created_d2" $created_d2 "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "observed_on" $observed_on "scalar") (serialize-qp "unobserved_by_user_id" $unobserved_by_user_id "scalar") (serialize-qp "apply_project_rules_for" $apply_project_rules_for "scalar") (serialize-qp "cs" $cs "scalar") (serialize-qp "csa" $csa "scalar") (serialize-qp "csi" $csi "csv") (serialize-qp "geoprivacy" $geoprivacy "csv") (serialize-qp "taxon_geoprivacy" $taxon_geoprivacy "csv") (serialize-qp "obscuration" $obscuration "csv") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "iconic_taxa" $iconic_taxa "csv") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "identifications" $identifications "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "nelat" $nelat "scalar") (serialize-qp "nelng" $nelng "scalar") (serialize-qp "swlat" $swlat "scalar") (serialize-qp "swlng" $swlng "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "not_in_project" $not_in_project "scalar") (serialize-qp "not_matching_project_rules_for" $not_matching_project_rules_for "scalar") (serialize-qp "observation_accuracy_experiment_id" $observation_accuracy_experiment_id "csv") (serialize-qp "fails_dqa_accurate" $fails_dqa_accurate "scalar") (serialize-qp "fails_dqa_date" $fails_dqa_date "scalar") (serialize-qp "fails_dqa_evidence" $fails_dqa_evidence "scalar") (serialize-qp "fails_dqa_location" $fails_dqa_location "scalar") (serialize-qp "fails_dqa_needs_id" $fails_dqa_needs_id "scalar") (serialize-qp "fails_dqa_recent" $fails_dqa_recent "scalar") (serialize-qp "fails_dqa_subject" $fails_dqa_subject "scalar") (serialize-qp "fails_dqa_wild" $fails_dqa_wild "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "search_on" $search_on "scalar") (serialize-qp "quality_grade" $quality_grade "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "viewer_id" $viewer_id "scalar") (serialize-qp "reviewed" $reviewed "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "preferred_place_id" $preferred_place_id "scalar") (serialize-qp "ttl" $ttl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/observations/observers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observation Popular Field Values
#
# GET /observations/popular_field_values
export def "observations-popular-field-values get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --acc: string@bool-completer # Whether or not positional accuracy / coordinate uncertainty has been specified
  --captive: string@bool-completer # Captive or cultivated observations
  --endemic: string@bool-completer # Observations whose taxa are endemic to their location
  --geo: string@bool-completer # Observations that are georeferenced
  --id-please: string@bool-completer # Observations with the deprecated `ID, Please!` flag. Note that this will return observations, but that this attribute is no longer used.
  --identified: string@bool-completer # Observations that have community identifications
  --introduced: string@bool-completer # Observations whose taxa are introduced in their location
  --mappable: string@bool-completer # Observations that show on map tiles
  --native: string@bool-completer # Observations whose taxa are native to their location
  --out-of-range: string@bool-completer # Observations whose taxa are outside their known ranges
  --pcid: string@bool-completer # Observations identified by the curator of a project. If the `project_id` parameter is also specified, this will only consider observations identified by curators of the specified project(s)
  --photos: string@bool-completer # Observations with photos
  --popular: string@bool-completer # Observations that have been favorited by at least one user
  --sounds: string@bool-completer # Observations with sounds
  --taxon-is-active: string@bool-completer # Observations of active taxon concepts
  --threatened: string@bool-completer # Observations whose taxa are threatened in their location
  --verifiable: string@bool-completer # Observations with a `quality_grade` of either `needs_id` or `research`. Equivalent to `quality_grade=needs_id,research`
  --licensed: string@bool-completer # License attribute of an observation must not be null
  --photo-licensed: string@bool-completer # License attribute of at least one photo of an observation must not be null
  --expected-nearby: string@bool-completer # Observation taxon is expected nearby
  --id: list # Must have this ID
  --not-id: list # Must not have this ID
  --license: list@license-completer # Observation must have this license
  --ofv-datatype: list # Must have an observation field value with this datatype
  --photo-license: list@photo-license-completer # Must have at least one photo with this license
  --place-id: list # Must be observed within the place with this ID
  --project-id: list # Must be added to the project this ID or slug
  --rank: list@rank-completer # Taxon must have this rank
  --site-id: list # Must be affiliated with the iNaturalist network website with this ID
  --sound-license: list@sound-license-completer # Must have at least one sound with this license
  --taxon-id: list # Only show observations of these taxa and their descendants
  --without-taxon-id: list # Exclude observations of these taxa and their descendants
  --taxon-name: list # Taxon must have a scientific or common name matching this string
  --user-id: list # User must have this ID or login
  --user-login: list # User must have this login
  --ident-user-id: int # Observations identified by a particular user
  --hour: list # Must be observed within this hour of the day
  --day: list # Must be observed within this day of the month
  --month: list # Must be observed within this month
  --year: list # Must be observed within this year
  --created-day: list # Must be created within this day of the month
  --created-month: list # Must be created within this month
  --created-year: list # Must be created within this year
  --term-id: list # Must have an annotation using this controlled term ID
  --term-value-id: list # Must have an annotation using this controlled value ID. Must be combined with the `term_id` parameter
  --without-term-id: int # Exclude observations with annotations using this controlled value ID.
  --without-term-value-id: list # Exclude observations with annotations using this controlled value ID. Must be combined with the `term_id` parameter
  --term-id-or-unknown: list # Must be combined with the `term_value_id` or the `without_term_value_id` parameter. Must have an annotation using this controlled term ID and associated term value IDs or be missing this annotation.
  --annotation-user-id: list # Must have an annotation created by this user
  --acc-above: string # Must have a positional accuracy above this value (meters)
  --acc-below: string # Must have a positional accuracy below this value (meters)
  --acc-below-or-unknown: string # Positional accuracy must be below this value (in meters) or be unknown
  --d1: string # Must be observed on or after this date (format: date)
  --d2: string # Must be observed on or before this date (format: date)
  --created-d1: string # Must be created at or after this time (format: date-time)
  --created-d2: string # Must be created at or before this time (format: date-time)
  --created-on: string # Must be created on this date (format: date)
  --observed-on: string # Must be observed on this date (format: date)
  --unobserved-by-user-id: int # Must not be of a taxon previously observed by this user
  --apply-project-rules-for: string # Must match the rules of the project with this ID or slug
  --cs: string # Taxon must have this conservation status code. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csa: string # Taxon must have a conservation status from this authority. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csi: list@csi-completer # Taxon must have this IUCN conservation status. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --geoprivacy: list@geoprivacy-completer # Must have this geoprivacy setting
  --taxon-geoprivacy: list@taxon-geoprivacy-completer # Filter observations by the most conservative geoprivacy applied by a conservation status associated with one of the taxa proposed in the current identifications.
  --obscuration: list@obscuration-completer # Must have `geoprivacy` or `taxon_geoprivacy` fields matching these values
  --hrank: string@hrank-completer # Taxon must have this rank or lower
  --lrank: string@lrank-completer # Taxon must have this rank or higher
  --iconic-taxa: list@iconic-taxa-completer # Taxon must by within this iconic taxon
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --identifications: string@identifications-completer # Identifications must meet these criteria
  --lat: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --lng: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --radius: string # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)
  --nelat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --nelng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --list-id: int # Taxon must be in the list with this ID
  --not-in-project: string # Must not be in the project with this ID or slug
  --not-matching-project-rules-for: string # Must not match the rules of the project with this ID or slug
  --observation-accuracy-experiment-id: list # Must included in this observation accuracy experiment
  --fails-dqa-accurate: string@bool-completer # Must be voted as not accurately depicting an organism or scene
  --fails-dqa-date: string@bool-completer # Must be voted as not having an accurate date
  --fails-dqa-evidence: string@bool-completer # Must be voted as not evidence of an organism
  --fails-dqa-location: string@bool-completer # Must be voted as not having an accurate location
  --fails-dqa-needs-id: string@bool-completer # Must be voted as the community ID cannot be improved
  --fails-dqa-recent: string@bool-completer # Must be voted as not recent evidence of an organism
  --fails-dqa-subject: string@bool-completer # Must be voted as not having evidence related to a single subject
  --fails-dqa-wild: string@bool-completer # Must be voted as not wild
  --q: string # Search observation properties. Can be combined with `search_on`
  --search-on: string@search-on-completer # Properties to search on, when combined with `q`. Searches across all properties by default
  --quality-grade: string@quality-grade-completer # Must have this quality grade
  --updated-since: string # Must be updated since this time
  --viewer-id: string # See `reviewed`
  --reviewed: string@bool-completer # Observations have been reviewed by the user with ID equal to the value of the `viewer_id` parameter
  --locale: string # Locale preference for taxon common names
  --preferred-place-id: int # Place preference for regional taxon common names
  --ttl: string # Set the `Cache-Control` HTTP header with this value as `max-age`, in seconds. This means subsequent identical requests will be cached on iNaturalist servers, and commonly within web browsers
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "acc" $acc "scalar") (serialize-qp "captive" $captive "scalar") (serialize-qp "endemic" $endemic "scalar") (serialize-qp "geo" $geo "scalar") (serialize-qp "id_please" $id_please "scalar") (serialize-qp "identified" $identified "scalar") (serialize-qp "introduced" $introduced "scalar") (serialize-qp "mappable" $mappable "scalar") (serialize-qp "native" $native "scalar") (serialize-qp "out_of_range" $out_of_range "scalar") (serialize-qp "pcid" $pcid "scalar") (serialize-qp "photos" $photos "scalar") (serialize-qp "popular" $popular "scalar") (serialize-qp "sounds" $sounds "scalar") (serialize-qp "taxon_is_active" $taxon_is_active "scalar") (serialize-qp "threatened" $threatened "scalar") (serialize-qp "verifiable" $verifiable "scalar") (serialize-qp "licensed" $licensed "scalar") (serialize-qp "photo_licensed" $photo_licensed "scalar") (serialize-qp "expected_nearby" $expected_nearby "scalar") (serialize-qp "id" $id "csv") (serialize-qp "not_id" $not_id "csv") (serialize-qp "license" $license "csv") (serialize-qp "ofv_datatype" $ofv_datatype "csv") (serialize-qp "photo_license" $photo_license "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "project_id" $project_id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "site_id" $site_id "csv") (serialize-qp "sound_license" $sound_license "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "taxon_name" $taxon_name "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "ident_user_id" $ident_user_id "scalar") (serialize-qp "hour" $hour "csv") (serialize-qp "day" $day "csv") (serialize-qp "month" $month "csv") (serialize-qp "year" $year "csv") (serialize-qp "created_day" $created_day "csv") (serialize-qp "created_month" $created_month "csv") (serialize-qp "created_year" $created_year "csv") (serialize-qp "term_id" $term_id "csv") (serialize-qp "term_value_id" $term_value_id "csv") (serialize-qp "without_term_id" $without_term_id "scalar") (serialize-qp "without_term_value_id" $without_term_value_id "csv") (serialize-qp "term_id_or_unknown" $term_id_or_unknown "csv") (serialize-qp "annotation_user_id" $annotation_user_id "csv") (serialize-qp "acc_above" $acc_above "scalar") (serialize-qp "acc_below" $acc_below "scalar") (serialize-qp "acc_below_or_unknown" $acc_below_or_unknown "scalar") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "created_d1" $created_d1 "scalar") (serialize-qp "created_d2" $created_d2 "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "observed_on" $observed_on "scalar") (serialize-qp "unobserved_by_user_id" $unobserved_by_user_id "scalar") (serialize-qp "apply_project_rules_for" $apply_project_rules_for "scalar") (serialize-qp "cs" $cs "scalar") (serialize-qp "csa" $csa "scalar") (serialize-qp "csi" $csi "csv") (serialize-qp "geoprivacy" $geoprivacy "csv") (serialize-qp "taxon_geoprivacy" $taxon_geoprivacy "csv") (serialize-qp "obscuration" $obscuration "csv") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "iconic_taxa" $iconic_taxa "csv") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "identifications" $identifications "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "nelat" $nelat "scalar") (serialize-qp "nelng" $nelng "scalar") (serialize-qp "swlat" $swlat "scalar") (serialize-qp "swlng" $swlng "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "not_in_project" $not_in_project "scalar") (serialize-qp "not_matching_project_rules_for" $not_matching_project_rules_for "scalar") (serialize-qp "observation_accuracy_experiment_id" $observation_accuracy_experiment_id "csv") (serialize-qp "fails_dqa_accurate" $fails_dqa_accurate "scalar") (serialize-qp "fails_dqa_date" $fails_dqa_date "scalar") (serialize-qp "fails_dqa_evidence" $fails_dqa_evidence "scalar") (serialize-qp "fails_dqa_location" $fails_dqa_location "scalar") (serialize-qp "fails_dqa_needs_id" $fails_dqa_needs_id "scalar") (serialize-qp "fails_dqa_recent" $fails_dqa_recent "scalar") (serialize-qp "fails_dqa_subject" $fails_dqa_subject "scalar") (serialize-qp "fails_dqa_wild" $fails_dqa_wild "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "search_on" $search_on "scalar") (serialize-qp "quality_grade" $quality_grade "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "viewer_id" $viewer_id "scalar") (serialize-qp "reviewed" $reviewed "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "preferred_place_id" $preferred_place_id "scalar") (serialize-qp "ttl" $ttl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/observations/popular_field_values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observation Species Counts
#
# GET /observations/species_counts
export def "observations-species-counts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --acc: string@bool-completer # Whether or not positional accuracy / coordinate uncertainty has been specified
  --captive: string@bool-completer # Captive or cultivated observations
  --endemic: string@bool-completer # Observations whose taxa are endemic to their location
  --geo: string@bool-completer # Observations that are georeferenced
  --id-please: string@bool-completer # Observations with the deprecated `ID, Please!` flag. Note that this will return observations, but that this attribute is no longer used.
  --identified: string@bool-completer # Observations that have community identifications
  --introduced: string@bool-completer # Observations whose taxa are introduced in their location
  --mappable: string@bool-completer # Observations that show on map tiles
  --native: string@bool-completer # Observations whose taxa are native to their location
  --out-of-range: string@bool-completer # Observations whose taxa are outside their known ranges
  --pcid: string@bool-completer # Observations identified by the curator of a project. If the `project_id` parameter is also specified, this will only consider observations identified by curators of the specified project(s)
  --photos: string@bool-completer # Observations with photos
  --popular: string@bool-completer # Observations that have been favorited by at least one user
  --sounds: string@bool-completer # Observations with sounds
  --taxon-is-active: string@bool-completer # Observations of active taxon concepts
  --threatened: string@bool-completer # Observations whose taxa are threatened in their location
  --verifiable: string@bool-completer # Observations with a `quality_grade` of either `needs_id` or `research`. Equivalent to `quality_grade=needs_id,research`
  --licensed: string@bool-completer # License attribute of an observation must not be null
  --photo-licensed: string@bool-completer # License attribute of at least one photo of an observation must not be null
  --expected-nearby: string@bool-completer # Observation taxon is expected nearby
  --id: list # Must have this ID
  --not-id: list # Must not have this ID
  --license: list@license-completer # Observation must have this license
  --ofv-datatype: list # Must have an observation field value with this datatype
  --photo-license: list@photo-license-completer # Must have at least one photo with this license
  --place-id: list # Must be observed within the place with this ID
  --project-id: list # Must be added to the project this ID or slug
  --rank: list@rank-completer # Taxon must have this rank
  --site-id: list # Must be affiliated with the iNaturalist network website with this ID
  --sound-license: list@sound-license-completer # Must have at least one sound with this license
  --taxon-id: list # Only show observations of these taxa and their descendants
  --without-taxon-id: list # Exclude observations of these taxa and their descendants
  --taxon-name: list # Taxon must have a scientific or common name matching this string
  --user-id: list # User must have this ID or login
  --user-login: list # User must have this login
  --ident-user-id: int # Observations identified by a particular user
  --hour: list # Must be observed within this hour of the day
  --day: list # Must be observed within this day of the month
  --month: list # Must be observed within this month
  --year: list # Must be observed within this year
  --created-day: list # Must be created within this day of the month
  --created-month: list # Must be created within this month
  --created-year: list # Must be created within this year
  --term-id: list # Must have an annotation using this controlled term ID
  --term-value-id: list # Must have an annotation using this controlled value ID. Must be combined with the `term_id` parameter
  --without-term-id: int # Exclude observations with annotations using this controlled value ID.
  --without-term-value-id: list # Exclude observations with annotations using this controlled value ID. Must be combined with the `term_id` parameter
  --term-id-or-unknown: list # Must be combined with the `term_value_id` or the `without_term_value_id` parameter. Must have an annotation using this controlled term ID and associated term value IDs or be missing this annotation.
  --annotation-user-id: list # Must have an annotation created by this user
  --acc-above: string # Must have a positional accuracy above this value (meters)
  --acc-below: string # Must have a positional accuracy below this value (meters)
  --acc-below-or-unknown: string # Positional accuracy must be below this value (in meters) or be unknown
  --d1: string # Must be observed on or after this date (format: date)
  --d2: string # Must be observed on or before this date (format: date)
  --created-d1: string # Must be created at or after this time (format: date-time)
  --created-d2: string # Must be created at or before this time (format: date-time)
  --created-on: string # Must be created on this date (format: date)
  --observed-on: string # Must be observed on this date (format: date)
  --unobserved-by-user-id: int # Must not be of a taxon previously observed by this user
  --apply-project-rules-for: string # Must match the rules of the project with this ID or slug
  --cs: string # Taxon must have this conservation status code. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csa: string # Taxon must have a conservation status from this authority. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csi: list@csi-completer # Taxon must have this IUCN conservation status. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --geoprivacy: list@geoprivacy-completer # Must have this geoprivacy setting
  --taxon-geoprivacy: list@taxon-geoprivacy-completer # Filter observations by the most conservative geoprivacy applied by a conservation status associated with one of the taxa proposed in the current identifications.
  --obscuration: list@obscuration-completer # Must have `geoprivacy` or `taxon_geoprivacy` fields matching these values
  --hrank: string@hrank-completer # Taxon must have this rank or lower
  --lrank: string@lrank-completer # Taxon must have this rank or higher
  --iconic-taxa: list@iconic-taxa-completer # Taxon must by within this iconic taxon
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --identifications: string@identifications-completer # Identifications must meet these criteria
  --lat: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --lng: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --radius: string # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)
  --nelat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --nelng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --list-id: int # Taxon must be in the list with this ID
  --not-in-project: string # Must not be in the project with this ID or slug
  --not-matching-project-rules-for: string # Must not match the rules of the project with this ID or slug
  --observation-accuracy-experiment-id: list # Must included in this observation accuracy experiment
  --fails-dqa-accurate: string@bool-completer # Must be voted as not accurately depicting an organism or scene
  --fails-dqa-date: string@bool-completer # Must be voted as not having an accurate date
  --fails-dqa-evidence: string@bool-completer # Must be voted as not evidence of an organism
  --fails-dqa-location: string@bool-completer # Must be voted as not having an accurate location
  --fails-dqa-needs-id: string@bool-completer # Must be voted as the community ID cannot be improved
  --fails-dqa-recent: string@bool-completer # Must be voted as not recent evidence of an organism
  --fails-dqa-subject: string@bool-completer # Must be voted as not having evidence related to a single subject
  --fails-dqa-wild: string@bool-completer # Must be voted as not wild
  --q: string # Search observation properties. Can be combined with `search_on`
  --search-on: string@search-on-completer # Properties to search on, when combined with `q`. Searches across all properties by default
  --quality-grade: string@quality-grade-completer # Must have this quality grade
  --updated-since: string # Must be updated since this time
  --viewer-id: string # See `reviewed`
  --reviewed: string@bool-completer # Observations have been reviewed by the user with ID equal to the value of the `viewer_id` parameter
  --locale: string # Locale preference for taxon common names
  --preferred-place-id: int # Place preference for regional taxon common names
  --ttl: string # Set the `Cache-Control` HTTP header with this value as `max-age`, in seconds. This means subsequent identical requests will be cached on iNaturalist servers, and commonly within web browsers
  --include-ancestors: string@bool-completer # Include taxon ancestors in the response (default: false)
  --page: string # Pagination `page` number
  --per-page: string # Number of results to return in a `page`. The maximum value is 500
]: nothing -> record<total_results: int, page: int, per_page: int, results: table<count: int, taxon: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "acc" $acc "scalar") (serialize-qp "captive" $captive "scalar") (serialize-qp "endemic" $endemic "scalar") (serialize-qp "geo" $geo "scalar") (serialize-qp "id_please" $id_please "scalar") (serialize-qp "identified" $identified "scalar") (serialize-qp "introduced" $introduced "scalar") (serialize-qp "mappable" $mappable "scalar") (serialize-qp "native" $native "scalar") (serialize-qp "out_of_range" $out_of_range "scalar") (serialize-qp "pcid" $pcid "scalar") (serialize-qp "photos" $photos "scalar") (serialize-qp "popular" $popular "scalar") (serialize-qp "sounds" $sounds "scalar") (serialize-qp "taxon_is_active" $taxon_is_active "scalar") (serialize-qp "threatened" $threatened "scalar") (serialize-qp "verifiable" $verifiable "scalar") (serialize-qp "licensed" $licensed "scalar") (serialize-qp "photo_licensed" $photo_licensed "scalar") (serialize-qp "expected_nearby" $expected_nearby "scalar") (serialize-qp "id" $id "csv") (serialize-qp "not_id" $not_id "csv") (serialize-qp "license" $license "csv") (serialize-qp "ofv_datatype" $ofv_datatype "csv") (serialize-qp "photo_license" $photo_license "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "project_id" $project_id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "site_id" $site_id "csv") (serialize-qp "sound_license" $sound_license "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "taxon_name" $taxon_name "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "ident_user_id" $ident_user_id "scalar") (serialize-qp "hour" $hour "csv") (serialize-qp "day" $day "csv") (serialize-qp "month" $month "csv") (serialize-qp "year" $year "csv") (serialize-qp "created_day" $created_day "csv") (serialize-qp "created_month" $created_month "csv") (serialize-qp "created_year" $created_year "csv") (serialize-qp "term_id" $term_id "csv") (serialize-qp "term_value_id" $term_value_id "csv") (serialize-qp "without_term_id" $without_term_id "scalar") (serialize-qp "without_term_value_id" $without_term_value_id "csv") (serialize-qp "term_id_or_unknown" $term_id_or_unknown "csv") (serialize-qp "annotation_user_id" $annotation_user_id "csv") (serialize-qp "acc_above" $acc_above "scalar") (serialize-qp "acc_below" $acc_below "scalar") (serialize-qp "acc_below_or_unknown" $acc_below_or_unknown "scalar") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "created_d1" $created_d1 "scalar") (serialize-qp "created_d2" $created_d2 "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "observed_on" $observed_on "scalar") (serialize-qp "unobserved_by_user_id" $unobserved_by_user_id "scalar") (serialize-qp "apply_project_rules_for" $apply_project_rules_for "scalar") (serialize-qp "cs" $cs "scalar") (serialize-qp "csa" $csa "scalar") (serialize-qp "csi" $csi "csv") (serialize-qp "geoprivacy" $geoprivacy "csv") (serialize-qp "taxon_geoprivacy" $taxon_geoprivacy "csv") (serialize-qp "obscuration" $obscuration "csv") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "iconic_taxa" $iconic_taxa "csv") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "identifications" $identifications "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "nelat" $nelat "scalar") (serialize-qp "nelng" $nelng "scalar") (serialize-qp "swlat" $swlat "scalar") (serialize-qp "swlng" $swlng "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "not_in_project" $not_in_project "scalar") (serialize-qp "not_matching_project_rules_for" $not_matching_project_rules_for "scalar") (serialize-qp "observation_accuracy_experiment_id" $observation_accuracy_experiment_id "csv") (serialize-qp "fails_dqa_accurate" $fails_dqa_accurate "scalar") (serialize-qp "fails_dqa_date" $fails_dqa_date "scalar") (serialize-qp "fails_dqa_evidence" $fails_dqa_evidence "scalar") (serialize-qp "fails_dqa_location" $fails_dqa_location "scalar") (serialize-qp "fails_dqa_needs_id" $fails_dqa_needs_id "scalar") (serialize-qp "fails_dqa_recent" $fails_dqa_recent "scalar") (serialize-qp "fails_dqa_subject" $fails_dqa_subject "scalar") (serialize-qp "fails_dqa_wild" $fails_dqa_wild "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "search_on" $search_on "scalar") (serialize-qp "quality_grade" $quality_grade "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "viewer_id" $viewer_id "scalar") (serialize-qp "reviewed" $reviewed "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "preferred_place_id" $preferred_place_id "scalar") (serialize-qp "ttl" $ttl "scalar") (serialize-qp "include_ancestors" $include_ancestors "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/observations/species_counts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observation User Updates
#
# GET /observations/updates
export def "observations-updates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --created-after: string # Must be created at or after this time (format: date-time)
  --viewed: string@bool-completer # Notification has been viewed by the user before
  --observations-by: string@observations-by-completer # Only show updates on observations owned by the currently authenticated user or on observations the authenticated user is following but does not own.
  --page: string # Pagination `page` number
  --per-page: string # Number of results to return in a `page`. The maximum value is generally 200 unless otherwise noted
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "created_after" $created_after "scalar") (serialize-qp "viewed" $viewed "scalar") (serialize-qp "observations_by" $observations_by "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/observations/updates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observation Field Value Update
#
# PUT /observations/{id}/viewed_updates
export def "observations-viewed-updates put" [
  id: int
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
  let full_url = (build-url $base $"/observations/($id)/viewed_updates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observation Field Value Update
#
# PUT /observation_field_values/{id}
# --observation_field_value shape: {observation_id?: int, observation_field_id?: int, value?: string}
export def "observation-field-values put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --observation-field-value: record # shape: {observation_id?: int, observation_field_id?: int, value?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/observation_field_values/($id)")
  let body = {observation_field_value: $observation_field_value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Observation Field Value Delete
#
# DELETE /observation_field_values/{id}
export def "observation-field-values delete" [
  id: int
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
  let full_url = (build-url $base $"/observation_field_values/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observation Field Value Create
#
# POST /observation_field_values
# --observation_field_value shape: {observation_id?: int, observation_field_id?: int, value?: string}
export def "observation-field-values post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --observation-field-value: record # shape: {observation_id?: int, observation_field_id?: int, value?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/observation_field_values")
  let body = {observation_field_value: $observation_field_value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Observation Photo Update
#
# PUT /observation_photos/{id}
export def "observation-photos put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --observation-photoposition: int # Position in which the photo is displayed for the observation
  --file: path # The photo
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/observation_photos/($id)")
  let body = {observation_photo[position]: $observation_photoposition, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Observation Photo Delete
#
# DELETE /observation_photos/{id}
export def "observation-photos delete" [
  id: int
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
  let full_url = (build-url $base $"/observation_photos/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Observation Photo Create
#
# POST /observation_photos
export def "observation-photos post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --observation-photoobservation-id: int # Observation ID
  --observation-photouuid: string # Observation UUID
  --file: path # The photo
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/observation_photos")
  let body = {observation_photo[observation_id]: $observation_photoobservation_id, observation_photo[uuid]: $observation_photouuid, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Photo Create
#
# POST /photos
export def "photos post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file: path # The photo
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/photos")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Place Details
#
# GET /places/{id}
export def "places get-by-id" [
  id: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --admin-level: list@admin-level-completer # Admin level of a place, or an array of admin levels in comma-delimited format. Supported admin levels are: -10 (continent), 0 (country), 10 (state), 20 (county), 30 (town), 100 (park)
]: nothing -> record<total_results: int, page: int, per_page: int, results: table<id: int, name: string, display_name: string, admin_level: int, ancestor_place_ids: list, bbox_area: float, geometry_geojson: record, location: string, place_type: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "admin_level" $admin_level "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Place Autocomplete
#
# GET /places/autocomplete
export def "places-autocomplete get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Search by name (must start with this value) or by ID (exact match).
  --order-by: string@order-by-completer-2 # Sort field
]: nothing -> record<total_results: int, page: int, per_page: int, results: table<id: int, name: string, display_name: string, admin_level: int, ancestor_place_ids: list, bbox_area: float, geometry_geojson: record, location: string, place_type: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/places/autocomplete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Nearby Places
#
# GET /places/nearby
export def "places-nearby get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nelat: float # Must be nearby this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --nelng: float # Must be nearby this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlat: float # Must be nearby this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlng: float # Must be nearby this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --name: string # Name must match this value
  --per-page: string # Number of results to return in a `page`. The maximum value is generally 200 unless otherwise noted
]: nothing -> record<total_results: int, page: int, per_page: int, results: record<standard: list<record>, community: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nelat" $nelat "scalar") (serialize-qp "nelng" $nelng "scalar") (serialize-qp "swlat" $swlat "scalar") (serialize-qp "swlng" $swlng "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/places/nearby" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Posts Search
#
# GET /posts
export def "posts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --login: string # Return posts by this user
  --project-id: int # Return posts from this project
  --page: string # Pagination `page` number
  --per-page: string # Number of results to return in a `page`. The maximum value is generally 200 unless otherwise noted
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/posts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Post Create
#
# POST /posts
# --post shape: {title?: string, body?: string, preferred_formatting?: string, user_id?: float, parent_id?: float, parent_type?: string}
export def "posts post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --commit: string # e.g. Publish
  --post: record # shape: {title?: string, body?: string, preferred_formatting?: string, user_id?: float, parent_id?: float, parent_type?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/posts")
  let body = {commit: $commit, post: $post} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Post Update
#
# PUT /posts/{id}
# --post shape: {title?: string, body?: string, preferred_formatting?: string, user_id?: float, parent_id?: float, parent_type?: string}
export def "posts put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --commit: string # e.g. Publish
  --post: record # shape: {title?: string, body?: string, preferred_formatting?: string, user_id?: float, parent_id?: float, parent_type?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/posts/($id)")
  let body = {commit: $commit, post: $post} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Post Delete
#
# DELETE /posts/{id}
export def "posts delete" [
  id: int
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
  let full_url = (build-url $base $"/posts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Posts For User
#
# GET /posts/for_user
export def "posts-for-user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --newer-than: int # returns posts newer than the post with this ID
  --older-than: int # returns posts older than the post with this ID
  --page: string # Pagination `page` number
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "newer_than" $newer_than "scalar") (serialize-qp "older_than" $older_than "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/posts/for_user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Project Observation Update
#
# PUT /project_observations/{id}
# --project_observation shape: {project_id?: int, observation_id?: int, prefers_curator_coordinate_access?: bool}
export def "project-observations put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project-observation: record # shape: {project_id?: int, observation_id?: int, prefers_curator_coordinate_access?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/project_observations/($id)")
  let body = {project_observation: $project_observation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Project Observation Delete
#
# DELETE /project_observations/{id}
export def "project-observations delete" [
  id: int
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
  let full_url = (build-url $base $"/project_observations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Project Observation Create
#
# POST /project_observations
export def "project-observations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project-id: int
  --observation-id: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/project_observations")
  let body = {project_id: $project_id, observation_id: $observation_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Project Search
#
# GET /projects
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Search by name (must start with this value) or by ID (exact match).
  --id: list # Must have this ID
  --not-id: list # Must not have this ID
  --lat: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --lng: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --place-id: list # Must be associated with this place
  --radius: string # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius). Defaults to 500km
  --featured: string@featured-completer # Must be marked featured for the relevant site
  --noteworthy: string@noteworthy-completer # Must be marked noteworthy for the relevant site
  --site-id: int # Site ID that applies to `featured` and `noteworthy`. Defaults to the site of the authenticated user, or to the main iNaturalist site https://www.inaturalist.org
  --rule-details: string@rule-details-completer # Return more information about project rules, for example return a full taxon object instead of simply an ID
  --type: list@type-completer # Projects must be of this type
  --member-id: int # Project must have member with this user ID
  --has-params: string@bool-completer # Must have search parameter requirements
  --has-posts: string@bool-completer # Must have posts
  --per-page: string # Number of results to return in a `page`. The maximum value is generally 200 unless otherwise noted
  --order-by: string@order-by-completer-3 # Sort field
]: nothing -> record<total_results: int, page: int, per_page: int, results: table<id: int, title: string, description: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "id" $id "csv") (serialize-qp "not_id" $not_id "csv") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "place_id" $place_id "csv") (serialize-qp "radius" $radius "scalar") (serialize-qp "featured" $featured "scalar") (serialize-qp "noteworthy" $noteworthy "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "rule_details" $rule_details "scalar") (serialize-qp "type" $type "csv") (serialize-qp "member_id" $member_id "scalar") (serialize-qp "has_params" $has_params "scalar") (serialize-qp "has_posts" $has_posts "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Project Details
#
# GET /projects/{id}
export def "projects get" [
  id: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rule-details: string@rule-details-completer # Return more information about project rules, for example return a full taxon object instead of simply an ID
]: nothing -> record<total_results: int, page: int, per_page: int, results: table<id: int, title: string, description: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rule_details" $rule_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Projects Join
#
# POST /projects/{id}/join
export def "projects-join post" [
  id: int
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
  let full_url = (build-url $base $"/projects/($id)/join")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Projects Leave
#
# DELETE /projects/{id}/leave
export def "projects-leave delete" [
  id: int
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
  let full_url = (build-url $base $"/projects/($id)/leave")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Project Members
#
# GET /projects/{id}/members
export def "projects-members get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string@role-completer # Membership role
  --skip-counts: string@bool-completer # If counts are not needed, consider setting this to true to save on processing time, resulting in faster responses  (default: false)
  --page: string # Pagination `page` number
  --per-page: string # Number of results to return in a `page`. The maximum value is generally 200 unless otherwise noted
]: nothing -> record<total_results: int, page: int, per_page: int, results: table<id: int, project_id: int, created_at: string, updated_at: string, role: string, observations_count: int, taxa_count: int, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "skip_counts" $skip_counts "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Membership of current user
#
# GET /projects/{id}/membership
export def "projects-membership get" [
  id: list
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
  let full_url = (build-url $base $"/projects/($id)/membership")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Project Subscriptions
#
# GET /projects/{id}/subscriptions
# DEPRECATED
@deprecated
export def "projects-subscriptions get" [
  id: int
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
  let full_url = (build-url $base $"/projects/($id)/subscriptions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Project Add
#
# POST /projects/{id}/add
export def "projects-add post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --observation-id: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/add")
  let body = {observation_id: $observation_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Project Add
#
# DELETE /projects/{id}/remove
export def "projects-remove delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --observation-id: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/remove")
  let body = {observation_id: $observation_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Project Autocomplete
#
# GET /projects/autocomplete
export def "projects-autocomplete get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Search by name (must start with this value) or by ID (exact match).
  --id: list # Must have this ID
  --not-id: list # Must not have this ID
  --lat: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --lng: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --place-id: list # Must be associated with this place
  --radius: string # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius). Defaults to 500km
  --featured: string@featured-completer # Must be marked featured for the relevant site
  --noteworthy: string@noteworthy-completer # Must be marked noteworthy for the relevant site
  --site-id: int # Site ID that applies to `featured` and `noteworthy`. Defaults to the site of the authenticated user, or to the main iNaturalist site https://www.inaturalist.org
  --rule-details: string@rule-details-completer # Return more information about project rules, for example return a full taxon object instead of simply an ID
  --type: list@type-completer # Projects must be of this type
  --member-id: int # Project must have member with this user ID
  --has-params: string@bool-completer # Must have search parameter requirements
  --has-posts: string@bool-completer # Must have posts
  --per-page: string # Number of results to return in a `page`. The maximum value is generally 200 unless otherwise noted
]: nothing -> record<total_results: int, page: int, per_page: int, results: table<id: int, title: string, description: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "id" $id "csv") (serialize-qp "not_id" $not_id "csv") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "place_id" $place_id "csv") (serialize-qp "radius" $radius "scalar") (serialize-qp "featured" $featured "scalar") (serialize-qp "noteworthy" $noteworthy "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "rule_details" $rule_details "scalar") (serialize-qp "type" $type "csv") (serialize-qp "member_id" $member_id "scalar") (serialize-qp "has_params" $has_params "scalar") (serialize-qp "has_posts" $has_posts "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects/autocomplete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Site Search
#
# GET /search
export def "search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Search object properties
  --sources: list@sources-completer # Must be of this type
  --place-id: list # Must be associated with this place
  --include-taxon-ancestors: string@bool-completer # Include taxon ancestors in the response (default: false)
  --per-page: string # Number of results to return in a `page`. The maximum value is generally 200 unless otherwise noted
  --locale: string # Locale preference for taxon common names
  --preferred-place-id: int # Place preference for regional taxon common names
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sources" $sources "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "include_taxon_ancestors" $include_taxon_ancestors "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "preferred_place_id" $preferred_place_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Project Subscribe
#
# POST /subscriptions/project/{id}/subscribe
export def "subscriptions-project-subscribe post" [
  id: int
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
  let full_url = (build-url $base $"/subscriptions/project/($id)/subscribe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Taxon Details
#
# GET /taxa/{id}
export def "taxa get" [
  id: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rank-level: float # Taxon must have this rank level. Some example values are 70 (kingdom), 60 (phylum), 50 (class), 40 (order), 30 (family), 20 (genus), 10 (species), 5 (subspecies)
]: nothing -> record<total_results: int, page: int, per_page: int, results: table<id: int, iconic_taxon_id: int, iconic_taxon_name: string, is_active: bool, name: string, preferred_common_name: string, rank: string, rank_level: float, ancestor_ids: list, colors: list, conservation_status: record, conservation_statuses: list, default_photo: record, establishment_means: record, observations_count: int, preferred_establishment_means: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rank_level" $rank_level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/taxa/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Taxon Search
#
# GET /taxa
export def "taxa list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Search by name (must start with this value) or by ID (exact match).
  --is-active: string@bool-completer # Taxon is `active`
  --id: list # Comma-separated list of taxon IDs
  --parent-id: int # Taxon's parent must have this ID
  --rank: list@rank-completer # Taxon must have this rank
  --rank-level: float # Taxon must have this rank level. Some example values are 70 (kingdom), 60 (phylum), 50 (class), 40 (order), 30 (family), 20 (genus), 10 (species), 5 (subspecies)
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --per-page: string # Number of results to return in a `page`. The maximum value is generally 200 unless otherwise noted
  --locale: string # Locale preference for taxon common names
  --preferred-place-id: int # Place preference for regional taxon common names
  --only-id: string@bool-completer # Return only the record IDs
  --all-names: string@bool-completer # Include all taxon names in the response
  --order: string@order-completer # Sort order (default: desc)
  --order-by: string@order-by-completer-4 # Sort field (default: observations_count)
]: nothing -> record<total_results: int, page: int, per_page: int, results: table<id: int, iconic_taxon_id: int, iconic_taxon_name: string, is_active: bool, name: string, preferred_common_name: string, rank: string, rank_level: float, ancestor_ids: list, colors: list, conservation_status: record, conservation_statuses: list, default_photo: record, establishment_means: record, observations_count: int, preferred_establishment_means: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "is_active" $is_active "scalar") (serialize-qp "id" $id "csv") (serialize-qp "parent_id" $parent_id "scalar") (serialize-qp "rank" $rank "csv") (serialize-qp "rank_level" $rank_level "scalar") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "preferred_place_id" $preferred_place_id "scalar") (serialize-qp "only_id" $only_id "scalar") (serialize-qp "all_names" $all_names "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/taxa" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Taxon Autocomplete
#
# GET /taxa/autocomplete
export def "taxa-autocomplete get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Search by name (must start with this value) or by ID (exact match).
  --is-active: string@bool-completer # Taxon is `active`
  --taxon-id: list # Only show taxa with this ID, or its descendants
  --rank: list@rank-completer # Taxon must have this rank
  --rank-level: float # Taxon must have this rank level. Some example values are 70 (kingdom), 60 (phylum), 50 (class), 40 (order), 30 (family), 20 (genus), 10 (species), 5 (subspecies)
  --per-page: string # Number of results to return in a `page`. The maximum value is 30 for this endpoint
  --locale: string # Locale preference for taxon common names
  --preferred-place-id: int # Place preference for regional taxon common names
  --all-names: string@bool-completer # Include all taxon names in the response
]: nothing -> record<total_results: int, page: int, per_page: int, results: table<id: int, iconic_taxon_id: int, iconic_taxon_name: string, is_active: bool, name: string, preferred_common_name: string, rank: string, rank_level: float, default_photo: record, matched_term: string, observations_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "is_active" $is_active "scalar") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "rank_level" $rank_level "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "preferred_place_id" $preferred_place_id "scalar") (serialize-qp "all_names" $all_names "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/taxa/autocomplete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# User Details
#
# GET /users/{id}
export def "users get" [
  id: int
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
  let full_url = (build-url $base $"/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# User Update
#
# PUT /users/{id}
export def "users put" [
  id: int
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
  let full_url = (build-url $base $"/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# User Projects
#
# GET /users/{id}/projects
export def "users-projects get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rule-details: string@rule-details-completer # Return more information about project rules, for example return a full taxon object instead of simply an ID
  --project-type: string@project-type-completer # Specify the type of project to return
  --page: string # Pagination `page` number
  --per-page: string # Number of results to return in a `page`. The maximum value is generally 200 unless otherwise noted
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rule_details" $rule_details "scalar") (serialize-qp "project_type" $project_type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# User Autocomplete
#
# GET /users/autocomplete
export def "users-autocomplete get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Search by name (must start with this value) or by ID (exact match).
  --project-id: int # Only show users with memberships to this project
  --per-page: string # Number of results to return in a `page`. The maximum value is generally 200 unless otherwise noted
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/autocomplete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Users Me
#
# GET /users/me
export def "users-me get" [
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
  let full_url = (build-url $base "/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mute a User
#
# POST /users/{id}/mute
export def "users-mute post" [
  id: int
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
  let full_url = (build-url $base $"/users/($id)/mute")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unmute a User
#
# DELETE /users/{id}/mute
export def "users-mute delete" [
  id: int
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
  let full_url = (build-url $base $"/users/($id)/mute")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# User Resend Confirmation
#
# POST /users/resend_confirmation
export def "users-resend-confirmation post" [
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
  let full_url = (build-url $base "/users/resend_confirmation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# User Update Session
#
# PUT /users/update_session
export def "users-update-session put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --preferred-taxon-page-ancestors-shown: string@bool-completer
  --preferred-taxon-page-place-id: int
  --preferred-taxon-page-tab: string
  --prefers-skip-coarer-id-modal: string@bool-completer
  --prefers-hide-obs-show-annotations: string@bool-completer
  --prefers-hide-obs-show-projects: string@bool-completer
  --prefers-hide-obs-show-tags: string@bool-completer
  --prefers-hide-obs-show-observation-fields: string@bool-completer
  --prefers-hide-obs-show-identifiers: string@bool-completer
  --prefers-hide-obs-show-copyright: string@bool-completer
  --prefers-hide-obs-show-quality-metrics: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/update_session")
  let body = {preferred_taxon_page_ancestors_shown: $preferred_taxon_page_ancestors_shown, preferred_taxon_page_place_id: $preferred_taxon_page_place_id, preferred_taxon_page_tab: $preferred_taxon_page_tab, prefers_skip_coarer_id_modal: $prefers_skip_coarer_id_modal, prefers_hide_obs_show_annotations: $prefers_hide_obs_show_annotations, prefers_hide_obs_show_projects: $prefers_hide_obs_show_projects, prefers_hide_obs_show_tags: $prefers_hide_obs_show_tags, prefers_hide_obs_show_observation_fields: $prefers_hide_obs_show_observation_fields, prefers_hide_obs_show_identifiers: $prefers_hide_obs_show_identifiers, prefers_hide_obs_show_copyright: $prefers_hide_obs_show_copyright, prefers_hide_obs_show_quality_metrics: $prefers_hide_obs_show_quality_metrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Colored Heatmap Tiles
#
# GET /colored_heatmap/{zoom}/{x}/{y}.png
export def "colored-heatmap get-by-zoom-x-y" [
  zoom: int
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --color: string # Primary color to use in tile creation. Accepts common colors by string (e.g. `color=blue`), and accepts escaped color HEX codes (e.g. `color=%2386a91c`)
  --acc: string@bool-completer # Whether or not positional accuracy / coordinate uncertainty has been specified
  --captive: string@bool-completer # Captive or cultivated observations
  --endemic: string@bool-completer # Observations whose taxa are endemic to their location
  --geo: string@bool-completer # Observations that are georeferenced
  --id-please: string@bool-completer # Observations with the deprecated `ID, Please!` flag. Note that this will return observations, but that this attribute is no longer used.
  --identified: string@bool-completer # Observations that have community identifications
  --introduced: string@bool-completer # Observations whose taxa are introduced in their location
  --mappable: string@bool-completer # Observations that show on map tiles
  --native: string@bool-completer # Observations whose taxa are native to their location
  --out-of-range: string@bool-completer # Observations whose taxa are outside their known ranges
  --pcid: string@bool-completer # Observations identified by the curator of a project. If the `project_id` parameter is also specified, this will only consider observations identified by curators of the specified project(s)
  --photos: string@bool-completer # Observations with photos
  --popular: string@bool-completer # Observations that have been favorited by at least one user
  --sounds: string@bool-completer # Observations with sounds
  --taxon-is-active: string@bool-completer # Observations of active taxon concepts
  --threatened: string@bool-completer # Observations whose taxa are threatened in their location
  --verifiable: string@bool-completer # Observations with a `quality_grade` of either `needs_id` or `research`. Equivalent to `quality_grade=needs_id,research`
  --licensed: string@bool-completer # License attribute of an observation must not be null
  --photo-licensed: string@bool-completer # License attribute of at least one photo of an observation must not be null
  --expected-nearby: string@bool-completer # Observation taxon is expected nearby
  --id: list # Must have this ID
  --not-id: list # Must not have this ID
  --license: list@license-completer # Observation must have this license
  --ofv-datatype: list # Must have an observation field value with this datatype
  --photo-license: list@photo-license-completer # Must have at least one photo with this license
  --place-id: list # Must be observed within the place with this ID
  --project-id: list # Must be added to the project this ID or slug
  --rank: list@rank-completer # Taxon must have this rank
  --site-id: list # Must be affiliated with the iNaturalist network website with this ID
  --sound-license: list@sound-license-completer # Must have at least one sound with this license
  --taxon-id: list # Only show observations of these taxa and their descendants
  --without-taxon-id: list # Exclude observations of these taxa and their descendants
  --taxon-name: list # Taxon must have a scientific or common name matching this string
  --user-id: list # User must have this ID or login
  --user-login: list # User must have this login
  --ident-user-id: int # Observations identified by a particular user
  --hour: list # Must be observed within this hour of the day
  --day: list # Must be observed within this day of the month
  --month: list # Must be observed within this month
  --year: list # Must be observed within this year
  --created-day: list # Must be created within this day of the month
  --created-month: list # Must be created within this month
  --created-year: list # Must be created within this year
  --term-id: list # Must have an annotation using this controlled term ID
  --term-value-id: list # Must have an annotation using this controlled value ID. Must be combined with the `term_id` parameter
  --without-term-id: int # Exclude observations with annotations using this controlled value ID.
  --without-term-value-id: list # Exclude observations with annotations using this controlled value ID. Must be combined with the `term_id` parameter
  --term-id-or-unknown: list # Must be combined with the `term_value_id` or the `without_term_value_id` parameter. Must have an annotation using this controlled term ID and associated term value IDs or be missing this annotation.
  --annotation-user-id: list # Must have an annotation created by this user
  --acc-above: string # Must have a positional accuracy above this value (meters)
  --acc-below: string # Must have a positional accuracy below this value (meters)
  --acc-below-or-unknown: string # Positional accuracy must be below this value (in meters) or be unknown
  --d1: string # Must be observed on or after this date (format: date)
  --d2: string # Must be observed on or before this date (format: date)
  --created-d1: string # Must be created at or after this time (format: date-time)
  --created-d2: string # Must be created at or before this time (format: date-time)
  --created-on: string # Must be created on this date (format: date)
  --observed-on: string # Must be observed on this date (format: date)
  --unobserved-by-user-id: int # Must not be of a taxon previously observed by this user
  --apply-project-rules-for: string # Must match the rules of the project with this ID or slug
  --cs: string # Taxon must have this conservation status code. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csa: string # Taxon must have a conservation status from this authority. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csi: list@csi-completer # Taxon must have this IUCN conservation status. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --geoprivacy: list@geoprivacy-completer # Must have this geoprivacy setting
  --taxon-geoprivacy: list@taxon-geoprivacy-completer # Filter observations by the most conservative geoprivacy applied by a conservation status associated with one of the taxa proposed in the current identifications.
  --obscuration: list@obscuration-completer # Must have `geoprivacy` or `taxon_geoprivacy` fields matching these values
  --hrank: string@hrank-completer # Taxon must have this rank or lower
  --lrank: string@lrank-completer # Taxon must have this rank or higher
  --iconic-taxa: list@iconic-taxa-completer # Taxon must by within this iconic taxon
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --identifications: string@identifications-completer # Identifications must meet these criteria
  --lat: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --lng: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --radius: string # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)
  --nelat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --nelng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --list-id: int # Taxon must be in the list with this ID
  --not-in-project: string # Must not be in the project with this ID or slug
  --not-matching-project-rules-for: string # Must not match the rules of the project with this ID or slug
  --observation-accuracy-experiment-id: list # Must included in this observation accuracy experiment
  --fails-dqa-accurate: string@bool-completer # Must be voted as not accurately depicting an organism or scene
  --fails-dqa-date: string@bool-completer # Must be voted as not having an accurate date
  --fails-dqa-evidence: string@bool-completer # Must be voted as not evidence of an organism
  --fails-dqa-location: string@bool-completer # Must be voted as not having an accurate location
  --fails-dqa-needs-id: string@bool-completer # Must be voted as the community ID cannot be improved
  --fails-dqa-recent: string@bool-completer # Must be voted as not recent evidence of an organism
  --fails-dqa-subject: string@bool-completer # Must be voted as not having evidence related to a single subject
  --fails-dqa-wild: string@bool-completer # Must be voted as not wild
  --q: string # Search observation properties. Can be combined with `search_on`
  --search-on: string@search-on-completer # Properties to search on, when combined with `q`. Searches across all properties by default
  --quality-grade: string@quality-grade-completer # Must have this quality grade
  --updated-since: string # Must be updated since this time
  --viewer-id: string # See `reviewed`
  --reviewed: string@bool-completer # Observations have been reviewed by the user with ID equal to the value of the `viewer_id` parameter
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "color" $color "scalar") (serialize-qp "acc" $acc "scalar") (serialize-qp "captive" $captive "scalar") (serialize-qp "endemic" $endemic "scalar") (serialize-qp "geo" $geo "scalar") (serialize-qp "id_please" $id_please "scalar") (serialize-qp "identified" $identified "scalar") (serialize-qp "introduced" $introduced "scalar") (serialize-qp "mappable" $mappable "scalar") (serialize-qp "native" $native "scalar") (serialize-qp "out_of_range" $out_of_range "scalar") (serialize-qp "pcid" $pcid "scalar") (serialize-qp "photos" $photos "scalar") (serialize-qp "popular" $popular "scalar") (serialize-qp "sounds" $sounds "scalar") (serialize-qp "taxon_is_active" $taxon_is_active "scalar") (serialize-qp "threatened" $threatened "scalar") (serialize-qp "verifiable" $verifiable "scalar") (serialize-qp "licensed" $licensed "scalar") (serialize-qp "photo_licensed" $photo_licensed "scalar") (serialize-qp "expected_nearby" $expected_nearby "scalar") (serialize-qp "id" $id "csv") (serialize-qp "not_id" $not_id "csv") (serialize-qp "license" $license "csv") (serialize-qp "ofv_datatype" $ofv_datatype "csv") (serialize-qp "photo_license" $photo_license "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "project_id" $project_id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "site_id" $site_id "csv") (serialize-qp "sound_license" $sound_license "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "taxon_name" $taxon_name "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "ident_user_id" $ident_user_id "scalar") (serialize-qp "hour" $hour "csv") (serialize-qp "day" $day "csv") (serialize-qp "month" $month "csv") (serialize-qp "year" $year "csv") (serialize-qp "created_day" $created_day "csv") (serialize-qp "created_month" $created_month "csv") (serialize-qp "created_year" $created_year "csv") (serialize-qp "term_id" $term_id "csv") (serialize-qp "term_value_id" $term_value_id "csv") (serialize-qp "without_term_id" $without_term_id "scalar") (serialize-qp "without_term_value_id" $without_term_value_id "csv") (serialize-qp "term_id_or_unknown" $term_id_or_unknown "csv") (serialize-qp "annotation_user_id" $annotation_user_id "csv") (serialize-qp "acc_above" $acc_above "scalar") (serialize-qp "acc_below" $acc_below "scalar") (serialize-qp "acc_below_or_unknown" $acc_below_or_unknown "scalar") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "created_d1" $created_d1 "scalar") (serialize-qp "created_d2" $created_d2 "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "observed_on" $observed_on "scalar") (serialize-qp "unobserved_by_user_id" $unobserved_by_user_id "scalar") (serialize-qp "apply_project_rules_for" $apply_project_rules_for "scalar") (serialize-qp "cs" $cs "scalar") (serialize-qp "csa" $csa "scalar") (serialize-qp "csi" $csi "csv") (serialize-qp "geoprivacy" $geoprivacy "csv") (serialize-qp "taxon_geoprivacy" $taxon_geoprivacy "csv") (serialize-qp "obscuration" $obscuration "csv") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "iconic_taxa" $iconic_taxa "csv") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "identifications" $identifications "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "nelat" $nelat "scalar") (serialize-qp "nelng" $nelng "scalar") (serialize-qp "swlat" $swlat "scalar") (serialize-qp "swlng" $swlng "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "not_in_project" $not_in_project "scalar") (serialize-qp "not_matching_project_rules_for" $not_matching_project_rules_for "scalar") (serialize-qp "observation_accuracy_experiment_id" $observation_accuracy_experiment_id "csv") (serialize-qp "fails_dqa_accurate" $fails_dqa_accurate "scalar") (serialize-qp "fails_dqa_date" $fails_dqa_date "scalar") (serialize-qp "fails_dqa_evidence" $fails_dqa_evidence "scalar") (serialize-qp "fails_dqa_location" $fails_dqa_location "scalar") (serialize-qp "fails_dqa_needs_id" $fails_dqa_needs_id "scalar") (serialize-qp "fails_dqa_recent" $fails_dqa_recent "scalar") (serialize-qp "fails_dqa_subject" $fails_dqa_subject "scalar") (serialize-qp "fails_dqa_wild" $fails_dqa_wild "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "search_on" $search_on "scalar") (serialize-qp "quality_grade" $quality_grade "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "viewer_id" $viewer_id "scalar") (serialize-qp "reviewed" $reviewed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/colored_heatmap/($zoom)/($x)/($y).png" $qp)
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Colored Heatmap Tiles UTFGrid
#
# GET /colored_heatmap/{zoom}/{x}/{y}.grid.json
export def "colored-heatmap get-by-zoom-x-y-1" [
  zoom: int
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --color: string # Primary color to use in tile creation. Accepts common colors by string (e.g. `color=blue`), and accepts escaped color HEX codes (e.g. `color=%2386a91c`)
  --acc: string@bool-completer # Whether or not positional accuracy / coordinate uncertainty has been specified
  --captive: string@bool-completer # Captive or cultivated observations
  --endemic: string@bool-completer # Observations whose taxa are endemic to their location
  --geo: string@bool-completer # Observations that are georeferenced
  --id-please: string@bool-completer # Observations with the deprecated `ID, Please!` flag. Note that this will return observations, but that this attribute is no longer used.
  --identified: string@bool-completer # Observations that have community identifications
  --introduced: string@bool-completer # Observations whose taxa are introduced in their location
  --mappable: string@bool-completer # Observations that show on map tiles
  --native: string@bool-completer # Observations whose taxa are native to their location
  --out-of-range: string@bool-completer # Observations whose taxa are outside their known ranges
  --pcid: string@bool-completer # Observations identified by the curator of a project. If the `project_id` parameter is also specified, this will only consider observations identified by curators of the specified project(s)
  --photos: string@bool-completer # Observations with photos
  --popular: string@bool-completer # Observations that have been favorited by at least one user
  --sounds: string@bool-completer # Observations with sounds
  --taxon-is-active: string@bool-completer # Observations of active taxon concepts
  --threatened: string@bool-completer # Observations whose taxa are threatened in their location
  --verifiable: string@bool-completer # Observations with a `quality_grade` of either `needs_id` or `research`. Equivalent to `quality_grade=needs_id,research`
  --licensed: string@bool-completer # License attribute of an observation must not be null
  --photo-licensed: string@bool-completer # License attribute of at least one photo of an observation must not be null
  --expected-nearby: string@bool-completer # Observation taxon is expected nearby
  --id: list # Must have this ID
  --not-id: list # Must not have this ID
  --license: list@license-completer # Observation must have this license
  --ofv-datatype: list # Must have an observation field value with this datatype
  --photo-license: list@photo-license-completer # Must have at least one photo with this license
  --place-id: list # Must be observed within the place with this ID
  --project-id: list # Must be added to the project this ID or slug
  --rank: list@rank-completer # Taxon must have this rank
  --site-id: list # Must be affiliated with the iNaturalist network website with this ID
  --sound-license: list@sound-license-completer # Must have at least one sound with this license
  --taxon-id: list # Only show observations of these taxa and their descendants
  --without-taxon-id: list # Exclude observations of these taxa and their descendants
  --taxon-name: list # Taxon must have a scientific or common name matching this string
  --user-id: list # User must have this ID or login
  --user-login: list # User must have this login
  --ident-user-id: int # Observations identified by a particular user
  --hour: list # Must be observed within this hour of the day
  --day: list # Must be observed within this day of the month
  --month: list # Must be observed within this month
  --year: list # Must be observed within this year
  --created-day: list # Must be created within this day of the month
  --created-month: list # Must be created within this month
  --created-year: list # Must be created within this year
  --term-id: list # Must have an annotation using this controlled term ID
  --term-value-id: list # Must have an annotation using this controlled value ID. Must be combined with the `term_id` parameter
  --without-term-id: int # Exclude observations with annotations using this controlled value ID.
  --without-term-value-id: list # Exclude observations with annotations using this controlled value ID. Must be combined with the `term_id` parameter
  --term-id-or-unknown: list # Must be combined with the `term_value_id` or the `without_term_value_id` parameter. Must have an annotation using this controlled term ID and associated term value IDs or be missing this annotation.
  --annotation-user-id: list # Must have an annotation created by this user
  --acc-above: string # Must have a positional accuracy above this value (meters)
  --acc-below: string # Must have a positional accuracy below this value (meters)
  --acc-below-or-unknown: string # Positional accuracy must be below this value (in meters) or be unknown
  --d1: string # Must be observed on or after this date (format: date)
  --d2: string # Must be observed on or before this date (format: date)
  --created-d1: string # Must be created at or after this time (format: date-time)
  --created-d2: string # Must be created at or before this time (format: date-time)
  --created-on: string # Must be created on this date (format: date)
  --observed-on: string # Must be observed on this date (format: date)
  --unobserved-by-user-id: int # Must not be of a taxon previously observed by this user
  --apply-project-rules-for: string # Must match the rules of the project with this ID or slug
  --cs: string # Taxon must have this conservation status code. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csa: string # Taxon must have a conservation status from this authority. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csi: list@csi-completer # Taxon must have this IUCN conservation status. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --geoprivacy: list@geoprivacy-completer # Must have this geoprivacy setting
  --taxon-geoprivacy: list@taxon-geoprivacy-completer # Filter observations by the most conservative geoprivacy applied by a conservation status associated with one of the taxa proposed in the current identifications.
  --obscuration: list@obscuration-completer # Must have `geoprivacy` or `taxon_geoprivacy` fields matching these values
  --hrank: string@hrank-completer # Taxon must have this rank or lower
  --lrank: string@lrank-completer # Taxon must have this rank or higher
  --iconic-taxa: list@iconic-taxa-completer # Taxon must by within this iconic taxon
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --identifications: string@identifications-completer # Identifications must meet these criteria
  --lat: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --lng: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --radius: string # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)
  --nelat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --nelng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --list-id: int # Taxon must be in the list with this ID
  --not-in-project: string # Must not be in the project with this ID or slug
  --not-matching-project-rules-for: string # Must not match the rules of the project with this ID or slug
  --observation-accuracy-experiment-id: list # Must included in this observation accuracy experiment
  --fails-dqa-accurate: string@bool-completer # Must be voted as not accurately depicting an organism or scene
  --fails-dqa-date: string@bool-completer # Must be voted as not having an accurate date
  --fails-dqa-evidence: string@bool-completer # Must be voted as not evidence of an organism
  --fails-dqa-location: string@bool-completer # Must be voted as not having an accurate location
  --fails-dqa-needs-id: string@bool-completer # Must be voted as the community ID cannot be improved
  --fails-dqa-recent: string@bool-completer # Must be voted as not recent evidence of an organism
  --fails-dqa-subject: string@bool-completer # Must be voted as not having evidence related to a single subject
  --fails-dqa-wild: string@bool-completer # Must be voted as not wild
  --q: string # Search observation properties. Can be combined with `search_on`
  --search-on: string@search-on-completer # Properties to search on, when combined with `q`. Searches across all properties by default
  --quality-grade: string@quality-grade-completer # Must have this quality grade
  --updated-since: string # Must be updated since this time
  --viewer-id: string # See `reviewed`
  --reviewed: string@bool-completer # Observations have been reviewed by the user with ID equal to the value of the `viewer_id` parameter
]: nothing -> record<grid: list<string>, keys: list<string>, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "color" $color "scalar") (serialize-qp "acc" $acc "scalar") (serialize-qp "captive" $captive "scalar") (serialize-qp "endemic" $endemic "scalar") (serialize-qp "geo" $geo "scalar") (serialize-qp "id_please" $id_please "scalar") (serialize-qp "identified" $identified "scalar") (serialize-qp "introduced" $introduced "scalar") (serialize-qp "mappable" $mappable "scalar") (serialize-qp "native" $native "scalar") (serialize-qp "out_of_range" $out_of_range "scalar") (serialize-qp "pcid" $pcid "scalar") (serialize-qp "photos" $photos "scalar") (serialize-qp "popular" $popular "scalar") (serialize-qp "sounds" $sounds "scalar") (serialize-qp "taxon_is_active" $taxon_is_active "scalar") (serialize-qp "threatened" $threatened "scalar") (serialize-qp "verifiable" $verifiable "scalar") (serialize-qp "licensed" $licensed "scalar") (serialize-qp "photo_licensed" $photo_licensed "scalar") (serialize-qp "expected_nearby" $expected_nearby "scalar") (serialize-qp "id" $id "csv") (serialize-qp "not_id" $not_id "csv") (serialize-qp "license" $license "csv") (serialize-qp "ofv_datatype" $ofv_datatype "csv") (serialize-qp "photo_license" $photo_license "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "project_id" $project_id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "site_id" $site_id "csv") (serialize-qp "sound_license" $sound_license "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "taxon_name" $taxon_name "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "ident_user_id" $ident_user_id "scalar") (serialize-qp "hour" $hour "csv") (serialize-qp "day" $day "csv") (serialize-qp "month" $month "csv") (serialize-qp "year" $year "csv") (serialize-qp "created_day" $created_day "csv") (serialize-qp "created_month" $created_month "csv") (serialize-qp "created_year" $created_year "csv") (serialize-qp "term_id" $term_id "csv") (serialize-qp "term_value_id" $term_value_id "csv") (serialize-qp "without_term_id" $without_term_id "scalar") (serialize-qp "without_term_value_id" $without_term_value_id "csv") (serialize-qp "term_id_or_unknown" $term_id_or_unknown "csv") (serialize-qp "annotation_user_id" $annotation_user_id "csv") (serialize-qp "acc_above" $acc_above "scalar") (serialize-qp "acc_below" $acc_below "scalar") (serialize-qp "acc_below_or_unknown" $acc_below_or_unknown "scalar") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "created_d1" $created_d1 "scalar") (serialize-qp "created_d2" $created_d2 "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "observed_on" $observed_on "scalar") (serialize-qp "unobserved_by_user_id" $unobserved_by_user_id "scalar") (serialize-qp "apply_project_rules_for" $apply_project_rules_for "scalar") (serialize-qp "cs" $cs "scalar") (serialize-qp "csa" $csa "scalar") (serialize-qp "csi" $csi "csv") (serialize-qp "geoprivacy" $geoprivacy "csv") (serialize-qp "taxon_geoprivacy" $taxon_geoprivacy "csv") (serialize-qp "obscuration" $obscuration "csv") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "iconic_taxa" $iconic_taxa "csv") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "identifications" $identifications "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "nelat" $nelat "scalar") (serialize-qp "nelng" $nelng "scalar") (serialize-qp "swlat" $swlat "scalar") (serialize-qp "swlng" $swlng "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "not_in_project" $not_in_project "scalar") (serialize-qp "not_matching_project_rules_for" $not_matching_project_rules_for "scalar") (serialize-qp "observation_accuracy_experiment_id" $observation_accuracy_experiment_id "csv") (serialize-qp "fails_dqa_accurate" $fails_dqa_accurate "scalar") (serialize-qp "fails_dqa_date" $fails_dqa_date "scalar") (serialize-qp "fails_dqa_evidence" $fails_dqa_evidence "scalar") (serialize-qp "fails_dqa_location" $fails_dqa_location "scalar") (serialize-qp "fails_dqa_needs_id" $fails_dqa_needs_id "scalar") (serialize-qp "fails_dqa_recent" $fails_dqa_recent "scalar") (serialize-qp "fails_dqa_subject" $fails_dqa_subject "scalar") (serialize-qp "fails_dqa_wild" $fails_dqa_wild "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "search_on" $search_on "scalar") (serialize-qp "quality_grade" $quality_grade "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "viewer_id" $viewer_id "scalar") (serialize-qp "reviewed" $reviewed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/colored_heatmap/($zoom)/($x)/($y).grid.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Grid Tiles
#
# GET /grid/{zoom}/{x}/{y}.png
export def "grid get-by-zoom-x-y" [
  zoom: int
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --color: string # Primary color to use in tile creation. Accepts common colors by string (e.g. `color=blue`), and accepts escaped color HEX codes (e.g. `color=%2386a91c`)
  --acc: string@bool-completer # Whether or not positional accuracy / coordinate uncertainty has been specified
  --captive: string@bool-completer # Captive or cultivated observations
  --endemic: string@bool-completer # Observations whose taxa are endemic to their location
  --geo: string@bool-completer # Observations that are georeferenced
  --id-please: string@bool-completer # Observations with the deprecated `ID, Please!` flag. Note that this will return observations, but that this attribute is no longer used.
  --identified: string@bool-completer # Observations that have community identifications
  --introduced: string@bool-completer # Observations whose taxa are introduced in their location
  --mappable: string@bool-completer # Observations that show on map tiles
  --native: string@bool-completer # Observations whose taxa are native to their location
  --out-of-range: string@bool-completer # Observations whose taxa are outside their known ranges
  --pcid: string@bool-completer # Observations identified by the curator of a project. If the `project_id` parameter is also specified, this will only consider observations identified by curators of the specified project(s)
  --photos: string@bool-completer # Observations with photos
  --popular: string@bool-completer # Observations that have been favorited by at least one user
  --sounds: string@bool-completer # Observations with sounds
  --taxon-is-active: string@bool-completer # Observations of active taxon concepts
  --threatened: string@bool-completer # Observations whose taxa are threatened in their location
  --verifiable: string@bool-completer # Observations with a `quality_grade` of either `needs_id` or `research`. Equivalent to `quality_grade=needs_id,research`
  --licensed: string@bool-completer # License attribute of an observation must not be null
  --photo-licensed: string@bool-completer # License attribute of at least one photo of an observation must not be null
  --expected-nearby: string@bool-completer # Observation taxon is expected nearby
  --id: list # Must have this ID
  --not-id: list # Must not have this ID
  --license: list@license-completer # Observation must have this license
  --ofv-datatype: list # Must have an observation field value with this datatype
  --photo-license: list@photo-license-completer # Must have at least one photo with this license
  --place-id: list # Must be observed within the place with this ID
  --project-id: list # Must be added to the project this ID or slug
  --rank: list@rank-completer # Taxon must have this rank
  --site-id: list # Must be affiliated with the iNaturalist network website with this ID
  --sound-license: list@sound-license-completer # Must have at least one sound with this license
  --taxon-id: list # Only show observations of these taxa and their descendants
  --without-taxon-id: list # Exclude observations of these taxa and their descendants
  --taxon-name: list # Taxon must have a scientific or common name matching this string
  --user-id: list # User must have this ID or login
  --user-login: list # User must have this login
  --ident-user-id: int # Observations identified by a particular user
  --hour: list # Must be observed within this hour of the day
  --day: list # Must be observed within this day of the month
  --month: list # Must be observed within this month
  --year: list # Must be observed within this year
  --created-day: list # Must be created within this day of the month
  --created-month: list # Must be created within this month
  --created-year: list # Must be created within this year
  --term-id: list # Must have an annotation using this controlled term ID
  --term-value-id: list # Must have an annotation using this controlled value ID. Must be combined with the `term_id` parameter
  --without-term-id: int # Exclude observations with annotations using this controlled value ID.
  --without-term-value-id: list # Exclude observations with annotations using this controlled value ID. Must be combined with the `term_id` parameter
  --term-id-or-unknown: list # Must be combined with the `term_value_id` or the `without_term_value_id` parameter. Must have an annotation using this controlled term ID and associated term value IDs or be missing this annotation.
  --annotation-user-id: list # Must have an annotation created by this user
  --acc-above: string # Must have a positional accuracy above this value (meters)
  --acc-below: string # Must have a positional accuracy below this value (meters)
  --acc-below-or-unknown: string # Positional accuracy must be below this value (in meters) or be unknown
  --d1: string # Must be observed on or after this date (format: date)
  --d2: string # Must be observed on or before this date (format: date)
  --created-d1: string # Must be created at or after this time (format: date-time)
  --created-d2: string # Must be created at or before this time (format: date-time)
  --created-on: string # Must be created on this date (format: date)
  --observed-on: string # Must be observed on this date (format: date)
  --unobserved-by-user-id: int # Must not be of a taxon previously observed by this user
  --apply-project-rules-for: string # Must match the rules of the project with this ID or slug
  --cs: string # Taxon must have this conservation status code. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csa: string # Taxon must have a conservation status from this authority. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csi: list@csi-completer # Taxon must have this IUCN conservation status. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --geoprivacy: list@geoprivacy-completer # Must have this geoprivacy setting
  --taxon-geoprivacy: list@taxon-geoprivacy-completer # Filter observations by the most conservative geoprivacy applied by a conservation status associated with one of the taxa proposed in the current identifications.
  --obscuration: list@obscuration-completer # Must have `geoprivacy` or `taxon_geoprivacy` fields matching these values
  --hrank: string@hrank-completer # Taxon must have this rank or lower
  --lrank: string@lrank-completer # Taxon must have this rank or higher
  --iconic-taxa: list@iconic-taxa-completer # Taxon must by within this iconic taxon
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --identifications: string@identifications-completer # Identifications must meet these criteria
  --lat: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --lng: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --radius: string # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)
  --nelat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --nelng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --list-id: int # Taxon must be in the list with this ID
  --not-in-project: string # Must not be in the project with this ID or slug
  --not-matching-project-rules-for: string # Must not match the rules of the project with this ID or slug
  --observation-accuracy-experiment-id: list # Must included in this observation accuracy experiment
  --fails-dqa-accurate: string@bool-completer # Must be voted as not accurately depicting an organism or scene
  --fails-dqa-date: string@bool-completer # Must be voted as not having an accurate date
  --fails-dqa-evidence: string@bool-completer # Must be voted as not evidence of an organism
  --fails-dqa-location: string@bool-completer # Must be voted as not having an accurate location
  --fails-dqa-needs-id: string@bool-completer # Must be voted as the community ID cannot be improved
  --fails-dqa-recent: string@bool-completer # Must be voted as not recent evidence of an organism
  --fails-dqa-subject: string@bool-completer # Must be voted as not having evidence related to a single subject
  --fails-dqa-wild: string@bool-completer # Must be voted as not wild
  --q: string # Search observation properties. Can be combined with `search_on`
  --search-on: string@search-on-completer # Properties to search on, when combined with `q`. Searches across all properties by default
  --quality-grade: string@quality-grade-completer # Must have this quality grade
  --updated-since: string # Must be updated since this time
  --viewer-id: string # See `reviewed`
  --reviewed: string@bool-completer # Observations have been reviewed by the user with ID equal to the value of the `viewer_id` parameter
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "color" $color "scalar") (serialize-qp "acc" $acc "scalar") (serialize-qp "captive" $captive "scalar") (serialize-qp "endemic" $endemic "scalar") (serialize-qp "geo" $geo "scalar") (serialize-qp "id_please" $id_please "scalar") (serialize-qp "identified" $identified "scalar") (serialize-qp "introduced" $introduced "scalar") (serialize-qp "mappable" $mappable "scalar") (serialize-qp "native" $native "scalar") (serialize-qp "out_of_range" $out_of_range "scalar") (serialize-qp "pcid" $pcid "scalar") (serialize-qp "photos" $photos "scalar") (serialize-qp "popular" $popular "scalar") (serialize-qp "sounds" $sounds "scalar") (serialize-qp "taxon_is_active" $taxon_is_active "scalar") (serialize-qp "threatened" $threatened "scalar") (serialize-qp "verifiable" $verifiable "scalar") (serialize-qp "licensed" $licensed "scalar") (serialize-qp "photo_licensed" $photo_licensed "scalar") (serialize-qp "expected_nearby" $expected_nearby "scalar") (serialize-qp "id" $id "csv") (serialize-qp "not_id" $not_id "csv") (serialize-qp "license" $license "csv") (serialize-qp "ofv_datatype" $ofv_datatype "csv") (serialize-qp "photo_license" $photo_license "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "project_id" $project_id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "site_id" $site_id "csv") (serialize-qp "sound_license" $sound_license "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "taxon_name" $taxon_name "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "ident_user_id" $ident_user_id "scalar") (serialize-qp "hour" $hour "csv") (serialize-qp "day" $day "csv") (serialize-qp "month" $month "csv") (serialize-qp "year" $year "csv") (serialize-qp "created_day" $created_day "csv") (serialize-qp "created_month" $created_month "csv") (serialize-qp "created_year" $created_year "csv") (serialize-qp "term_id" $term_id "csv") (serialize-qp "term_value_id" $term_value_id "csv") (serialize-qp "without_term_id" $without_term_id "scalar") (serialize-qp "without_term_value_id" $without_term_value_id "csv") (serialize-qp "term_id_or_unknown" $term_id_or_unknown "csv") (serialize-qp "annotation_user_id" $annotation_user_id "csv") (serialize-qp "acc_above" $acc_above "scalar") (serialize-qp "acc_below" $acc_below "scalar") (serialize-qp "acc_below_or_unknown" $acc_below_or_unknown "scalar") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "created_d1" $created_d1 "scalar") (serialize-qp "created_d2" $created_d2 "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "observed_on" $observed_on "scalar") (serialize-qp "unobserved_by_user_id" $unobserved_by_user_id "scalar") (serialize-qp "apply_project_rules_for" $apply_project_rules_for "scalar") (serialize-qp "cs" $cs "scalar") (serialize-qp "csa" $csa "scalar") (serialize-qp "csi" $csi "csv") (serialize-qp "geoprivacy" $geoprivacy "csv") (serialize-qp "taxon_geoprivacy" $taxon_geoprivacy "csv") (serialize-qp "obscuration" $obscuration "csv") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "iconic_taxa" $iconic_taxa "csv") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "identifications" $identifications "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "nelat" $nelat "scalar") (serialize-qp "nelng" $nelng "scalar") (serialize-qp "swlat" $swlat "scalar") (serialize-qp "swlng" $swlng "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "not_in_project" $not_in_project "scalar") (serialize-qp "not_matching_project_rules_for" $not_matching_project_rules_for "scalar") (serialize-qp "observation_accuracy_experiment_id" $observation_accuracy_experiment_id "csv") (serialize-qp "fails_dqa_accurate" $fails_dqa_accurate "scalar") (serialize-qp "fails_dqa_date" $fails_dqa_date "scalar") (serialize-qp "fails_dqa_evidence" $fails_dqa_evidence "scalar") (serialize-qp "fails_dqa_location" $fails_dqa_location "scalar") (serialize-qp "fails_dqa_needs_id" $fails_dqa_needs_id "scalar") (serialize-qp "fails_dqa_recent" $fails_dqa_recent "scalar") (serialize-qp "fails_dqa_subject" $fails_dqa_subject "scalar") (serialize-qp "fails_dqa_wild" $fails_dqa_wild "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "search_on" $search_on "scalar") (serialize-qp "quality_grade" $quality_grade "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "viewer_id" $viewer_id "scalar") (serialize-qp "reviewed" $reviewed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/grid/($zoom)/($x)/($y).png" $qp)
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Grid Tiles UTFGrid
#
# GET /grid/{zoom}/{x}/{y}.grid.json
export def "grid get-by-zoom-x-y-1" [
  zoom: int
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --color: string # Primary color to use in tile creation. Accepts common colors by string (e.g. `color=blue`), and accepts escaped color HEX codes (e.g. `color=%2386a91c`)
  --acc: string@bool-completer # Whether or not positional accuracy / coordinate uncertainty has been specified
  --captive: string@bool-completer # Captive or cultivated observations
  --endemic: string@bool-completer # Observations whose taxa are endemic to their location
  --geo: string@bool-completer # Observations that are georeferenced
  --id-please: string@bool-completer # Observations with the deprecated `ID, Please!` flag. Note that this will return observations, but that this attribute is no longer used.
  --identified: string@bool-completer # Observations that have community identifications
  --introduced: string@bool-completer # Observations whose taxa are introduced in their location
  --mappable: string@bool-completer # Observations that show on map tiles
  --native: string@bool-completer # Observations whose taxa are native to their location
  --out-of-range: string@bool-completer # Observations whose taxa are outside their known ranges
  --pcid: string@bool-completer # Observations identified by the curator of a project. If the `project_id` parameter is also specified, this will only consider observations identified by curators of the specified project(s)
  --photos: string@bool-completer # Observations with photos
  --popular: string@bool-completer # Observations that have been favorited by at least one user
  --sounds: string@bool-completer # Observations with sounds
  --taxon-is-active: string@bool-completer # Observations of active taxon concepts
  --threatened: string@bool-completer # Observations whose taxa are threatened in their location
  --verifiable: string@bool-completer # Observations with a `quality_grade` of either `needs_id` or `research`. Equivalent to `quality_grade=needs_id,research`
  --licensed: string@bool-completer # License attribute of an observation must not be null
  --photo-licensed: string@bool-completer # License attribute of at least one photo of an observation must not be null
  --expected-nearby: string@bool-completer # Observation taxon is expected nearby
  --id: list # Must have this ID
  --not-id: list # Must not have this ID
  --license: list@license-completer # Observation must have this license
  --ofv-datatype: list # Must have an observation field value with this datatype
  --photo-license: list@photo-license-completer # Must have at least one photo with this license
  --place-id: list # Must be observed within the place with this ID
  --project-id: list # Must be added to the project this ID or slug
  --rank: list@rank-completer # Taxon must have this rank
  --site-id: list # Must be affiliated with the iNaturalist network website with this ID
  --sound-license: list@sound-license-completer # Must have at least one sound with this license
  --taxon-id: list # Only show observations of these taxa and their descendants
  --without-taxon-id: list # Exclude observations of these taxa and their descendants
  --taxon-name: list # Taxon must have a scientific or common name matching this string
  --user-id: list # User must have this ID or login
  --user-login: list # User must have this login
  --ident-user-id: int # Observations identified by a particular user
  --hour: list # Must be observed within this hour of the day
  --day: list # Must be observed within this day of the month
  --month: list # Must be observed within this month
  --year: list # Must be observed within this year
  --created-day: list # Must be created within this day of the month
  --created-month: list # Must be created within this month
  --created-year: list # Must be created within this year
  --term-id: list # Must have an annotation using this controlled term ID
  --term-value-id: list # Must have an annotation using this controlled value ID. Must be combined with the `term_id` parameter
  --without-term-id: int # Exclude observations with annotations using this controlled value ID.
  --without-term-value-id: list # Exclude observations with annotations using this controlled value ID. Must be combined with the `term_id` parameter
  --term-id-or-unknown: list # Must be combined with the `term_value_id` or the `without_term_value_id` parameter. Must have an annotation using this controlled term ID and associated term value IDs or be missing this annotation.
  --annotation-user-id: list # Must have an annotation created by this user
  --acc-above: string # Must have a positional accuracy above this value (meters)
  --acc-below: string # Must have a positional accuracy below this value (meters)
  --acc-below-or-unknown: string # Positional accuracy must be below this value (in meters) or be unknown
  --d1: string # Must be observed on or after this date (format: date)
  --d2: string # Must be observed on or before this date (format: date)
  --created-d1: string # Must be created at or after this time (format: date-time)
  --created-d2: string # Must be created at or before this time (format: date-time)
  --created-on: string # Must be created on this date (format: date)
  --observed-on: string # Must be observed on this date (format: date)
  --unobserved-by-user-id: int # Must not be of a taxon previously observed by this user
  --apply-project-rules-for: string # Must match the rules of the project with this ID or slug
  --cs: string # Taxon must have this conservation status code. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csa: string # Taxon must have a conservation status from this authority. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csi: list@csi-completer # Taxon must have this IUCN conservation status. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --geoprivacy: list@geoprivacy-completer # Must have this geoprivacy setting
  --taxon-geoprivacy: list@taxon-geoprivacy-completer # Filter observations by the most conservative geoprivacy applied by a conservation status associated with one of the taxa proposed in the current identifications.
  --obscuration: list@obscuration-completer # Must have `geoprivacy` or `taxon_geoprivacy` fields matching these values
  --hrank: string@hrank-completer # Taxon must have this rank or lower
  --lrank: string@lrank-completer # Taxon must have this rank or higher
  --iconic-taxa: list@iconic-taxa-completer # Taxon must by within this iconic taxon
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --identifications: string@identifications-completer # Identifications must meet these criteria
  --lat: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --lng: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --radius: string # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)
  --nelat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --nelng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --list-id: int # Taxon must be in the list with this ID
  --not-in-project: string # Must not be in the project with this ID or slug
  --not-matching-project-rules-for: string # Must not match the rules of the project with this ID or slug
  --observation-accuracy-experiment-id: list # Must included in this observation accuracy experiment
  --fails-dqa-accurate: string@bool-completer # Must be voted as not accurately depicting an organism or scene
  --fails-dqa-date: string@bool-completer # Must be voted as not having an accurate date
  --fails-dqa-evidence: string@bool-completer # Must be voted as not evidence of an organism
  --fails-dqa-location: string@bool-completer # Must be voted as not having an accurate location
  --fails-dqa-needs-id: string@bool-completer # Must be voted as the community ID cannot be improved
  --fails-dqa-recent: string@bool-completer # Must be voted as not recent evidence of an organism
  --fails-dqa-subject: string@bool-completer # Must be voted as not having evidence related to a single subject
  --fails-dqa-wild: string@bool-completer # Must be voted as not wild
  --q: string # Search observation properties. Can be combined with `search_on`
  --search-on: string@search-on-completer # Properties to search on, when combined with `q`. Searches across all properties by default
  --quality-grade: string@quality-grade-completer # Must have this quality grade
  --updated-since: string # Must be updated since this time
  --viewer-id: string # See `reviewed`
  --reviewed: string@bool-completer # Observations have been reviewed by the user with ID equal to the value of the `viewer_id` parameter
]: nothing -> record<grid: list<string>, keys: list<string>, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "color" $color "scalar") (serialize-qp "acc" $acc "scalar") (serialize-qp "captive" $captive "scalar") (serialize-qp "endemic" $endemic "scalar") (serialize-qp "geo" $geo "scalar") (serialize-qp "id_please" $id_please "scalar") (serialize-qp "identified" $identified "scalar") (serialize-qp "introduced" $introduced "scalar") (serialize-qp "mappable" $mappable "scalar") (serialize-qp "native" $native "scalar") (serialize-qp "out_of_range" $out_of_range "scalar") (serialize-qp "pcid" $pcid "scalar") (serialize-qp "photos" $photos "scalar") (serialize-qp "popular" $popular "scalar") (serialize-qp "sounds" $sounds "scalar") (serialize-qp "taxon_is_active" $taxon_is_active "scalar") (serialize-qp "threatened" $threatened "scalar") (serialize-qp "verifiable" $verifiable "scalar") (serialize-qp "licensed" $licensed "scalar") (serialize-qp "photo_licensed" $photo_licensed "scalar") (serialize-qp "expected_nearby" $expected_nearby "scalar") (serialize-qp "id" $id "csv") (serialize-qp "not_id" $not_id "csv") (serialize-qp "license" $license "csv") (serialize-qp "ofv_datatype" $ofv_datatype "csv") (serialize-qp "photo_license" $photo_license "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "project_id" $project_id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "site_id" $site_id "csv") (serialize-qp "sound_license" $sound_license "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "taxon_name" $taxon_name "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "ident_user_id" $ident_user_id "scalar") (serialize-qp "hour" $hour "csv") (serialize-qp "day" $day "csv") (serialize-qp "month" $month "csv") (serialize-qp "year" $year "csv") (serialize-qp "created_day" $created_day "csv") (serialize-qp "created_month" $created_month "csv") (serialize-qp "created_year" $created_year "csv") (serialize-qp "term_id" $term_id "csv") (serialize-qp "term_value_id" $term_value_id "csv") (serialize-qp "without_term_id" $without_term_id "scalar") (serialize-qp "without_term_value_id" $without_term_value_id "csv") (serialize-qp "term_id_or_unknown" $term_id_or_unknown "csv") (serialize-qp "annotation_user_id" $annotation_user_id "csv") (serialize-qp "acc_above" $acc_above "scalar") (serialize-qp "acc_below" $acc_below "scalar") (serialize-qp "acc_below_or_unknown" $acc_below_or_unknown "scalar") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "created_d1" $created_d1 "scalar") (serialize-qp "created_d2" $created_d2 "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "observed_on" $observed_on "scalar") (serialize-qp "unobserved_by_user_id" $unobserved_by_user_id "scalar") (serialize-qp "apply_project_rules_for" $apply_project_rules_for "scalar") (serialize-qp "cs" $cs "scalar") (serialize-qp "csa" $csa "scalar") (serialize-qp "csi" $csi "csv") (serialize-qp "geoprivacy" $geoprivacy "csv") (serialize-qp "taxon_geoprivacy" $taxon_geoprivacy "csv") (serialize-qp "obscuration" $obscuration "csv") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "iconic_taxa" $iconic_taxa "csv") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "identifications" $identifications "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "nelat" $nelat "scalar") (serialize-qp "nelng" $nelng "scalar") (serialize-qp "swlat" $swlat "scalar") (serialize-qp "swlng" $swlng "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "not_in_project" $not_in_project "scalar") (serialize-qp "not_matching_project_rules_for" $not_matching_project_rules_for "scalar") (serialize-qp "observation_accuracy_experiment_id" $observation_accuracy_experiment_id "csv") (serialize-qp "fails_dqa_accurate" $fails_dqa_accurate "scalar") (serialize-qp "fails_dqa_date" $fails_dqa_date "scalar") (serialize-qp "fails_dqa_evidence" $fails_dqa_evidence "scalar") (serialize-qp "fails_dqa_location" $fails_dqa_location "scalar") (serialize-qp "fails_dqa_needs_id" $fails_dqa_needs_id "scalar") (serialize-qp "fails_dqa_recent" $fails_dqa_recent "scalar") (serialize-qp "fails_dqa_subject" $fails_dqa_subject "scalar") (serialize-qp "fails_dqa_wild" $fails_dqa_wild "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "search_on" $search_on "scalar") (serialize-qp "quality_grade" $quality_grade "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "viewer_id" $viewer_id "scalar") (serialize-qp "reviewed" $reviewed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/grid/($zoom)/($x)/($y).grid.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Heatmap Tiles
#
# GET /heatmap/{zoom}/{x}/{y}.png
export def "heatmap get-by-zoom-x-y" [
  zoom: int
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --color: string # Primary color to use in tile creation. Accepts common colors by string (e.g. `color=blue`), and accepts escaped color HEX codes (e.g. `color=%2386a91c`)
  --acc: string@bool-completer # Whether or not positional accuracy / coordinate uncertainty has been specified
  --captive: string@bool-completer # Captive or cultivated observations
  --endemic: string@bool-completer # Observations whose taxa are endemic to their location
  --geo: string@bool-completer # Observations that are georeferenced
  --id-please: string@bool-completer # Observations with the deprecated `ID, Please!` flag. Note that this will return observations, but that this attribute is no longer used.
  --identified: string@bool-completer # Observations that have community identifications
  --introduced: string@bool-completer # Observations whose taxa are introduced in their location
  --mappable: string@bool-completer # Observations that show on map tiles
  --native: string@bool-completer # Observations whose taxa are native to their location
  --out-of-range: string@bool-completer # Observations whose taxa are outside their known ranges
  --pcid: string@bool-completer # Observations identified by the curator of a project. If the `project_id` parameter is also specified, this will only consider observations identified by curators of the specified project(s)
  --photos: string@bool-completer # Observations with photos
  --popular: string@bool-completer # Observations that have been favorited by at least one user
  --sounds: string@bool-completer # Observations with sounds
  --taxon-is-active: string@bool-completer # Observations of active taxon concepts
  --threatened: string@bool-completer # Observations whose taxa are threatened in their location
  --verifiable: string@bool-completer # Observations with a `quality_grade` of either `needs_id` or `research`. Equivalent to `quality_grade=needs_id,research`
  --licensed: string@bool-completer # License attribute of an observation must not be null
  --photo-licensed: string@bool-completer # License attribute of at least one photo of an observation must not be null
  --expected-nearby: string@bool-completer # Observation taxon is expected nearby
  --id: list # Must have this ID
  --not-id: list # Must not have this ID
  --license: list@license-completer # Observation must have this license
  --ofv-datatype: list # Must have an observation field value with this datatype
  --photo-license: list@photo-license-completer # Must have at least one photo with this license
  --place-id: list # Must be observed within the place with this ID
  --project-id: list # Must be added to the project this ID or slug
  --rank: list@rank-completer # Taxon must have this rank
  --site-id: list # Must be affiliated with the iNaturalist network website with this ID
  --sound-license: list@sound-license-completer # Must have at least one sound with this license
  --taxon-id: list # Only show observations of these taxa and their descendants
  --without-taxon-id: list # Exclude observations of these taxa and their descendants
  --taxon-name: list # Taxon must have a scientific or common name matching this string
  --user-id: list # User must have this ID or login
  --user-login: list # User must have this login
  --ident-user-id: int # Observations identified by a particular user
  --hour: list # Must be observed within this hour of the day
  --day: list # Must be observed within this day of the month
  --month: list # Must be observed within this month
  --year: list # Must be observed within this year
  --created-day: list # Must be created within this day of the month
  --created-month: list # Must be created within this month
  --created-year: list # Must be created within this year
  --term-id: list # Must have an annotation using this controlled term ID
  --term-value-id: list # Must have an annotation using this controlled value ID. Must be combined with the `term_id` parameter
  --without-term-id: int # Exclude observations with annotations using this controlled value ID.
  --without-term-value-id: list # Exclude observations with annotations using this controlled value ID. Must be combined with the `term_id` parameter
  --term-id-or-unknown: list # Must be combined with the `term_value_id` or the `without_term_value_id` parameter. Must have an annotation using this controlled term ID and associated term value IDs or be missing this annotation.
  --annotation-user-id: list # Must have an annotation created by this user
  --acc-above: string # Must have a positional accuracy above this value (meters)
  --acc-below: string # Must have a positional accuracy below this value (meters)
  --acc-below-or-unknown: string # Positional accuracy must be below this value (in meters) or be unknown
  --d1: string # Must be observed on or after this date (format: date)
  --d2: string # Must be observed on or before this date (format: date)
  --created-d1: string # Must be created at or after this time (format: date-time)
  --created-d2: string # Must be created at or before this time (format: date-time)
  --created-on: string # Must be created on this date (format: date)
  --observed-on: string # Must be observed on this date (format: date)
  --unobserved-by-user-id: int # Must not be of a taxon previously observed by this user
  --apply-project-rules-for: string # Must match the rules of the project with this ID or slug
  --cs: string # Taxon must have this conservation status code. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csa: string # Taxon must have a conservation status from this authority. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csi: list@csi-completer # Taxon must have this IUCN conservation status. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --geoprivacy: list@geoprivacy-completer # Must have this geoprivacy setting
  --taxon-geoprivacy: list@taxon-geoprivacy-completer # Filter observations by the most conservative geoprivacy applied by a conservation status associated with one of the taxa proposed in the current identifications.
  --obscuration: list@obscuration-completer # Must have `geoprivacy` or `taxon_geoprivacy` fields matching these values
  --hrank: string@hrank-completer # Taxon must have this rank or lower
  --lrank: string@lrank-completer # Taxon must have this rank or higher
  --iconic-taxa: list@iconic-taxa-completer # Taxon must by within this iconic taxon
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --identifications: string@identifications-completer # Identifications must meet these criteria
  --lat: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --lng: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --radius: string # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)
  --nelat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --nelng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --list-id: int # Taxon must be in the list with this ID
  --not-in-project: string # Must not be in the project with this ID or slug
  --not-matching-project-rules-for: string # Must not match the rules of the project with this ID or slug
  --observation-accuracy-experiment-id: list # Must included in this observation accuracy experiment
  --fails-dqa-accurate: string@bool-completer # Must be voted as not accurately depicting an organism or scene
  --fails-dqa-date: string@bool-completer # Must be voted as not having an accurate date
  --fails-dqa-evidence: string@bool-completer # Must be voted as not evidence of an organism
  --fails-dqa-location: string@bool-completer # Must be voted as not having an accurate location
  --fails-dqa-needs-id: string@bool-completer # Must be voted as the community ID cannot be improved
  --fails-dqa-recent: string@bool-completer # Must be voted as not recent evidence of an organism
  --fails-dqa-subject: string@bool-completer # Must be voted as not having evidence related to a single subject
  --fails-dqa-wild: string@bool-completer # Must be voted as not wild
  --q: string # Search observation properties. Can be combined with `search_on`
  --search-on: string@search-on-completer # Properties to search on, when combined with `q`. Searches across all properties by default
  --quality-grade: string@quality-grade-completer # Must have this quality grade
  --updated-since: string # Must be updated since this time
  --viewer-id: string # See `reviewed`
  --reviewed: string@bool-completer # Observations have been reviewed by the user with ID equal to the value of the `viewer_id` parameter
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "color" $color "scalar") (serialize-qp "acc" $acc "scalar") (serialize-qp "captive" $captive "scalar") (serialize-qp "endemic" $endemic "scalar") (serialize-qp "geo" $geo "scalar") (serialize-qp "id_please" $id_please "scalar") (serialize-qp "identified" $identified "scalar") (serialize-qp "introduced" $introduced "scalar") (serialize-qp "mappable" $mappable "scalar") (serialize-qp "native" $native "scalar") (serialize-qp "out_of_range" $out_of_range "scalar") (serialize-qp "pcid" $pcid "scalar") (serialize-qp "photos" $photos "scalar") (serialize-qp "popular" $popular "scalar") (serialize-qp "sounds" $sounds "scalar") (serialize-qp "taxon_is_active" $taxon_is_active "scalar") (serialize-qp "threatened" $threatened "scalar") (serialize-qp "verifiable" $verifiable "scalar") (serialize-qp "licensed" $licensed "scalar") (serialize-qp "photo_licensed" $photo_licensed "scalar") (serialize-qp "expected_nearby" $expected_nearby "scalar") (serialize-qp "id" $id "csv") (serialize-qp "not_id" $not_id "csv") (serialize-qp "license" $license "csv") (serialize-qp "ofv_datatype" $ofv_datatype "csv") (serialize-qp "photo_license" $photo_license "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "project_id" $project_id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "site_id" $site_id "csv") (serialize-qp "sound_license" $sound_license "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "taxon_name" $taxon_name "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "ident_user_id" $ident_user_id "scalar") (serialize-qp "hour" $hour "csv") (serialize-qp "day" $day "csv") (serialize-qp "month" $month "csv") (serialize-qp "year" $year "csv") (serialize-qp "created_day" $created_day "csv") (serialize-qp "created_month" $created_month "csv") (serialize-qp "created_year" $created_year "csv") (serialize-qp "term_id" $term_id "csv") (serialize-qp "term_value_id" $term_value_id "csv") (serialize-qp "without_term_id" $without_term_id "scalar") (serialize-qp "without_term_value_id" $without_term_value_id "csv") (serialize-qp "term_id_or_unknown" $term_id_or_unknown "csv") (serialize-qp "annotation_user_id" $annotation_user_id "csv") (serialize-qp "acc_above" $acc_above "scalar") (serialize-qp "acc_below" $acc_below "scalar") (serialize-qp "acc_below_or_unknown" $acc_below_or_unknown "scalar") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "created_d1" $created_d1 "scalar") (serialize-qp "created_d2" $created_d2 "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "observed_on" $observed_on "scalar") (serialize-qp "unobserved_by_user_id" $unobserved_by_user_id "scalar") (serialize-qp "apply_project_rules_for" $apply_project_rules_for "scalar") (serialize-qp "cs" $cs "scalar") (serialize-qp "csa" $csa "scalar") (serialize-qp "csi" $csi "csv") (serialize-qp "geoprivacy" $geoprivacy "csv") (serialize-qp "taxon_geoprivacy" $taxon_geoprivacy "csv") (serialize-qp "obscuration" $obscuration "csv") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "iconic_taxa" $iconic_taxa "csv") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "identifications" $identifications "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "nelat" $nelat "scalar") (serialize-qp "nelng" $nelng "scalar") (serialize-qp "swlat" $swlat "scalar") (serialize-qp "swlng" $swlng "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "not_in_project" $not_in_project "scalar") (serialize-qp "not_matching_project_rules_for" $not_matching_project_rules_for "scalar") (serialize-qp "observation_accuracy_experiment_id" $observation_accuracy_experiment_id "csv") (serialize-qp "fails_dqa_accurate" $fails_dqa_accurate "scalar") (serialize-qp "fails_dqa_date" $fails_dqa_date "scalar") (serialize-qp "fails_dqa_evidence" $fails_dqa_evidence "scalar") (serialize-qp "fails_dqa_location" $fails_dqa_location "scalar") (serialize-qp "fails_dqa_needs_id" $fails_dqa_needs_id "scalar") (serialize-qp "fails_dqa_recent" $fails_dqa_recent "scalar") (serialize-qp "fails_dqa_subject" $fails_dqa_subject "scalar") (serialize-qp "fails_dqa_wild" $fails_dqa_wild "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "search_on" $search_on "scalar") (serialize-qp "quality_grade" $quality_grade "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "viewer_id" $viewer_id "scalar") (serialize-qp "reviewed" $reviewed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/heatmap/($zoom)/($x)/($y).png" $qp)
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Heatmap Tiles UTFGrid
#
# GET /heatmap/{zoom}/{x}/{y}.grid.json
export def "heatmap get-by-zoom-x-y-1" [
  zoom: int
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --color: string # Primary color to use in tile creation. Accepts common colors by string (e.g. `color=blue`), and accepts escaped color HEX codes (e.g. `color=%2386a91c`)
  --acc: string@bool-completer # Whether or not positional accuracy / coordinate uncertainty has been specified
  --captive: string@bool-completer # Captive or cultivated observations
  --endemic: string@bool-completer # Observations whose taxa are endemic to their location
  --geo: string@bool-completer # Observations that are georeferenced
  --id-please: string@bool-completer # Observations with the deprecated `ID, Please!` flag. Note that this will return observations, but that this attribute is no longer used.
  --identified: string@bool-completer # Observations that have community identifications
  --introduced: string@bool-completer # Observations whose taxa are introduced in their location
  --mappable: string@bool-completer # Observations that show on map tiles
  --native: string@bool-completer # Observations whose taxa are native to their location
  --out-of-range: string@bool-completer # Observations whose taxa are outside their known ranges
  --pcid: string@bool-completer # Observations identified by the curator of a project. If the `project_id` parameter is also specified, this will only consider observations identified by curators of the specified project(s)
  --photos: string@bool-completer # Observations with photos
  --popular: string@bool-completer # Observations that have been favorited by at least one user
  --sounds: string@bool-completer # Observations with sounds
  --taxon-is-active: string@bool-completer # Observations of active taxon concepts
  --threatened: string@bool-completer # Observations whose taxa are threatened in their location
  --verifiable: string@bool-completer # Observations with a `quality_grade` of either `needs_id` or `research`. Equivalent to `quality_grade=needs_id,research`
  --licensed: string@bool-completer # License attribute of an observation must not be null
  --photo-licensed: string@bool-completer # License attribute of at least one photo of an observation must not be null
  --expected-nearby: string@bool-completer # Observation taxon is expected nearby
  --id: list # Must have this ID
  --not-id: list # Must not have this ID
  --license: list@license-completer # Observation must have this license
  --ofv-datatype: list # Must have an observation field value with this datatype
  --photo-license: list@photo-license-completer # Must have at least one photo with this license
  --place-id: list # Must be observed within the place with this ID
  --project-id: list # Must be added to the project this ID or slug
  --rank: list@rank-completer # Taxon must have this rank
  --site-id: list # Must be affiliated with the iNaturalist network website with this ID
  --sound-license: list@sound-license-completer # Must have at least one sound with this license
  --taxon-id: list # Only show observations of these taxa and their descendants
  --without-taxon-id: list # Exclude observations of these taxa and their descendants
  --taxon-name: list # Taxon must have a scientific or common name matching this string
  --user-id: list # User must have this ID or login
  --user-login: list # User must have this login
  --ident-user-id: int # Observations identified by a particular user
  --hour: list # Must be observed within this hour of the day
  --day: list # Must be observed within this day of the month
  --month: list # Must be observed within this month
  --year: list # Must be observed within this year
  --created-day: list # Must be created within this day of the month
  --created-month: list # Must be created within this month
  --created-year: list # Must be created within this year
  --term-id: list # Must have an annotation using this controlled term ID
  --term-value-id: list # Must have an annotation using this controlled value ID. Must be combined with the `term_id` parameter
  --without-term-id: int # Exclude observations with annotations using this controlled value ID.
  --without-term-value-id: list # Exclude observations with annotations using this controlled value ID. Must be combined with the `term_id` parameter
  --term-id-or-unknown: list # Must be combined with the `term_value_id` or the `without_term_value_id` parameter. Must have an annotation using this controlled term ID and associated term value IDs or be missing this annotation.
  --annotation-user-id: list # Must have an annotation created by this user
  --acc-above: string # Must have a positional accuracy above this value (meters)
  --acc-below: string # Must have a positional accuracy below this value (meters)
  --acc-below-or-unknown: string # Positional accuracy must be below this value (in meters) or be unknown
  --d1: string # Must be observed on or after this date (format: date)
  --d2: string # Must be observed on or before this date (format: date)
  --created-d1: string # Must be created at or after this time (format: date-time)
  --created-d2: string # Must be created at or before this time (format: date-time)
  --created-on: string # Must be created on this date (format: date)
  --observed-on: string # Must be observed on this date (format: date)
  --unobserved-by-user-id: int # Must not be of a taxon previously observed by this user
  --apply-project-rules-for: string # Must match the rules of the project with this ID or slug
  --cs: string # Taxon must have this conservation status code. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csa: string # Taxon must have a conservation status from this authority. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csi: list@csi-completer # Taxon must have this IUCN conservation status. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --geoprivacy: list@geoprivacy-completer # Must have this geoprivacy setting
  --taxon-geoprivacy: list@taxon-geoprivacy-completer # Filter observations by the most conservative geoprivacy applied by a conservation status associated with one of the taxa proposed in the current identifications.
  --obscuration: list@obscuration-completer # Must have `geoprivacy` or `taxon_geoprivacy` fields matching these values
  --hrank: string@hrank-completer # Taxon must have this rank or lower
  --lrank: string@lrank-completer # Taxon must have this rank or higher
  --iconic-taxa: list@iconic-taxa-completer # Taxon must by within this iconic taxon
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --identifications: string@identifications-completer # Identifications must meet these criteria
  --lat: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --lng: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --radius: string # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)
  --nelat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --nelng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --list-id: int # Taxon must be in the list with this ID
  --not-in-project: string # Must not be in the project with this ID or slug
  --not-matching-project-rules-for: string # Must not match the rules of the project with this ID or slug
  --observation-accuracy-experiment-id: list # Must included in this observation accuracy experiment
  --fails-dqa-accurate: string@bool-completer # Must be voted as not accurately depicting an organism or scene
  --fails-dqa-date: string@bool-completer # Must be voted as not having an accurate date
  --fails-dqa-evidence: string@bool-completer # Must be voted as not evidence of an organism
  --fails-dqa-location: string@bool-completer # Must be voted as not having an accurate location
  --fails-dqa-needs-id: string@bool-completer # Must be voted as the community ID cannot be improved
  --fails-dqa-recent: string@bool-completer # Must be voted as not recent evidence of an organism
  --fails-dqa-subject: string@bool-completer # Must be voted as not having evidence related to a single subject
  --fails-dqa-wild: string@bool-completer # Must be voted as not wild
  --q: string # Search observation properties. Can be combined with `search_on`
  --search-on: string@search-on-completer # Properties to search on, when combined with `q`. Searches across all properties by default
  --quality-grade: string@quality-grade-completer # Must have this quality grade
  --updated-since: string # Must be updated since this time
  --viewer-id: string # See `reviewed`
  --reviewed: string@bool-completer # Observations have been reviewed by the user with ID equal to the value of the `viewer_id` parameter
]: nothing -> record<grid: list<string>, keys: list<string>, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "color" $color "scalar") (serialize-qp "acc" $acc "scalar") (serialize-qp "captive" $captive "scalar") (serialize-qp "endemic" $endemic "scalar") (serialize-qp "geo" $geo "scalar") (serialize-qp "id_please" $id_please "scalar") (serialize-qp "identified" $identified "scalar") (serialize-qp "introduced" $introduced "scalar") (serialize-qp "mappable" $mappable "scalar") (serialize-qp "native" $native "scalar") (serialize-qp "out_of_range" $out_of_range "scalar") (serialize-qp "pcid" $pcid "scalar") (serialize-qp "photos" $photos "scalar") (serialize-qp "popular" $popular "scalar") (serialize-qp "sounds" $sounds "scalar") (serialize-qp "taxon_is_active" $taxon_is_active "scalar") (serialize-qp "threatened" $threatened "scalar") (serialize-qp "verifiable" $verifiable "scalar") (serialize-qp "licensed" $licensed "scalar") (serialize-qp "photo_licensed" $photo_licensed "scalar") (serialize-qp "expected_nearby" $expected_nearby "scalar") (serialize-qp "id" $id "csv") (serialize-qp "not_id" $not_id "csv") (serialize-qp "license" $license "csv") (serialize-qp "ofv_datatype" $ofv_datatype "csv") (serialize-qp "photo_license" $photo_license "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "project_id" $project_id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "site_id" $site_id "csv") (serialize-qp "sound_license" $sound_license "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "taxon_name" $taxon_name "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "ident_user_id" $ident_user_id "scalar") (serialize-qp "hour" $hour "csv") (serialize-qp "day" $day "csv") (serialize-qp "month" $month "csv") (serialize-qp "year" $year "csv") (serialize-qp "created_day" $created_day "csv") (serialize-qp "created_month" $created_month "csv") (serialize-qp "created_year" $created_year "csv") (serialize-qp "term_id" $term_id "csv") (serialize-qp "term_value_id" $term_value_id "csv") (serialize-qp "without_term_id" $without_term_id "scalar") (serialize-qp "without_term_value_id" $without_term_value_id "csv") (serialize-qp "term_id_or_unknown" $term_id_or_unknown "csv") (serialize-qp "annotation_user_id" $annotation_user_id "csv") (serialize-qp "acc_above" $acc_above "scalar") (serialize-qp "acc_below" $acc_below "scalar") (serialize-qp "acc_below_or_unknown" $acc_below_or_unknown "scalar") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "created_d1" $created_d1 "scalar") (serialize-qp "created_d2" $created_d2 "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "observed_on" $observed_on "scalar") (serialize-qp "unobserved_by_user_id" $unobserved_by_user_id "scalar") (serialize-qp "apply_project_rules_for" $apply_project_rules_for "scalar") (serialize-qp "cs" $cs "scalar") (serialize-qp "csa" $csa "scalar") (serialize-qp "csi" $csi "csv") (serialize-qp "geoprivacy" $geoprivacy "csv") (serialize-qp "taxon_geoprivacy" $taxon_geoprivacy "csv") (serialize-qp "obscuration" $obscuration "csv") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "iconic_taxa" $iconic_taxa "csv") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "identifications" $identifications "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "nelat" $nelat "scalar") (serialize-qp "nelng" $nelng "scalar") (serialize-qp "swlat" $swlat "scalar") (serialize-qp "swlng" $swlng "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "not_in_project" $not_in_project "scalar") (serialize-qp "not_matching_project_rules_for" $not_matching_project_rules_for "scalar") (serialize-qp "observation_accuracy_experiment_id" $observation_accuracy_experiment_id "csv") (serialize-qp "fails_dqa_accurate" $fails_dqa_accurate "scalar") (serialize-qp "fails_dqa_date" $fails_dqa_date "scalar") (serialize-qp "fails_dqa_evidence" $fails_dqa_evidence "scalar") (serialize-qp "fails_dqa_location" $fails_dqa_location "scalar") (serialize-qp "fails_dqa_needs_id" $fails_dqa_needs_id "scalar") (serialize-qp "fails_dqa_recent" $fails_dqa_recent "scalar") (serialize-qp "fails_dqa_subject" $fails_dqa_subject "scalar") (serialize-qp "fails_dqa_wild" $fails_dqa_wild "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "search_on" $search_on "scalar") (serialize-qp "quality_grade" $quality_grade "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "viewer_id" $viewer_id "scalar") (serialize-qp "reviewed" $reviewed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/heatmap/($zoom)/($x)/($y).grid.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Points Tiles
#
# GET /points/{zoom}/{x}/{y}.png
export def "points get-by-zoom-x-y" [
  zoom: int
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --color: string # Primary color to use in tile creation. Accepts common colors by string (e.g. `color=blue`), and accepts escaped color HEX codes (e.g. `color=%2386a91c`)
  --acc: string@bool-completer # Whether or not positional accuracy / coordinate uncertainty has been specified
  --captive: string@bool-completer # Captive or cultivated observations
  --endemic: string@bool-completer # Observations whose taxa are endemic to their location
  --geo: string@bool-completer # Observations that are georeferenced
  --id-please: string@bool-completer # Observations with the deprecated `ID, Please!` flag. Note that this will return observations, but that this attribute is no longer used.
  --identified: string@bool-completer # Observations that have community identifications
  --introduced: string@bool-completer # Observations whose taxa are introduced in their location
  --mappable: string@bool-completer # Observations that show on map tiles
  --native: string@bool-completer # Observations whose taxa are native to their location
  --out-of-range: string@bool-completer # Observations whose taxa are outside their known ranges
  --pcid: string@bool-completer # Observations identified by the curator of a project. If the `project_id` parameter is also specified, this will only consider observations identified by curators of the specified project(s)
  --photos: string@bool-completer # Observations with photos
  --popular: string@bool-completer # Observations that have been favorited by at least one user
  --sounds: string@bool-completer # Observations with sounds
  --taxon-is-active: string@bool-completer # Observations of active taxon concepts
  --threatened: string@bool-completer # Observations whose taxa are threatened in their location
  --verifiable: string@bool-completer # Observations with a `quality_grade` of either `needs_id` or `research`. Equivalent to `quality_grade=needs_id,research`
  --licensed: string@bool-completer # License attribute of an observation must not be null
  --photo-licensed: string@bool-completer # License attribute of at least one photo of an observation must not be null
  --expected-nearby: string@bool-completer # Observation taxon is expected nearby
  --id: list # Must have this ID
  --not-id: list # Must not have this ID
  --license: list@license-completer # Observation must have this license
  --ofv-datatype: list # Must have an observation field value with this datatype
  --photo-license: list@photo-license-completer # Must have at least one photo with this license
  --place-id: list # Must be observed within the place with this ID
  --project-id: list # Must be added to the project this ID or slug
  --rank: list@rank-completer # Taxon must have this rank
  --site-id: list # Must be affiliated with the iNaturalist network website with this ID
  --sound-license: list@sound-license-completer # Must have at least one sound with this license
  --taxon-id: list # Only show observations of these taxa and their descendants
  --without-taxon-id: list # Exclude observations of these taxa and their descendants
  --taxon-name: list # Taxon must have a scientific or common name matching this string
  --user-id: list # User must have this ID or login
  --user-login: list # User must have this login
  --ident-user-id: int # Observations identified by a particular user
  --hour: list # Must be observed within this hour of the day
  --day: list # Must be observed within this day of the month
  --month: list # Must be observed within this month
  --year: list # Must be observed within this year
  --created-day: list # Must be created within this day of the month
  --created-month: list # Must be created within this month
  --created-year: list # Must be created within this year
  --term-id: list # Must have an annotation using this controlled term ID
  --term-value-id: list # Must have an annotation using this controlled value ID. Must be combined with the `term_id` parameter
  --without-term-id: int # Exclude observations with annotations using this controlled value ID.
  --without-term-value-id: list # Exclude observations with annotations using this controlled value ID. Must be combined with the `term_id` parameter
  --term-id-or-unknown: list # Must be combined with the `term_value_id` or the `without_term_value_id` parameter. Must have an annotation using this controlled term ID and associated term value IDs or be missing this annotation.
  --annotation-user-id: list # Must have an annotation created by this user
  --acc-above: string # Must have a positional accuracy above this value (meters)
  --acc-below: string # Must have a positional accuracy below this value (meters)
  --acc-below-or-unknown: string # Positional accuracy must be below this value (in meters) or be unknown
  --d1: string # Must be observed on or after this date (format: date)
  --d2: string # Must be observed on or before this date (format: date)
  --created-d1: string # Must be created at or after this time (format: date-time)
  --created-d2: string # Must be created at or before this time (format: date-time)
  --created-on: string # Must be created on this date (format: date)
  --observed-on: string # Must be observed on this date (format: date)
  --unobserved-by-user-id: int # Must not be of a taxon previously observed by this user
  --apply-project-rules-for: string # Must match the rules of the project with this ID or slug
  --cs: string # Taxon must have this conservation status code. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csa: string # Taxon must have a conservation status from this authority. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csi: list@csi-completer # Taxon must have this IUCN conservation status. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --geoprivacy: list@geoprivacy-completer # Must have this geoprivacy setting
  --taxon-geoprivacy: list@taxon-geoprivacy-completer # Filter observations by the most conservative geoprivacy applied by a conservation status associated with one of the taxa proposed in the current identifications.
  --obscuration: list@obscuration-completer # Must have `geoprivacy` or `taxon_geoprivacy` fields matching these values
  --hrank: string@hrank-completer # Taxon must have this rank or lower
  --lrank: string@lrank-completer # Taxon must have this rank or higher
  --iconic-taxa: list@iconic-taxa-completer # Taxon must by within this iconic taxon
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --identifications: string@identifications-completer # Identifications must meet these criteria
  --lat: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --lng: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --radius: string # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)
  --nelat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --nelng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --list-id: int # Taxon must be in the list with this ID
  --not-in-project: string # Must not be in the project with this ID or slug
  --not-matching-project-rules-for: string # Must not match the rules of the project with this ID or slug
  --observation-accuracy-experiment-id: list # Must included in this observation accuracy experiment
  --fails-dqa-accurate: string@bool-completer # Must be voted as not accurately depicting an organism or scene
  --fails-dqa-date: string@bool-completer # Must be voted as not having an accurate date
  --fails-dqa-evidence: string@bool-completer # Must be voted as not evidence of an organism
  --fails-dqa-location: string@bool-completer # Must be voted as not having an accurate location
  --fails-dqa-needs-id: string@bool-completer # Must be voted as the community ID cannot be improved
  --fails-dqa-recent: string@bool-completer # Must be voted as not recent evidence of an organism
  --fails-dqa-subject: string@bool-completer # Must be voted as not having evidence related to a single subject
  --fails-dqa-wild: string@bool-completer # Must be voted as not wild
  --q: string # Search observation properties. Can be combined with `search_on`
  --search-on: string@search-on-completer # Properties to search on, when combined with `q`. Searches across all properties by default
  --quality-grade: string@quality-grade-completer # Must have this quality grade
  --updated-since: string # Must be updated since this time
  --viewer-id: string # See `reviewed`
  --reviewed: string@bool-completer # Observations have been reviewed by the user with ID equal to the value of the `viewer_id` parameter
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "color" $color "scalar") (serialize-qp "acc" $acc "scalar") (serialize-qp "captive" $captive "scalar") (serialize-qp "endemic" $endemic "scalar") (serialize-qp "geo" $geo "scalar") (serialize-qp "id_please" $id_please "scalar") (serialize-qp "identified" $identified "scalar") (serialize-qp "introduced" $introduced "scalar") (serialize-qp "mappable" $mappable "scalar") (serialize-qp "native" $native "scalar") (serialize-qp "out_of_range" $out_of_range "scalar") (serialize-qp "pcid" $pcid "scalar") (serialize-qp "photos" $photos "scalar") (serialize-qp "popular" $popular "scalar") (serialize-qp "sounds" $sounds "scalar") (serialize-qp "taxon_is_active" $taxon_is_active "scalar") (serialize-qp "threatened" $threatened "scalar") (serialize-qp "verifiable" $verifiable "scalar") (serialize-qp "licensed" $licensed "scalar") (serialize-qp "photo_licensed" $photo_licensed "scalar") (serialize-qp "expected_nearby" $expected_nearby "scalar") (serialize-qp "id" $id "csv") (serialize-qp "not_id" $not_id "csv") (serialize-qp "license" $license "csv") (serialize-qp "ofv_datatype" $ofv_datatype "csv") (serialize-qp "photo_license" $photo_license "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "project_id" $project_id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "site_id" $site_id "csv") (serialize-qp "sound_license" $sound_license "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "taxon_name" $taxon_name "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "ident_user_id" $ident_user_id "scalar") (serialize-qp "hour" $hour "csv") (serialize-qp "day" $day "csv") (serialize-qp "month" $month "csv") (serialize-qp "year" $year "csv") (serialize-qp "created_day" $created_day "csv") (serialize-qp "created_month" $created_month "csv") (serialize-qp "created_year" $created_year "csv") (serialize-qp "term_id" $term_id "csv") (serialize-qp "term_value_id" $term_value_id "csv") (serialize-qp "without_term_id" $without_term_id "scalar") (serialize-qp "without_term_value_id" $without_term_value_id "csv") (serialize-qp "term_id_or_unknown" $term_id_or_unknown "csv") (serialize-qp "annotation_user_id" $annotation_user_id "csv") (serialize-qp "acc_above" $acc_above "scalar") (serialize-qp "acc_below" $acc_below "scalar") (serialize-qp "acc_below_or_unknown" $acc_below_or_unknown "scalar") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "created_d1" $created_d1 "scalar") (serialize-qp "created_d2" $created_d2 "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "observed_on" $observed_on "scalar") (serialize-qp "unobserved_by_user_id" $unobserved_by_user_id "scalar") (serialize-qp "apply_project_rules_for" $apply_project_rules_for "scalar") (serialize-qp "cs" $cs "scalar") (serialize-qp "csa" $csa "scalar") (serialize-qp "csi" $csi "csv") (serialize-qp "geoprivacy" $geoprivacy "csv") (serialize-qp "taxon_geoprivacy" $taxon_geoprivacy "csv") (serialize-qp "obscuration" $obscuration "csv") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "iconic_taxa" $iconic_taxa "csv") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "identifications" $identifications "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "nelat" $nelat "scalar") (serialize-qp "nelng" $nelng "scalar") (serialize-qp "swlat" $swlat "scalar") (serialize-qp "swlng" $swlng "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "not_in_project" $not_in_project "scalar") (serialize-qp "not_matching_project_rules_for" $not_matching_project_rules_for "scalar") (serialize-qp "observation_accuracy_experiment_id" $observation_accuracy_experiment_id "csv") (serialize-qp "fails_dqa_accurate" $fails_dqa_accurate "scalar") (serialize-qp "fails_dqa_date" $fails_dqa_date "scalar") (serialize-qp "fails_dqa_evidence" $fails_dqa_evidence "scalar") (serialize-qp "fails_dqa_location" $fails_dqa_location "scalar") (serialize-qp "fails_dqa_needs_id" $fails_dqa_needs_id "scalar") (serialize-qp "fails_dqa_recent" $fails_dqa_recent "scalar") (serialize-qp "fails_dqa_subject" $fails_dqa_subject "scalar") (serialize-qp "fails_dqa_wild" $fails_dqa_wild "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "search_on" $search_on "scalar") (serialize-qp "quality_grade" $quality_grade "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "viewer_id" $viewer_id "scalar") (serialize-qp "reviewed" $reviewed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/points/($zoom)/($x)/($y).png" $qp)
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Points Tiles UTFGrid
#
# GET /points/{zoom}/{x}/{y}.grid.json
export def "points get-by-zoom-x-y-1" [
  zoom: int
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --color: string # Primary color to use in tile creation. Accepts common colors by string (e.g. `color=blue`), and accepts escaped color HEX codes (e.g. `color=%2386a91c`)
  --acc: string@bool-completer # Whether or not positional accuracy / coordinate uncertainty has been specified
  --captive: string@bool-completer # Captive or cultivated observations
  --endemic: string@bool-completer # Observations whose taxa are endemic to their location
  --geo: string@bool-completer # Observations that are georeferenced
  --id-please: string@bool-completer # Observations with the deprecated `ID, Please!` flag. Note that this will return observations, but that this attribute is no longer used.
  --identified: string@bool-completer # Observations that have community identifications
  --introduced: string@bool-completer # Observations whose taxa are introduced in their location
  --mappable: string@bool-completer # Observations that show on map tiles
  --native: string@bool-completer # Observations whose taxa are native to their location
  --out-of-range: string@bool-completer # Observations whose taxa are outside their known ranges
  --pcid: string@bool-completer # Observations identified by the curator of a project. If the `project_id` parameter is also specified, this will only consider observations identified by curators of the specified project(s)
  --photos: string@bool-completer # Observations with photos
  --popular: string@bool-completer # Observations that have been favorited by at least one user
  --sounds: string@bool-completer # Observations with sounds
  --taxon-is-active: string@bool-completer # Observations of active taxon concepts
  --threatened: string@bool-completer # Observations whose taxa are threatened in their location
  --verifiable: string@bool-completer # Observations with a `quality_grade` of either `needs_id` or `research`. Equivalent to `quality_grade=needs_id,research`
  --licensed: string@bool-completer # License attribute of an observation must not be null
  --photo-licensed: string@bool-completer # License attribute of at least one photo of an observation must not be null
  --expected-nearby: string@bool-completer # Observation taxon is expected nearby
  --id: list # Must have this ID
  --not-id: list # Must not have this ID
  --license: list@license-completer # Observation must have this license
  --ofv-datatype: list # Must have an observation field value with this datatype
  --photo-license: list@photo-license-completer # Must have at least one photo with this license
  --place-id: list # Must be observed within the place with this ID
  --project-id: list # Must be added to the project this ID or slug
  --rank: list@rank-completer # Taxon must have this rank
  --site-id: list # Must be affiliated with the iNaturalist network website with this ID
  --sound-license: list@sound-license-completer # Must have at least one sound with this license
  --taxon-id: list # Only show observations of these taxa and their descendants
  --without-taxon-id: list # Exclude observations of these taxa and their descendants
  --taxon-name: list # Taxon must have a scientific or common name matching this string
  --user-id: list # User must have this ID or login
  --user-login: list # User must have this login
  --ident-user-id: int # Observations identified by a particular user
  --hour: list # Must be observed within this hour of the day
  --day: list # Must be observed within this day of the month
  --month: list # Must be observed within this month
  --year: list # Must be observed within this year
  --created-day: list # Must be created within this day of the month
  --created-month: list # Must be created within this month
  --created-year: list # Must be created within this year
  --term-id: list # Must have an annotation using this controlled term ID
  --term-value-id: list # Must have an annotation using this controlled value ID. Must be combined with the `term_id` parameter
  --without-term-id: int # Exclude observations with annotations using this controlled value ID.
  --without-term-value-id: list # Exclude observations with annotations using this controlled value ID. Must be combined with the `term_id` parameter
  --term-id-or-unknown: list # Must be combined with the `term_value_id` or the `without_term_value_id` parameter. Must have an annotation using this controlled term ID and associated term value IDs or be missing this annotation.
  --annotation-user-id: list # Must have an annotation created by this user
  --acc-above: string # Must have a positional accuracy above this value (meters)
  --acc-below: string # Must have a positional accuracy below this value (meters)
  --acc-below-or-unknown: string # Positional accuracy must be below this value (in meters) or be unknown
  --d1: string # Must be observed on or after this date (format: date)
  --d2: string # Must be observed on or before this date (format: date)
  --created-d1: string # Must be created at or after this time (format: date-time)
  --created-d2: string # Must be created at or before this time (format: date-time)
  --created-on: string # Must be created on this date (format: date)
  --observed-on: string # Must be observed on this date (format: date)
  --unobserved-by-user-id: int # Must not be of a taxon previously observed by this user
  --apply-project-rules-for: string # Must match the rules of the project with this ID or slug
  --cs: string # Taxon must have this conservation status code. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csa: string # Taxon must have a conservation status from this authority. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --csi: list@csi-completer # Taxon must have this IUCN conservation status. If the `place_id` parameter is also specified, this will only consider statuses specific to that place
  --geoprivacy: list@geoprivacy-completer # Must have this geoprivacy setting
  --taxon-geoprivacy: list@taxon-geoprivacy-completer # Filter observations by the most conservative geoprivacy applied by a conservation status associated with one of the taxa proposed in the current identifications.
  --obscuration: list@obscuration-completer # Must have `geoprivacy` or `taxon_geoprivacy` fields matching these values
  --hrank: string@hrank-completer # Taxon must have this rank or lower
  --lrank: string@lrank-completer # Taxon must have this rank or higher
  --iconic-taxa: list@iconic-taxa-completer # Taxon must by within this iconic taxon
  --id-above: string # Must have an ID above this value
  --id-below: string # Must have an ID below this value
  --identifications: string@identifications-completer # Identifications must meet these criteria
  --lat: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --lng: float # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)  (format: double)
  --radius: string # Must be within a {`radius`} kilometer circle around this lat/lng (*lat, *lng, radius)
  --nelat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --nelng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlat: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --swlng: float # Must be within this bounding box (*nelat, *nelng, *swlat, *swlng)  (format: double)
  --list-id: int # Taxon must be in the list with this ID
  --not-in-project: string # Must not be in the project with this ID or slug
  --not-matching-project-rules-for: string # Must not match the rules of the project with this ID or slug
  --observation-accuracy-experiment-id: list # Must included in this observation accuracy experiment
  --fails-dqa-accurate: string@bool-completer # Must be voted as not accurately depicting an organism or scene
  --fails-dqa-date: string@bool-completer # Must be voted as not having an accurate date
  --fails-dqa-evidence: string@bool-completer # Must be voted as not evidence of an organism
  --fails-dqa-location: string@bool-completer # Must be voted as not having an accurate location
  --fails-dqa-needs-id: string@bool-completer # Must be voted as the community ID cannot be improved
  --fails-dqa-recent: string@bool-completer # Must be voted as not recent evidence of an organism
  --fails-dqa-subject: string@bool-completer # Must be voted as not having evidence related to a single subject
  --fails-dqa-wild: string@bool-completer # Must be voted as not wild
  --q: string # Search observation properties. Can be combined with `search_on`
  --search-on: string@search-on-completer # Properties to search on, when combined with `q`. Searches across all properties by default
  --quality-grade: string@quality-grade-completer # Must have this quality grade
  --updated-since: string # Must be updated since this time
  --viewer-id: string # See `reviewed`
  --reviewed: string@bool-completer # Observations have been reviewed by the user with ID equal to the value of the `viewer_id` parameter
]: nothing -> record<grid: list<string>, keys: list<string>, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "color" $color "scalar") (serialize-qp "acc" $acc "scalar") (serialize-qp "captive" $captive "scalar") (serialize-qp "endemic" $endemic "scalar") (serialize-qp "geo" $geo "scalar") (serialize-qp "id_please" $id_please "scalar") (serialize-qp "identified" $identified "scalar") (serialize-qp "introduced" $introduced "scalar") (serialize-qp "mappable" $mappable "scalar") (serialize-qp "native" $native "scalar") (serialize-qp "out_of_range" $out_of_range "scalar") (serialize-qp "pcid" $pcid "scalar") (serialize-qp "photos" $photos "scalar") (serialize-qp "popular" $popular "scalar") (serialize-qp "sounds" $sounds "scalar") (serialize-qp "taxon_is_active" $taxon_is_active "scalar") (serialize-qp "threatened" $threatened "scalar") (serialize-qp "verifiable" $verifiable "scalar") (serialize-qp "licensed" $licensed "scalar") (serialize-qp "photo_licensed" $photo_licensed "scalar") (serialize-qp "expected_nearby" $expected_nearby "scalar") (serialize-qp "id" $id "csv") (serialize-qp "not_id" $not_id "csv") (serialize-qp "license" $license "csv") (serialize-qp "ofv_datatype" $ofv_datatype "csv") (serialize-qp "photo_license" $photo_license "csv") (serialize-qp "place_id" $place_id "csv") (serialize-qp "project_id" $project_id "csv") (serialize-qp "rank" $rank "csv") (serialize-qp "site_id" $site_id "csv") (serialize-qp "sound_license" $sound_license "csv") (serialize-qp "taxon_id" $taxon_id "csv") (serialize-qp "without_taxon_id" $without_taxon_id "csv") (serialize-qp "taxon_name" $taxon_name "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_login" $user_login "csv") (serialize-qp "ident_user_id" $ident_user_id "scalar") (serialize-qp "hour" $hour "csv") (serialize-qp "day" $day "csv") (serialize-qp "month" $month "csv") (serialize-qp "year" $year "csv") (serialize-qp "created_day" $created_day "csv") (serialize-qp "created_month" $created_month "csv") (serialize-qp "created_year" $created_year "csv") (serialize-qp "term_id" $term_id "csv") (serialize-qp "term_value_id" $term_value_id "csv") (serialize-qp "without_term_id" $without_term_id "scalar") (serialize-qp "without_term_value_id" $without_term_value_id "csv") (serialize-qp "term_id_or_unknown" $term_id_or_unknown "csv") (serialize-qp "annotation_user_id" $annotation_user_id "csv") (serialize-qp "acc_above" $acc_above "scalar") (serialize-qp "acc_below" $acc_below "scalar") (serialize-qp "acc_below_or_unknown" $acc_below_or_unknown "scalar") (serialize-qp "d1" $d1 "scalar") (serialize-qp "d2" $d2 "scalar") (serialize-qp "created_d1" $created_d1 "scalar") (serialize-qp "created_d2" $created_d2 "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "observed_on" $observed_on "scalar") (serialize-qp "unobserved_by_user_id" $unobserved_by_user_id "scalar") (serialize-qp "apply_project_rules_for" $apply_project_rules_for "scalar") (serialize-qp "cs" $cs "scalar") (serialize-qp "csa" $csa "scalar") (serialize-qp "csi" $csi "csv") (serialize-qp "geoprivacy" $geoprivacy "csv") (serialize-qp "taxon_geoprivacy" $taxon_geoprivacy "csv") (serialize-qp "obscuration" $obscuration "csv") (serialize-qp "hrank" $hrank "scalar") (serialize-qp "lrank" $lrank "scalar") (serialize-qp "iconic_taxa" $iconic_taxa "csv") (serialize-qp "id_above" $id_above "scalar") (serialize-qp "id_below" $id_below "scalar") (serialize-qp "identifications" $identifications "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "nelat" $nelat "scalar") (serialize-qp "nelng" $nelng "scalar") (serialize-qp "swlat" $swlat "scalar") (serialize-qp "swlng" $swlng "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "not_in_project" $not_in_project "scalar") (serialize-qp "not_matching_project_rules_for" $not_matching_project_rules_for "scalar") (serialize-qp "observation_accuracy_experiment_id" $observation_accuracy_experiment_id "csv") (serialize-qp "fails_dqa_accurate" $fails_dqa_accurate "scalar") (serialize-qp "fails_dqa_date" $fails_dqa_date "scalar") (serialize-qp "fails_dqa_evidence" $fails_dqa_evidence "scalar") (serialize-qp "fails_dqa_location" $fails_dqa_location "scalar") (serialize-qp "fails_dqa_needs_id" $fails_dqa_needs_id "scalar") (serialize-qp "fails_dqa_recent" $fails_dqa_recent "scalar") (serialize-qp "fails_dqa_subject" $fails_dqa_subject "scalar") (serialize-qp "fails_dqa_wild" $fails_dqa_wild "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "search_on" $search_on "scalar") (serialize-qp "quality_grade" $quality_grade "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "viewer_id" $viewer_id "scalar") (serialize-qp "reviewed" $reviewed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/points/($zoom)/($x)/($y).grid.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Place Tiles
#
# GET /places/{place_id}/{zoom}/{x}/{y}.png
export def "places get-by-place_id-zoom-x-y" [
  place_id: int
  zoom: int
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ttl: string # Set the `Cache-Control` HTTP header with this value as `max-age`, in seconds. This means subsequent identical requests will be cached on iNaturalist servers, and commonly within web browsers
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ttl" $ttl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/($zoom)/($x)/($y).png" $qp)
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Taxon Place Tiles
#
# GET /taxon_places/{taxon_id}/{zoom}/{x}/{y}.png
export def "taxon-places get" [
  taxon_id: int
  zoom: int
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ttl: string # Set the `Cache-Control` HTTP header with this value as `max-age`, in seconds. This means subsequent identical requests will be cached on iNaturalist servers, and commonly within web browsers
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ttl" $ttl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/taxon_places/($taxon_id)/($zoom)/($x)/($y).png" $qp)
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Taxon Range Tiles
#
# GET /taxon_ranges/{taxon_id}/{zoom}/{x}/{y}.png
export def "taxon-ranges get" [
  taxon_id: int
  zoom: int
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --color: string # Primary color to use in tile creation. Accepts common colors by string (e.g. `color=blue`), and accepts escaped color HEX codes (e.g. `color=%2386a91c`)
  --ttl: string # Set the `Cache-Control` HTTP header with this value as `max-age`, in seconds. This means subsequent identical requests will be cached on iNaturalist servers, and commonly within web browsers
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "color" $color "scalar") (serialize-qp "ttl" $ttl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/taxon_ranges/($taxon_id)/($zoom)/($x)/($y).png" $qp)
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
