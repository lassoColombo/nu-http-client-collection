# Auto-generated client for Wordnik v4.0
# Source: https://api.apis.guru/v2/specs/wordnik.com/4.0/openapi.json
# Auth: --token flag or $env.WORDNIK_TOKEN

const BASE_URL = "https://api.wordnik.com/v4"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o WORDNIK_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-api_key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "api_key")=(encode-path-segment $token_val)", location: "query"} }
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

def base-url-completer [] { ["https://api.wordnik.com/v4"] }
def auth-scheme-completer [] { ["query-api_key"] }

# Completers for enum parameters
def use-canonical-completer [] { ["false" "true"] }
def part-of-speech-completer [] { ["abbreviation" "adjective" "adverb" "affix" "article" "auxiliary-verb" "conjunction" "definite-article" "family-name" "given-name" "idiom" "imperative" "interjection" "noun" "noun-plural" "noun-posessive" "past-participle" "phrasal-prefix" "preposition" "pronoun" "proper-noun" "proper-noun-plural" "proper-noun-posessive" "suffix" "verb" "verb-intransitive" "verb-transitive"] }
def source-dictionaries-completer [] { ["ahd-5" "all" "century" "webster" "wiktionary" "wordnet"] }
def include-tags-completer [] { ["false" "true"] }
def include-duplicates-completer [] { ["false" "true"] }
def source-dictionary-completer [] { ["ahd-5" "century" "webster" "wiktionary" "wordnet"] }
def source-dictionary-completer-1 [] { ["ahd-5" "century" "cmu" "macmillan" "webster" "wiktionary" "wordnet"] }
def type-format-completer [] { ["IPA" "ahd-5" "arpabet" "gcide-diacritical"] }
def relationship-types-completer [] { ["antonym" "cross-reference" "equivalent" "etymologically-related-term" "form" "has_topic" "hypernym" "hyponym" "inflected-form" "primary" "related-word" "rhyme" "same-context" "synonym" "variant" "verb-form" "verb-stem"] }
def sort-by-completer [] { ["alpha" "count"] }
def sort-order-completer [] { ["asc" "desc"] }
def include-source-dictionaries-completer [] { ["ahd-5" "century" "cmu" "macmillan" "webster" "wiktionary" "wordnet"] }
def exclude-source-dictionaries-completer [] { ["ahd-5" "century" "cmu" "macmillan" "webster" "wiktionary" "wordnet"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "word-json-audio get" } } | get name | first)
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

