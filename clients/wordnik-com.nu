# Auto-generated client for Wordnik v4.0
# Source: https://api.apis.guru/v2/specs/wordnik.com/4.0/openapi.json
# Auth: --token flag or $env.WORDNIK_TOKEN

const BASE_URL = "https://api.wordnik.com/v4"
const DEFAULT_AUTH = "query-api_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WORDNIK_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-api_key" => { {headers: {}, query: $"api_key=($token_val)"} }
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

def base-url-completer [] { ["https://api.wordnik.com/v4"] }
def auth-scheme-completer [] { ["query-api_key"] }

# Completers for enum parameters
def useCanonical-completer [] { ["false" "true"] }
def partOfSpeech-completer [] { ["abbreviation" "adjective" "adverb" "affix" "article" "auxiliary-verb" "conjunction" "definite-article" "family-name" "given-name" "idiom" "imperative" "interjection" "noun" "noun-plural" "noun-posessive" "past-participle" "phrasal-prefix" "preposition" "pronoun" "proper-noun" "proper-noun-plural" "proper-noun-posessive" "suffix" "verb" "verb-intransitive" "verb-transitive"] }
def sourceDictionaries-completer [] { ["ahd-5" "all" "century" "webster" "wiktionary" "wordnet"] }
def includeTags-completer [] { ["false" "true"] }
def includeDuplicates-completer [] { ["false" "true"] }
def sourceDictionary-completer [] { ["ahd-5" "century" "webster" "wiktionary" "wordnet"] }
def sourceDictionary-completer-1 [] { ["ahd-5" "century" "cmu" "macmillan" "webster" "wiktionary" "wordnet"] }
def typeFormat-completer [] { ["IPA" "ahd-5" "arpabet" "gcide-diacritical"] }
def relationshipTypes-completer [] { ["antonym" "cross-reference" "equivalent" "etymologically-related-term" "form" "has_topic" "hypernym" "hyponym" "inflected-form" "primary" "related-word" "rhyme" "same-context" "synonym" "variant" "verb-form" "verb-stem"] }
def sortBy-completer [] { ["alpha" "count"] }
def sortOrder-completer [] { ["asc" "desc"] }
def includeSourceDictionaries-completer [] { ["ahd-5" "century" "cmu" "macmillan" "webster" "wiktionary" "wordnet"] }
def excludeSourceDictionaries-completer [] { ["ahd-5" "century" "cmu" "macmillan" "webster" "wiktionary" "wordnet"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "wordjson-audio get" } } | get name | first)
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
export def "wordjson-audio get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --useCanonical: string@useCanonical-completer # If true will try to return the correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
  --limit: int # Maximum number of results to return (format: int32, default: 50)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "useCanonical" $useCanonical "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/word.json/($word)/audio" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return definitions for a word
#
# GET /word.json/{word}/definitions
# operationId: getDefinitions
export def "wordjson-definitions get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of results to return (format: int32, default: 200)
  --partOfSpeech: string@partOfSpeech-completer # CSV list of part-of-speech types
  --includeRelated: string # Return related words with definitions (default: false)
  --sourceDictionaries: list@sourceDictionaries-completer # Source dictionary to return definitions from.  If 'all' is received, results are returned from all sources. If multiple values are received (e.g. 'century,wiktionary'), results are returned from the first specified dictionary that has definitions. If left blank, results are returned from the first dictionary that has definitions. By default, dictionaries are searched in this order: ahd-5, wiktionary, webster, century, wordnet
  --useCanonical: string@useCanonical-completer # If true will try to return the correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
  --includeTags: string@includeTags-completer # Return a closed set of XML tags in response (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "partOfSpeech" $partOfSpeech "scalar") (serialize-qp "includeRelated" $includeRelated "scalar") (serialize-qp "sourceDictionaries" $sourceDictionaries "csv") (serialize-qp "useCanonical" $useCanonical "scalar") (serialize-qp "includeTags" $includeTags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/word.json/($word)/definitions" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches etymology data
#
# GET /word.json/{word}/etymologies
# operationId: getEtymologies
export def "wordjson-etymologies get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --useCanonical: string@useCanonical-completer # If true will try to return the correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "useCanonical" $useCanonical "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/word.json/($word)/etymologies" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns examples for a word
#
# GET /word.json/{word}/examples
# operationId: getExamples
export def "wordjson-examples get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeDuplicates: string@includeDuplicates-completer # Show duplicate examples from different sources (default: false)
  --useCanonical: string@useCanonical-completer # If true will try to return the correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
  --skip: int # Results to skip (format: int32, default: 0)
  --limit: int # Maximum number of results to return (format: int32, default: 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeDuplicates" $includeDuplicates "scalar") (serialize-qp "useCanonical" $useCanonical "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/word.json/($word)/examples" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns word usage over time
