# Auto-generated client for Kagi API v1
# Source: https://kagi.com/api/docs/_spec/openapi.yaml
# Auth: --token flag or $env.KAGI_API_TOKEN

const BASE_URL = "https://kagi.com/api/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o KAGI_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://kagi.com/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def workflow-completer [] { ["images" "news" "podcasts" "search" "videos"] }
def format-completer [] { ["json" "markdown"] }
def accept-completer [] { ["application/json" "text/markdown"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "search search" } } | get name | first)
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

# Perform a web search
#
# POST /search
# operationId: search
# --lens shape: {sites_included?: list, sites_excluded?: list, keywords_included?: list, keywords_excluded?: list, file_type?: string, time_after?: string, time_before?: string, time_relative?: "day"|"week"|"month", search_region?: string}
# --filters shape: {region?: string, after?: string, before?: string}
# --extract shape: {count?: int, timeout?: float}
# --personalizations shape: {domains?: list, regexes?: list}
export def "search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: string # Search query to run.
  --workflow: string@workflow-completer # Type of results to return. (default: search)
  --format: string@format-completer # **(EXPERIMENTAL)** Format to serialize the API response as. The exact contents and structure of markdown output is still being worked on - please send your feedback! (default: json)
  --lens-id: string # Lens to apply to the search. Can be a built-in lens's identifier or a lens ID as shown on https://kagi.com/settings/lenses when a lens is set to be shareable. Can be just the ID portion of the URL (`https://kagi.com/lenses/ID`) or the full URL.
  --lens: record # Inline description of a lens to apply to the search. Options supplied by the lens take precedence over those supplied by the user in their search terms (e.g., `site:` operators), allowing you to restrict the scope of the search to return more relevant results in specific applications. — shape: {sites_included?: list, sites_excluded?: list, keywords_included?: list, keywords_excluded?: list, file_type?: string, time_after?: string, time_before?: string, time_relative?: "day"|"week"|"month", search_region?: string}
  --timeout: float # Number of seconds to allow for collecting search results. Lower values will return results more quickly, but may be lower quality or inconsistent between calls. If omitted, will use the latest recommended value by Kagi.
  --page: int # Page number for paginated results. Must be between 1 and 10.
  --limit: int # Maximum number of results to return. Must be between 1 and 1024.  **NOTE:** This does not change the amount of results requested, it only limits the maximum amount returned. If omitted, the API always gives you the most results we can get in a single pass.
  --filters: record # Filters to apply to search results for more targeted queries.  **NOTE:** Any parameter here that overlaps with lenses will take priority over the lens. — shape: {region?: string, after?: string, before?: string}
  --extract: record # Configuration for extracting page content from search results. When provided, the API will fetch and extract the content from the specified number of result pages.  The resulting page markdown will update the value of the `snippet` field on the respective result item.  **NOTE:** Use of this option incurs additional cost, billed at your account's rate for the Extract API based on the number of units requested. You will not be charged if there were no results to extract. — shape: {count?: int, timeout?: float}
  --safe-search: string@bool-completer # Whether safe search is enabled, omitting potentially NSFW content. (default: true)
  --personalizations: record # Personalization rules to customize search result ranking. Allows specifying domain biases and regex-based replacements. — shape: {domains?: list, regexes?: list}
]: any -> record<meta: record<trace: string, node: string, ms: int>, data: record<search: list<record>, image: list<record>, video: list<record>, podcast: list<record>, podcast_creator: list<record>, news: list<record>, adjacent_question: list<record>, direct_answer: list<record>, interesting_news: list<record>, interesting_finds: list<record>, infobox: list<record>, code: list<record>, package_tracking: list<record>, public_records: list<record>, weather: list<record>, related_search: list<record>, listicle: list<record>, web_archive: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search")
  let body = {query: $body_query, workflow: $workflow, format: $format, lens_id: $lens_id, lens: $lens, timeout: $timeout, page: $page, limit: $limit, filters: $filters, extract: $extract, safe_search: $safe_search, personalizations: $personalizations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Extract page content as markdown from URLs
#
# POST /extract
# operationId: extractContent
# --pages item shape: {url: string}
export def "extract extractContent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  pages: list # Array of pages to extract content from. Must contain 1-10 URLs. Each URL must be a valid HTTPS URL. — item shape: {url: string}
  --timeout: float # Optional timeout in seconds for the extraction operation. Out of range values will be clamped back within range.  All URLs are fetched concurrently. This timeout applies a time budget for the entire bulk fetch operation.  (format: float, e.g. 1.337)
  --format: string@format-completer # **(EXPERIMENTAL)** Format to serialize the API response as. The exact contents and structure of markdown output is still being worked on - please send your feedback! (default: json)
]: any -> record<meta: record<trace: string, node: string, ms: int>, data: table<url: string, markdown: string, error: string>, errors: table<code: string, url: string, message: string, location: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/extract")
  let body = {pages: $pages, timeout: $timeout, format: $format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