# Fetches audio metadata for a word.
#
# GET /word.json/{word}/audio
# operationId: getAudio
export def "word-json-audio get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --use-canonical: string@use-canonical-completer # If true will try to return the correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
  --limit: int # Maximum number of results to return (format: int32, default: 50)
]: nothing -> table<attributionText: string, attributionUrl: string, audioType: string, commentCount: int, createdAt: string, createdBy: string, description: string, duration: float, fileUrl: string, id: int, voteAverage: float, voteCount: int, voteWeightedAverage: float, word: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let qp = [(serialize-qp "useCanonical" $use_canonical "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({word: (encode-path-segment $word)} | format pattern "/word.json/{word}/audio") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"useCanonical": $use_canonical, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Return definitions for a word
#
# GET /word.json/{word}/definitions
# operationId: getDefinitions
export def "word-json-definitions get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of results to return (format: int32, default: 200)
  --part-of-speech: string@part-of-speech-completer # CSV list of part-of-speech types
  --include-related: string # Return related words with definitions (default: false)
  --source-dictionaries: list<string>@source-dictionaries-completer # Source dictionary to return definitions from. If 'all' is received, results are returned from all sources. If multiple values are received (e.g. 'century,wiktionary'), results are returned from the first specified dictionary that has definitions. If left blank, results are returned from the first dictionary that has definitions. By default, dictionaries are searched in this order: ahd-5, wiktionary, webster, century, wordnet
  --use-canonical: string@use-canonical-completer # If true will try to return the correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
  --include-tags: string@include-tags-completer # Return a closed set of XML tags in response (default: false)
]: nothing -> table<attributionText: string, attributionUrl: string, citations: list<any>, exampleUses: list<any>, extendedText: string, labels: list<any>, notes: list<any>, partOfSpeech: string, relatedWords: list<any>, score: float, seqString: string, sequence: string, sourceDictionary: string, text: string, textProns: list<any>, word: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "partOfSpeech" $part_of_speech "scalar") (serialize-qp "includeRelated" $include_related "scalar") (serialize-qp "sourceDictionaries" $source_dictionaries "csv") (serialize-qp "useCanonical" $use_canonical "scalar") (serialize-qp "includeTags" $include_tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({word: (encode-path-segment $word)} | format pattern "/word.json/{word}/definitions") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "partOfSpeech": $part_of_speech, "includeRelated": $include_related, "sourceDictionaries": $source_dictionaries, "useCanonical": $use_canonical, "includeTags": $include_tags} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fetches etymology data
#
# GET /word.json/{word}/etymologies
# operationId: getEtymologies
export def "word-json-etymologies get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --use-canonical: string@use-canonical-completer # If true will try to return the correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let qp = [(serialize-qp "useCanonical" $use_canonical "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({word: (encode-path-segment $word)} | format pattern "/word.json/{word}/etymologies") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"useCanonical": $use_canonical} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns examples for a word
#
# GET /word.json/{word}/examples
# operationId: getExamples
export def "word-json-examples get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-duplicates: string@include-duplicates-completer # Show duplicate examples from different sources (default: false)
  --use-canonical: string@use-canonical-completer # If true will try to return the correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
  --skip: int # Results to skip (format: int32, default: 0)
  --limit: int # Maximum number of results to return (format: int32, default: 5)
]: nothing -> record<examples: list<any>, facets: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let qp = [(serialize-qp "includeDuplicates" $include_duplicates "scalar") (serialize-qp "useCanonical" $use_canonical "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({word: (encode-path-segment $word)} | format pattern "/word.json/{word}/examples") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"includeDuplicates": $include_duplicates, "useCanonical": $use_canonical, "skip": $skip, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns word usage over time
#
# GET /word.json/{word}/frequency
# operationId: getWordFrequency
export def "word-json-frequency get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --use-canonical: string@use-canonical-completer # If true will try to return the correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
  --start-year: int # Starting Year (format: int32, default: 1800)
  --end-year: int # Ending Year (format: int32, default: 2012)
]: nothing -> record<frequency: list<any>, frequencyString: string, totalCount: int, unknownYearCount: int, word: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let qp = [(serialize-qp "useCanonical" $use_canonical "scalar") (serialize-qp "startYear" $start_year "scalar") (serialize-qp "endYear" $end_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({word: (encode-path-segment $word)} | format pattern "/word.json/{word}/frequency") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"useCanonical": $use_canonical, "startYear": $start_year, "endYear": $end_year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns syllable information for a word
#
# GET /word.json/{word}/hyphenation
# operationId: getHyphenation
export def "word-json-hyphenation get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --use-canonical: string@use-canonical-completer # If true will try to return a correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
  --source-dictionary: string@source-dictionary-completer # Get from a single dictionary. Valid options: ahd-5, century, wiktionary, webster, and wordnet.
  --limit: int # Maximum number of results to return (format: int32, default: 50)
]: nothing -> table<seq: int, text: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let qp = [(serialize-qp "useCanonical" $use_canonical "scalar") (serialize-qp "sourceDictionary" $source_dictionary "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({word: (encode-path-segment $word)} | format pattern "/word.json/{word}/hyphenation") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"useCanonical": $use_canonical, "sourceDictionary": $source_dictionary, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fetches bi-gram phrases for a word
#
# GET /word.json/{word}/phrases
# operationId: getPhrases
export def "word-json-phrases get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of results to return (format: int32, default: 5)
  --wlmi: int # Minimum WLMI for the phrase (format: int32, default: 0)
  --use-canonical: string@use-canonical-completer # If true will try to return the correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
]: nothing -> table<count: int, gram1: string, gram2: string, mi: float, wlmi: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "wlmi" $wlmi "scalar") (serialize-qp "useCanonical" $use_canonical "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({word: (encode-path-segment $word)} | format pattern "/word.json/{word}/phrases") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "wlmi": $wlmi, "useCanonical": $use_canonical} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns text pronunciations for a given word
#
# GET /word.json/{word}/pronunciations
# operationId: getTextPronunciations
export def "word-json-pronunciations get-text" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --use-canonical: string@use-canonical-completer # If true will try to return a correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
  --source-dictionary: string@source-dictionary-completer-1 # Get from a single dictionary
  --type-format: string@type-format-completer # Text pronunciation type
  --limit: int # Maximum number of results to return (format: int32, default: 50)
]: nothing -> table<raw: string, rawType: string, seq: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let qp = [(serialize-qp "useCanonical" $use_canonical "scalar") (serialize-qp "sourceDictionary" $source_dictionary "scalar") (serialize-qp "typeFormat" $type_format "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({word: (encode-path-segment $word)} | format pattern "/word.json/{word}/pronunciations") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"useCanonical": $use_canonical, "sourceDictionary": $source_dictionary, "typeFormat": $type_format, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Given a word as a string, returns relationships from the Word Graph
#
# GET /word.json/{word}/relatedWords
# operationId: getRelatedWords
export def "word-json-related-words get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --use-canonical: string@use-canonical-completer # If true will try to return the correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
  --relationship-types: string@relationship-types-completer # Limits the total results per type of relationship type
  --limit-per-relationship-type: int # Restrict to the supplied relationship types (format: int32, default: 10)
]: nothing -> table<gram: string, label1: string, label2: string, label3: string, label4: string, relationshipType: string, words: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let qp = [(serialize-qp "useCanonical" $use_canonical "scalar") (serialize-qp "relationshipTypes" $relationship_types "scalar") (serialize-qp "limitPerRelationshipType" $limit_per_relationship_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({word: (encode-path-segment $word)} | format pattern "/word.json/{word}/relatedWords") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"useCanonical": $use_canonical, "relationshipTypes": $relationship_types, "limitPerRelationshipType": $limit_per_relationship_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the Scrabble score for a word
#
# GET /word.json/{word}/scrabbleScore
# operationId: getScrabbleScore
export def "word-json-scrabble-score get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<int, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let full_url = (build-url $base ({word: (encode-path-segment $word)} | format pattern "/word.json/{word}/scrabbleScore") $auth.query)
  let accept_val = "*/*"
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

# Returns a top example for a word
#
# GET /word.json/{word}/topExample
# operationId: getTopExample
export def "word-json-top-example get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --use-canonical: string@use-canonical-completer # If true will try to return the correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
]: nothing -> record<documentId: int, exampleId: int, id: int, provider: record<id: int, name: string>, rating: float, score: record<baseWordScore: float, docTermCount: int, id: int, lemma: string, partOfSpeech: string, position: int, score: float, sentenceId: int, stopword: bool, word: string, wordType: string>, sentence: record<display: string, documentMetadataId: int, hasScoredWords: bool, id: int, rating: int, scoredWords: list<any>>, text: string, title: string, url: string, word: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let qp = [(serialize-qp "useCanonical" $use_canonical "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({word: (encode-path-segment $word)} | format pattern "/word.json/{word}/topExample") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"useCanonical": $use_canonical} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a single random WordObject
#
# GET /words.json/randomWord
# operationId: getRandomWord
export def "words-json-random-word get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --has-dictionary-def: string # Only return words with dictionary definitions (default: true)
  --include-part-of-speech: string # CSV part-of-speech values to include (allowable values are noun, adjective, verb, adverb, interjection, pronoun, preposition, abbreviation, affix, article, auxiliary-verb, conjunction, definite-article, family-name, given-name, idiom, imperative, noun-plural, noun-posessive, past-participle, phrasal-prefix, proper-noun, proper-noun-plural, proper-noun-posessive, suffix, verb-intransitive, verb-transitive)
  --exclude-part-of-speech: string # CSV part-of-speech values to exclude (allowable values are noun, adjective, verb, adverb, interjection, pronoun, preposition, abbreviation, affix, article, auxiliary-verb, conjunction, definite-article, family-name, given-name, idiom, imperative, noun-plural, noun-posessive, past-participle, phrasal-prefix, proper-noun, proper-noun-plural, proper-noun-posessive, suffix, verb-intransitive, verb-transitive)
  --min-corpus-count: int # Minimum corpus frequency for terms (format: int32, default: 0)
  --max-corpus-count: int # Maximum corpus frequency for terms (format: int32, default: -1)
  --min-dictionary-count: int # Minimum dictionary count (format: int32, default: 1)
  --max-dictionary-count: int # Maximum dictionary count (format: int32, default: -1)
  --min-length: int # Minimum word length (format: int32, default: 5)
  --max-length: int # Maximum word length (format: int32, default: -1)
]: nothing -> record<canonicalForm: string, id: int, originalWord: string, suggestions: list<string>, vulgar: string, word: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hasDictionaryDef" $has_dictionary_def "scalar") (serialize-qp "includePartOfSpeech" $include_part_of_speech "scalar") (serialize-qp "excludePartOfSpeech" $exclude_part_of_speech "scalar") (serialize-qp "minCorpusCount" $min_corpus_count "scalar") (serialize-qp "maxCorpusCount" $max_corpus_count "scalar") (serialize-qp "minDictionaryCount" $min_dictionary_count "scalar") (serialize-qp "maxDictionaryCount" $max_dictionary_count "scalar") (serialize-qp "minLength" $min_length "scalar") (serialize-qp "maxLength" $max_length "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/words.json/randomWord" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"hasDictionaryDef": $has_dictionary_def, "includePartOfSpeech": $include_part_of_speech, "excludePartOfSpeech": $exclude_part_of_speech, "minCorpusCount": $min_corpus_count, "maxCorpusCount": $max_corpus_count, "minDictionaryCount": $min_dictionary_count, "maxDictionaryCount": $max_dictionary_count, "minLength": $min_length, "maxLength": $max_length} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns an array of random WordObjects
#
# GET /words.json/randomWords
# operationId: getRandomWords
export def "words-json-random-words get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --has-dictionary-def: string # Only return words with dictionary definitions (default: true)
  --include-part-of-speech: string # CSV part-of-speech values to include (allowable values are noun, adjective, verb, adverb, interjection, pronoun, preposition, abbreviation, affix, article, auxiliary-verb, conjunction, definite-article, family-name, given-name, idiom, imperative, noun-plural, noun-posessive, past-participle, phrasal-prefix, proper-noun, proper-noun-plural, proper-noun-posessive, suffix, verb-intransitive, verb-transitive)
  --exclude-part-of-speech: string # CSV part-of-speech values to exclude (allowable values are noun, adjective, verb, adverb, interjection, pronoun, preposition, abbreviation, affix, article, auxiliary-verb, conjunction, definite-article, family-name, given-name, idiom, imperative, noun-plural, noun-posessive, past-participle, phrasal-prefix, proper-noun, proper-noun-plural, proper-noun-posessive, suffix, verb-intransitive, verb-transitive)
  --min-corpus-count: int # Minimum corpus frequency for terms (format: int32, default: 0)
  --max-corpus-count: int # Maximum corpus frequency for terms (format: int32, default: -1)
  --min-dictionary-count: int # Minimum dictionary count (format: int32, default: 1)
  --max-dictionary-count: int # Maximum dictionary count (format: int32, default: -1)
  --min-length: int # Minimum word length (format: int32, default: 5)
  --max-length: int # Maximum word length (format: int32, default: -1)
  --sort-by: string@sort-by-completer # Attribute to sort by
  --sort-order: string@sort-order-completer # Sort direction
  --limit: int # Maximum number of results to return (format: int32, default: 10)
]: nothing -> table<canonicalForm: string, id: int, originalWord: string, suggestions: list<string>, vulgar: string, word: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hasDictionaryDef" $has_dictionary_def "scalar") (serialize-qp "includePartOfSpeech" $include_part_of_speech "scalar") (serialize-qp "excludePartOfSpeech" $exclude_part_of_speech "scalar") (serialize-qp "minCorpusCount" $min_corpus_count "scalar") (serialize-qp "maxCorpusCount" $max_corpus_count "scalar") (serialize-qp "minDictionaryCount" $min_dictionary_count "scalar") (serialize-qp "maxDictionaryCount" $max_dictionary_count "scalar") (serialize-qp "minLength" $min_length "scalar") (serialize-qp "maxLength" $max_length "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "sortOrder" $sort_order "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/words.json/randomWords" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"hasDictionaryDef": $has_dictionary_def, "includePartOfSpeech": $include_part_of_speech, "excludePartOfSpeech": $exclude_part_of_speech, "minCorpusCount": $min_corpus_count, "maxCorpusCount": $max_corpus_count, "minDictionaryCount": $min_dictionary_count, "maxDictionaryCount": $max_dictionary_count, "minLength": $min_length, "maxLength": $max_length, "sortBy": $sort_by, "sortOrder": $sort_order, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Reverse dictionary search
#
# GET /words.json/reverseDictionary
# operationId: reverseDictionary
export def "words-json-reverse-dictionary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Search term
  --find-sense-for-word: string # Restricts words and finds closest sense
  --include-source-dictionaries: string@include-source-dictionaries-completer # Only include these comma-delimited source dictionaries
  --exclude-source-dictionaries: string@exclude-source-dictionaries-completer # Exclude these comma-delimited source dictionaries
  --include-part-of-speech: string # Only include these comma-delimited parts of speech (allowable values are noun, adjective, verb, adverb, interjection, pronoun, preposition, abbreviation, affix, article, auxiliary-verb, conjunction, definite-article, family-name, given-name, idiom, imperative, noun-plural, noun-posessive, past-participle, phrasal-prefix, proper-noun, proper-noun-plural, proper-noun-posessive, suffix, verb-intransitive, verb-transitive)
  --exclude-part-of-speech: string # Exclude these comma-delimited parts of speech (allowable values are noun, adjective, verb, adverb, interjection, pronoun, preposition, abbreviation, affix, article, auxiliary-verb, conjunction, definite-article, family-name, given-name, idiom, imperative, noun-plural, noun-posessive, past-participle, phrasal-prefix, proper-noun, proper-noun-plural, proper-noun-posessive, suffix, verb-intransitive, verb-transitive)
  --min-corpus-count: int # Minimum corpus frequency for terms (format: int32, default: 5)
  --max-corpus-count: int # Maximum corpus frequency for terms (format: int32, default: -1)
  --min-length: int # Minimum word length (format: int32, default: 1)
  --max-length: int # Maximum word length (format: int32, default: -1)
  --expand-terms: string # Expand terms
  --include-tags: string@include-tags-completer # Return a closed set of XML tags in response (default: false)
  --sort-by: string@sort-by-completer # Attribute to sort by
  --sort-order: string@sort-order-completer # Sort direction
  --skip: string # Results to skip (default: 0)
  --limit: int # Maximum number of results to return (format: int32, default: 10)
]: nothing -> record<results: list<any>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "findSenseForWord" $find_sense_for_word "scalar") (serialize-qp "includeSourceDictionaries" $include_source_dictionaries "scalar") (serialize-qp "excludeSourceDictionaries" $exclude_source_dictionaries "scalar") (serialize-qp "includePartOfSpeech" $include_part_of_speech "scalar") (serialize-qp "excludePartOfSpeech" $exclude_part_of_speech "scalar") (serialize-qp "minCorpusCount" $min_corpus_count "scalar") (serialize-qp "maxCorpusCount" $max_corpus_count "scalar") (serialize-qp "minLength" $min_length "scalar") (serialize-qp "maxLength" $max_length "scalar") (serialize-qp "expandTerms" $expand_terms "scalar") (serialize-qp "includeTags" $include_tags "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "sortOrder" $sort_order "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/words.json/reverseDictionary" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query, "findSenseForWord": $find_sense_for_word, "includeSourceDictionaries": $include_source_dictionaries, "excludeSourceDictionaries": $exclude_source_dictionaries, "includePartOfSpeech": $include_part_of_speech, "excludePartOfSpeech": $exclude_part_of_speech, "minCorpusCount": $min_corpus_count, "maxCorpusCount": $max_corpus_count, "minLength": $min_length, "maxLength": $max_length, "expandTerms": $expand_terms, "includeTags": $include_tags, "sortBy": $sort_by, "sortOrder": $sort_order, "skip": $skip, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Searches words
#
# GET /words.json/search/{query}
# operationId: searchWords
export def "words-json-search list" [
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
  --allow-regex: string # Search term is a Regular Expression (default: false)
  --case-sensitive: string # Search case sensitive (default: true)
  --include-part-of-speech: string # Only include these comma-delimited parts of speech (allowable values are noun, adjective, verb, adverb, interjection, pronoun, preposition, abbreviation, affix, article, auxiliary-verb, conjunction, definite-article, family-name, given-name, idiom, imperative, noun-plural, noun-posessive, past-participle, phrasal-prefix, proper-noun, proper-noun-plural, proper-noun-posessive, suffix, verb-intransitive, verb-transitive)
  --exclude-part-of-speech: string # Exclude these comma-delimited parts of speech (allowable values are noun, adjective, verb, adverb, interjection, pronoun, preposition, abbreviation, affix, article, auxiliary-verb, conjunction, definite-article, family-name, given-name, idiom, imperative, noun-plural, noun-posessive, past-participle, phrasal-prefix, proper-noun, proper-noun-plural, proper-noun-posessive, suffix, verb-intransitive, verb-transitive)
  --min-corpus-count: int # Minimum corpus frequency for terms (format: int32, default: 5)
  --max-corpus-count: int # Maximum corpus frequency for terms (format: int32, default: -1)
  --min-dictionary-count: int # Minimum number of dictionary entries for words returned (format: int32, default: 1)
  --max-dictionary-count: int # Maximum dictionary definition count (format: int32, default: -1)
  --min-length: int # Minimum word length (format: int32, default: 1)
  --max-length: int # Maximum word length (format: int32, default: -1)
  --skip: int # Results to skip (format: int32, default: 0)
  --limit: int # Maximum number of results to return (format: int32, default: 10)
]: nothing -> record<searchResults: list<any>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($query | is-empty) { error make --unspanned { msg: "path parameter 'query' must be non-empty" } }
  let qp = [(serialize-qp "allowRegex" $allow_regex "scalar") (serialize-qp "caseSensitive" $case_sensitive "scalar") (serialize-qp "includePartOfSpeech" $include_part_of_speech "scalar") (serialize-qp "excludePartOfSpeech" $exclude_part_of_speech "scalar") (serialize-qp "minCorpusCount" $min_corpus_count "scalar") (serialize-qp "maxCorpusCount" $max_corpus_count "scalar") (serialize-qp "minDictionaryCount" $min_dictionary_count "scalar") (serialize-qp "maxDictionaryCount" $max_dictionary_count "scalar") (serialize-qp "minLength" $min_length "scalar") (serialize-qp "maxLength" $max_length "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({query: (encode-path-segment $query)} | format pattern "/words.json/search/{query}") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"allowRegex": $allow_regex, "caseSensitive": $case_sensitive, "includePartOfSpeech": $include_part_of_speech, "excludePartOfSpeech": $exclude_part_of_speech, "minCorpusCount": $min_corpus_count, "maxCorpusCount": $max_corpus_count, "minDictionaryCount": $min_dictionary_count, "maxDictionaryCount": $max_dictionary_count, "minLength": $min_length, "maxLength": $max_length, "skip": $skip, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a specific WordOfTheDay
#
# GET /words.json/wordOfTheDay
# operationId: getWordOfTheDay
export def "words-json-word-of-the-day get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Fetches by date in yyyy-MM-dd
]: nothing -> record<category: string, contentProvider: record<id: int, name: string>, createdAt: string, createdBy: string, definitions: list<any>, examples: list<any>, htmlExtra: string, id: int, note: string, parentId: string, publishDate: string, word: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/words.json/wordOfTheDay" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"date": $date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