#
# GET /word.json/{word}/frequency
# operationId: getWordFrequency
export def "wordjson-frequency get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --useCanonical: string@useCanonical-completer # If true will try to return the correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
  --startYear: int # Starting Year (format: int32, default: 1800)
  --endYear: int # Ending Year (format: int32, default: 2012)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "useCanonical" $useCanonical "scalar") (serialize-qp "startYear" $startYear "scalar") (serialize-qp "endYear" $endYear "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/word.json/($word)/frequency" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns syllable information for a word
#
# GET /word.json/{word}/hyphenation
# operationId: getHyphenation
export def "wordjson-hyphenation get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --useCanonical: string@useCanonical-completer # If true will try to return a correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
  --sourceDictionary: string@sourceDictionary-completer # Get from a single dictionary. Valid options: ahd-5, century, wiktionary, webster, and wordnet.
  --limit: int # Maximum number of results to return (format: int32, default: 50)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "useCanonical" $useCanonical "scalar") (serialize-qp "sourceDictionary" $sourceDictionary "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/word.json/($word)/hyphenation" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches bi-gram phrases for a word
#
# GET /word.json/{word}/phrases
# operationId: getPhrases
export def "wordjson-phrases get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of results to return (format: int32, default: 5)
  --wlmi: int # Minimum WLMI for the phrase (format: int32, default: 0)
  --useCanonical: string@useCanonical-completer # If true will try to return the correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "wlmi" $wlmi "scalar") (serialize-qp "useCanonical" $useCanonical "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/word.json/($word)/phrases" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns text pronunciations for a given word
#
# GET /word.json/{word}/pronunciations
# operationId: getTextPronunciations
export def "wordjson-pronunciations get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --useCanonical: string@useCanonical-completer # If true will try to return a correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
  --sourceDictionary: string@sourceDictionary-completer-1 # Get from a single dictionary
  --typeFormat: string@typeFormat-completer # Text pronunciation type
  --limit: int # Maximum number of results to return (format: int32, default: 50)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "useCanonical" $useCanonical "scalar") (serialize-qp "sourceDictionary" $sourceDictionary "scalar") (serialize-qp "typeFormat" $typeFormat "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/word.json/($word)/pronunciations" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Given a word as a string, returns relationships from the Word Graph
#
# GET /word.json/{word}/relatedWords
# operationId: getRelatedWords
export def "wordjson-related-words get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --useCanonical: string@useCanonical-completer # If true will try to return the correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
  --relationshipTypes: string@relationshipTypes-completer # Limits the total results per type of relationship type
  --limitPerRelationshipType: int # Restrict to the supplied relationship types (format: int32, default: 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "useCanonical" $useCanonical "scalar") (serialize-qp "relationshipTypes" $relationshipTypes "scalar") (serialize-qp "limitPerRelationshipType" $limitPerRelationshipType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/word.json/($word)/relatedWords" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the Scrabble score for a word
#
# GET /word.json/{word}/scrabbleScore
# operationId: getScrabbleScore
export def "wordjson-scrabble-score get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/word.json/($word)/scrabbleScore")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a top example for a word
#
# GET /word.json/{word}/topExample
# operationId: getTopExample
export def "wordjson-top-example get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --useCanonical: string@useCanonical-completer # If true will try to return the correct word root ('cats' -> 'cat'). If false returns exactly what was requested. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "useCanonical" $useCanonical "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/word.json/($word)/topExample" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a single random WordObject
#
# GET /words.json/randomWord
# operationId: getRandomWord
export def "wordsjson-random-word get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hasDictionaryDef: string # Only return words with dictionary definitions (default: true)
  --includePartOfSpeech: string # CSV part-of-speech values to include (allowable values are noun, adjective, verb, adverb, interjection, pronoun, preposition, abbreviation, affix, article, auxiliary-verb, conjunction, definite-article, family-name, given-name, idiom, imperative, noun-plural, noun-posessive, past-participle, phrasal-prefix, proper-noun, proper-noun-plural, proper-noun-posessive, suffix, verb-intransitive, verb-transitive)
  --excludePartOfSpeech: string # CSV part-of-speech values to exclude (allowable values are noun, adjective, verb, adverb, interjection, pronoun, preposition, abbreviation, affix, article, auxiliary-verb, conjunction, definite-article, family-name, given-name, idiom, imperative, noun-plural, noun-posessive, past-participle, phrasal-prefix, proper-noun, proper-noun-plural, proper-noun-posessive, suffix, verb-intransitive, verb-transitive)
  --minCorpusCount: int # Minimum corpus frequency for terms (format: int32, default: 0)
  --maxCorpusCount: int # Maximum corpus frequency for terms (format: int32, default: -1)
  --minDictionaryCount: int # Minimum dictionary count (format: int32, default: 1)
  --maxDictionaryCount: int # Maximum dictionary count (format: int32, default: -1)
  --minLength: int # Minimum word length (format: int32, default: 5)
  --maxLength: int # Maximum word length (format: int32, default: -1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hasDictionaryDef" $hasDictionaryDef "scalar") (serialize-qp "includePartOfSpeech" $includePartOfSpeech "scalar") (serialize-qp "excludePartOfSpeech" $excludePartOfSpeech "scalar") (serialize-qp "minCorpusCount" $minCorpusCount "scalar") (serialize-qp "maxCorpusCount" $maxCorpusCount "scalar") (serialize-qp "minDictionaryCount" $minDictionaryCount "scalar") (serialize-qp "maxDictionaryCount" $maxDictionaryCount "scalar") (serialize-qp "minLength" $minLength "scalar") (serialize-qp "maxLength" $maxLength "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/words.json/randomWord" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an array of random WordObjects
