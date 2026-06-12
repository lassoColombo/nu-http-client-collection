# Auto-generated client for Open Food Facts Open API V3 - under development v3
# Source: https://raw.githubusercontent.com/openfoodfacts/openfoodfacts-server/main/docs/api/ref/api-v3.yaml
# Auth: --token flag or $env.OPEN_FOOD_FACTS_OPEN_API_V3_UNDER_DEVELOPMENT_TOKEN

const BASE_URL = "https://world.openfoodfacts.org"
const DEFAULT_AUTH = "user-agent"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPEN_FOOD_FACTS_OPEN_API_V3_UNDER_DEVELOPMENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "cookie-session" => { {headers: {Cookie: $"session=($token_val)"}, query: ""} }
    "user-agent" => { {headers: {User-Agent: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://world.openfoodfacts.org" "https://world.openfoodfacts.net"] }
def auth-scheme-completer [] { ["cookie-session" "user-agent"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "product get-api-v3-product-code" } } | get name | first)
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

# Get Product Data
#
# GET /api/v3/product/{code}
# operationId: get-api-v3-product-code
export def "product get-api-v3-product-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Comma separated list of fields requested in the response.  Special values: * "none": returns no fields * "raw": returns all fields as stored internally in the database * "all": returns all fields except generated fields that need to be explicitly requested such as "knowledge_panels".  Defaults to "all" for READ requests. The "all" value can also be combined with fields like "attribute_groups" and "knowledge_panels".
]: nothing -> record<product: any> {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/product/($code)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or Update Product
#
# PATCH /api/v3/product/{code}
# operationId: patch-api-v3-product-code
export def "product patch-api-v3-product-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string
  --password: string # Password for login (format: password)
  --product: any
]: any -> record<product: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-session"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/product/($code)")
  let body = {user_id: $user_id, password: $password, product: $product} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upload Product Image
#
# POST /api/v3/product/{code}/images
# operationId: post-api-v3-product-code-images
export def "product-images post-api-v3-product-code-images" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # Username for login  Note: you must always use the username (and not the email) as it is far less brittle.
  --password: string # Password for login (format: password)
  --image-data-base64: string # Base64 encoded image data (supported formats: JPEG, PNG, GIF, HEIC)
  --selected: any # Optional instructions to select (and possibly crop) the uploaded image for specific information (e.g. front, ingredients, nutrition, packaging) for specific languages.
]: any -> record<product: record<images: record<uploaded: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-session"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/product/($code)/images")
  let body = {user_id: $user_id, password: $password, image_data_base64: $image_data_base64, selected: $selected} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Product Image
#
# DELETE /api/v3/product/{code}/images/uploaded/{imgid}
# operationId: delete-api-v3-product-code-images-uploaded-imgid
export def "product-images-uploaded delete-api-v3-product-code-images-uploaded-imgid" [
  code: string
  imgid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "cookie-session"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/product/($code)/images/uploaded/($imgid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get canonical tags for a list of local tags
#
# GET /api/v3/taxonomy_canonicalize_tags
# operationId: get-api-v3-taxonomy-canonicalize-tags
export def "taxonomy-canonicalize-tags get-api-v3-taxonomy-canonicalize-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tagtype: string # The type of taxonomy to canonicalize tags for (e.g., ingredients, categories). (e.g. ingredients)
  --local-tags-list: string # A comma-separated list of local tags to canonicalize. (e.g. sucre,eau)
  --lc: string # 2-letter code of the language of the user. Used for localizing some fields in returned values. If not passed, the language may be inferred by the subdomain of the request.  (e.g. fr)
]: nothing -> record<canonical_tags_list: string> {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tagtype" $tagtype "scalar") (serialize-qp "local_tags_list" $local_tags_list "scalar") (serialize-qp "lc" $lc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/taxonomy_canonicalize_tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get display tags in a specific language for a list of taxonomy tags
#
# GET /api/v3/taxonomy_display_tags
# operationId: get-api-v3-taxonomy-display-tags
export def "taxonomy-display-tags get-api-v3-taxonomy-display-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tagtype: string # The type of taxonomy to retrieve display tags for (e.g., ingredients, categories). (e.g. ingredients)
  --canonical-tags-list: string # A comma-separated list of canonical taxonomy tags to retrieve display tags for. (e.g. en:sugar,en:water)
  --lc: string # 2-letter code of the language to return display tags in.  (e.g. fr)
]: nothing -> record<display_tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tagtype" $tagtype "scalar") (serialize-qp "canonical_tags_list" $canonical_tags_list "scalar") (serialize-qp "lc" $lc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/taxonomy_display_tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Taxonomy Suggestions
#
# GET /api/v3/taxonomy_suggestions
# operationId: get-api-v3-taxonomy_suggestions-taxonomy
export def "taxonomy-suggestions suggestions-taxonomy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --string: string # Optional string used to filter suggestions (useful for autocomplete).  If passed, suggestions starting with the string will be returned first, followed by suggestions matching the string at the beginning of a word, and suggestions matching the string inside a word. (e.g. pe)
  --categories: string # Comma separated list of categories tags (e.g. "en:fats,en:unsalted-butters" or categories names in the language indicated by the "lc" field (e.g. "graisses, beurres salés" in French) (e.g. yougurts)
  --shape: string # Shape of packaging component (tag identified in the packaging_shapes taxonomy, or plain text tag name in the language indicated by the "lc" field) (e.g. bottle)
  --limit: string # Maximum number of suggestions. Default is 25, max is 400.
  --get-synonyms: string # Whether or not to include "matched_synonyms" in the response. Set to 1 to include.
  --term: string # Alias for the "string" parameter provided for backward compatibility. "string" takes precedence.
]: nothing -> record<suggestions: list<string>, matched_synonyms: record> {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "string" $string "scalar") (serialize-qp "categories" $categories "scalar") (serialize-qp "shape" $shape "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "get_synonyms" $get_synonyms "scalar") (serialize-qp "term" $term "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/taxonomy_suggestions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tag Knowledge Panels
#
# GET /api/v3/tag/{tagtype}/{tag_or_tagid}
# operationId: get-api-v3-tag-tagtype-tag_or_tagid
export def "tag tagid" [
  tagtype: string
  tag_or_tagid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<tagtype: string, tagid: string, tag: record<tagid: string, tagtype: string, knowledge_panels: any>> {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/tag/($tagtype)/($tag_or_tagid)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revert Product to Previous Revision
#
# POST /api/v3/product_revert
# operationId: post-api-v3-product_revert
export def "product-revert revert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string # Barcode of the product
  --rev: int # Revision number to revert to
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-session"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/product_revert")
  let body = {code: $code, rev: $rev} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List external knowledge panel sources (JSON)
#
# GET /api/v3/external_sources
# operationId: get-api-v3-external-sources
export def "external-sources get-api-v3-external-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<external_sources: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/external_sources")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get List of Preference Importance Values
#
# GET /api/v3/preferences
# operationId: get-api-v3-preferences
export def "preferences get-api-v3-preferences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<preferences: table<id: string, name: string, factor: int, minimum_match: int>> {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/preferences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get List of Attribute Groups and Attributes
#
# GET /api/v3.4/attribute_groups
# operationId: get-api-v3-4-attribute-groups
export def "v34-attribute-groups get-api-v3-4-attribute-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attribute_groups: table<id: string, name: string, warning: string, attributes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3.4/attribute_groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