#
# GET /words.json/randomWords
# operationId: getRandomWords
export def "wordsjson-random-words get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hasDictionaryDef: string # Only return words with dictionary definitions (default: true)
  --includePartOfSpeech: string # CSV part-of-speech values to include (allowable values are noun, adjective, verb, adverb, interjection, pronoun, preposition, abbreviation, affix, article, auxiliary-verb, conjunction, definite-article, family-name, given-name, idiom, imperative, noun-plural, noun-posessive, past-participle, phrasal-prefix, proper-noun, proper-noun-plural, proper-noun-posessive, suffix, verb-intransitive, verb-transitive)
  --excludePartOfSpeech: string # CSV part-of-speech values to exclude (allowable values are noun, adjective, verb, adverb, interjection, pronoun, preposition, abbreviation, affix, article, auxiliary-verb, conjunction, definite-article, family-name, given-name, idiom, imperative, noun-plural, noun-posessive, past-participle, phrasal-prefix, proper-noun, proper-noun-plural, proper-noun-posessive, suffix, verb-intransitive, verb-transitive)
  --minCorpusCount: int # Minimum corpus frequency for terms (format: int32, default: 0)
  --maxCorpusCount: int # Maximum corpus frequency for terms (format: int32, default: -1)
  --minDictionaryCount: int # Minimum dictionary count (format: int32, default: 1)
  --maxDictionaryCount: int # Maximum dictionary count (format: int32, default: -1)
  --minLength: int # Minimum word length (format: int32, default: 5)
  --maxLength: int # Maximum word length (format: int32, default: -1)
  --sortBy: string@sortBy-completer # Attribute to sort by
  --sortOrder: string@sortOrder-completer # Sort direction
  --limit: int # Maximum number of results to return (format: int32, default: 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hasDictionaryDef" $hasDictionaryDef "scalar") (serialize-qp "includePartOfSpeech" $includePartOfSpeech "scalar") (serialize-qp "excludePartOfSpeech" $excludePartOfSpeech "scalar") (serialize-qp "minCorpusCount" $minCorpusCount "scalar") (serialize-qp "maxCorpusCount" $maxCorpusCount "scalar") (serialize-qp "minDictionaryCount" $minDictionaryCount "scalar") (serialize-qp "maxDictionaryCount" $maxDictionaryCount "scalar") (serialize-qp "minLength" $minLength "scalar") (serialize-qp "maxLength" $maxLength "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/words.json/randomWords" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reverse dictionary search
#
# GET /words.json/reverseDictionary
# operationId: reverseDictionary
export def "wordsjson-reverse-dictionary reverseDictionary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Search term
  --findSenseForWord: string # Restricts words and finds closest sense
  --includeSourceDictionaries: string@includeSourceDictionaries-completer # Only include these comma-delimited source dictionaries
  --excludeSourceDictionaries: string@excludeSourceDictionaries-completer # Exclude these comma-delimited source dictionaries
  --includePartOfSpeech: string # Only include these comma-delimited parts of speech (allowable values are noun, adjective, verb, adverb, interjection, pronoun, preposition, abbreviation, affix, article, auxiliary-verb, conjunction, definite-article, family-name, given-name, idiom, imperative, noun-plural, noun-posessive, past-participle, phrasal-prefix, proper-noun, proper-noun-plural, proper-noun-posessive, suffix, verb-intransitive, verb-transitive)
  --excludePartOfSpeech: string # Exclude these comma-delimited parts of speech (allowable values are noun, adjective, verb, adverb, interjection, pronoun, preposition, abbreviation, affix, article, auxiliary-verb, conjunction, definite-article, family-name, given-name, idiom, imperative, noun-plural, noun-posessive, past-participle, phrasal-prefix, proper-noun, proper-noun-plural, proper-noun-posessive, suffix, verb-intransitive, verb-transitive)
  --minCorpusCount: int # Minimum corpus frequency for terms (format: int32, default: 5)
  --maxCorpusCount: int # Maximum corpus frequency for terms (format: int32, default: -1)
  --minLength: int # Minimum word length (format: int32, default: 1)
  --maxLength: int # Maximum word length (format: int32, default: -1)
  --expandTerms: string # Expand terms
  --includeTags: string@includeTags-completer # Return a closed set of XML tags in response (default: false)
  --sortBy: string@sortBy-completer # Attribute to sort by
  --sortOrder: string@sortOrder-completer # Sort direction
  --skip: string # Results to skip (default: 0)
  --limit: int # Maximum number of results to return (format: int32, default: 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "findSenseForWord" $findSenseForWord "scalar") (serialize-qp "includeSourceDictionaries" $includeSourceDictionaries "scalar") (serialize-qp "excludeSourceDictionaries" $excludeSourceDictionaries "scalar") (serialize-qp "includePartOfSpeech" $includePartOfSpeech "scalar") (serialize-qp "excludePartOfSpeech" $excludePartOfSpeech "scalar") (serialize-qp "minCorpusCount" $minCorpusCount "scalar") (serialize-qp "maxCorpusCount" $maxCorpusCount "scalar") (serialize-qp "minLength" $minLength "scalar") (serialize-qp "maxLength" $maxLength "scalar") (serialize-qp "expandTerms" $expandTerms "scalar") (serialize-qp "includeTags" $includeTags "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/words.json/reverseDictionary" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Searches words
#
# GET /words.json/search/{query}
# operationId: searchWords
export def "wordsjson-search searchWords" [
  query: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowRegex: string # Search term is a Regular Expression (default: false)
  --caseSensitive: string # Search case sensitive (default: true)
  --includePartOfSpeech: string # Only include these comma-delimited parts of speech (allowable values are noun, adjective, verb, adverb, interjection, pronoun, preposition, abbreviation, affix, article, auxiliary-verb, conjunction, definite-article, family-name, given-name, idiom, imperative, noun-plural, noun-posessive, past-participle, phrasal-prefix, proper-noun, proper-noun-plural, proper-noun-posessive, suffix, verb-intransitive, verb-transitive)
  --excludePartOfSpeech: string # Exclude these comma-delimited parts of speech (allowable values are noun, adjective, verb, adverb, interjection, pronoun, preposition, abbreviation, affix, article, auxiliary-verb, conjunction, definite-article, family-name, given-name, idiom, imperative, noun-plural, noun-posessive, past-participle, phrasal-prefix, proper-noun, proper-noun-plural, proper-noun-posessive, suffix, verb-intransitive, verb-transitive)
  --minCorpusCount: int # Minimum corpus frequency for terms (format: int32, default: 5)
  --maxCorpusCount: int # Maximum corpus frequency for terms (format: int32, default: -1)
  --minDictionaryCount: int # Minimum number of dictionary entries for words returned (format: int32, default: 1)
  --maxDictionaryCount: int # Maximum dictionary definition count (format: int32, default: -1)
  --minLength: int # Minimum word length (format: int32, default: 1)
  --maxLength: int # Maximum word length (format: int32, default: -1)
  --skip: int # Results to skip (format: int32, default: 0)
  --limit: int # Maximum number of results to return (format: int32, default: 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowRegex" $allowRegex "scalar") (serialize-qp "caseSensitive" $caseSensitive "scalar") (serialize-qp "includePartOfSpeech" $includePartOfSpeech "scalar") (serialize-qp "excludePartOfSpeech" $excludePartOfSpeech "scalar") (serialize-qp "minCorpusCount" $minCorpusCount "scalar") (serialize-qp "maxCorpusCount" $maxCorpusCount "scalar") (serialize-qp "minDictionaryCount" $minDictionaryCount "scalar") (serialize-qp "maxDictionaryCount" $maxDictionaryCount "scalar") (serialize-qp "minLength" $minLength "scalar") (serialize-qp "maxLength" $maxLength "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/words.json/search/($query)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a specific WordOfTheDay
#
# GET /words.json/wordOfTheDay
# operationId: getWordOfTheDay
export def "wordsjson-word-of-the-day get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Fetches by date in yyyy-MM-dd
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/words.json/wordOfTheDay" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
