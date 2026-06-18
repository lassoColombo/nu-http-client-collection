# Auto-generated client for Text Analytics & Sentiment Analysis API | api.text2data.com vv3.4
# Source: https://api.apis.guru/v2/specs/text2data.org/v3.4/swagger.json
# Auth: --token flag or $env.TEXT_ANALYTICS_SENTIMENT_ANALYSIS_API___API_TEXT2DATA_COM_TOKEN

const BASE_URL = "http://api.text2data.org"
const DEFAULT_AUTH = "query-PrivateKey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TEXT_ANALYTICS_SENTIMENT_ANALYSIS_API___API_TEXT2DATA_COM_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-PrivateKey" => { {headers: {}, query: $"(encode-path-segment "PrivateKey")=(encode-path-segment $token_val)"} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["http://api.text2data.org"] }
def auth-scheme-completer [] { ["query-PrivateKey"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "analyze get" } } | get name | first)
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

# Test api response without api key
#
# GET /v3/Analyze
# operationId: Analyze_Get
export def "analyze get" [
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
]: nothing -> record<AutoCategories: table<CategoryName: string, Score: float>, Citations: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, CloudTagHTML: string, CoreSentences: table<Magnitude: float, SentenceNumber: int, SentimentPolarity: string, SentimentResultString: string, SentimentValue: float, Text: string>, DetectedLanguage: string, DocSentimentPolarity: string, DocSentimentResultString: string, DocSentimentValue: float, Entities: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, ErrorMessage: string, Keywords: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, Magnitude: float, PartsOfSpeech: table<Action: string, Object: string, ObjectSentimentPolarity: string, ObjectSentimentResultString: string, ObjectSentimentValue: float, Subject: string, Text: string>, ResultTextHtml: string, SlangWords: table<SlangWordText: string, SlangWordTranslation: string>, Status: int, StorageInfo: record<CreateDate: string, DocumentText: string, IP: string, IsExcel: bool, IsGSExcel: bool, IsTwitterMode: bool, PrivateKey: string, RequestIdentifier: string, UserCategoryModelName: string>, Subjectivity: string, SwearWords: table<SlangWordText: string, SlangWordTranslation: string>, Themes: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, Timestamp: int, TransactionCurrentDay: int, TransactionDailyLimit: int, TransactionTotalCreditsLeft: int, TransactionUseByDate: string, UserCategories: table<CategoryName: string, Score: float>> {
  let auth = (build-auth $token ($auth_scheme | default "query-PrivateKey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/Analyze")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Sentiment analysis service
#
# POST /v3/Analyze
# operationId: Analyze_Post
export def "analyze create" [
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
  --document-language: string
  document_text: string
  --is-twitter-content: oneof<nothing, bool>
  private_key: string
  --request-identifier: string
  --secret: string
  --serialize-format: int # format: int32
  --user-category-model-name: string
]: any -> record<AutoCategories: table<CategoryName: string, Score: float>, Citations: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, CloudTagHTML: string, CoreSentences: table<Magnitude: float, SentenceNumber: int, SentimentPolarity: string, SentimentResultString: string, SentimentValue: float, Text: string>, DetectedLanguage: string, DocSentimentPolarity: string, DocSentimentResultString: string, DocSentimentValue: float, Entities: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, ErrorMessage: string, Keywords: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, Magnitude: float, PartsOfSpeech: table<Action: string, Object: string, ObjectSentimentPolarity: string, ObjectSentimentResultString: string, ObjectSentimentValue: float, Subject: string, Text: string>, ResultTextHtml: string, SlangWords: table<SlangWordText: string, SlangWordTranslation: string>, Status: int, StorageInfo: record<CreateDate: string, DocumentText: string, IP: string, IsExcel: bool, IsGSExcel: bool, IsTwitterMode: bool, PrivateKey: string, RequestIdentifier: string, UserCategoryModelName: string>, Subjectivity: string, SwearWords: table<SlangWordText: string, SlangWordTranslation: string>, Themes: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, Timestamp: int, TransactionCurrentDay: int, TransactionDailyLimit: int, TransactionTotalCreditsLeft: int, TransactionUseByDate: string, UserCategories: table<CategoryName: string, Score: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-PrivateKey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/Analyze")
  let req_body = {"DocumentLanguage": $document_language, "DocumentText": $document_text, "IsTwitterContent": $is_twitter_content, "PrivateKey": $private_key, "RequestIdentifier": $request_identifier, "Secret": $secret, "SerializeFormat": $serialize_format, "UserCategoryModelName": $user_category_model_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Test api response without api key
#
# GET /v3/Categorize
# operationId: Categorize_Get
export def "categorize get" [
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
]: nothing -> record<AutoCategories: table<CategoryName: string, Score: float>, Citations: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, CloudTagHTML: string, CoreSentences: table<Magnitude: float, SentenceNumber: int, SentimentPolarity: string, SentimentResultString: string, SentimentValue: float, Text: string>, DetectedLanguage: string, DocSentimentPolarity: string, DocSentimentResultString: string, DocSentimentValue: float, Entities: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, ErrorMessage: string, Keywords: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, Magnitude: float, PartsOfSpeech: table<Action: string, Object: string, ObjectSentimentPolarity: string, ObjectSentimentResultString: string, ObjectSentimentValue: float, Subject: string, Text: string>, ResultTextHtml: string, SlangWords: table<SlangWordText: string, SlangWordTranslation: string>, Status: int, StorageInfo: record<CreateDate: string, DocumentText: string, IP: string, IsExcel: bool, IsGSExcel: bool, IsTwitterMode: bool, PrivateKey: string, RequestIdentifier: string, UserCategoryModelName: string>, Subjectivity: string, SwearWords: table<SlangWordText: string, SlangWordTranslation: string>, Themes: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, Timestamp: int, TransactionCurrentDay: int, TransactionDailyLimit: int, TransactionTotalCreditsLeft: int, TransactionUseByDate: string, UserCategories: table<CategoryName: string, Score: float>> {
  let auth = (build-auth $token ($auth_scheme | default "query-PrivateKey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/Categorize")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Document categorization service
#
# POST /v3/Categorize
# operationId: Categorize_Post
export def "categorize create" [
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
  --document-language: string
  document_text: string
  --is-twitter-content: oneof<nothing, bool>
  private_key: string
  --request-identifier: string
  --secret: string
  --serialize-format: int # format: int32
  --user-category-model-name: string
]: any -> record<AutoCategories: table<CategoryName: string, Score: float>, Citations: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, CloudTagHTML: string, CoreSentences: table<Magnitude: float, SentenceNumber: int, SentimentPolarity: string, SentimentResultString: string, SentimentValue: float, Text: string>, DetectedLanguage: string, DocSentimentPolarity: string, DocSentimentResultString: string, DocSentimentValue: float, Entities: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, ErrorMessage: string, Keywords: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, Magnitude: float, PartsOfSpeech: table<Action: string, Object: string, ObjectSentimentPolarity: string, ObjectSentimentResultString: string, ObjectSentimentValue: float, Subject: string, Text: string>, ResultTextHtml: string, SlangWords: table<SlangWordText: string, SlangWordTranslation: string>, Status: int, StorageInfo: record<CreateDate: string, DocumentText: string, IP: string, IsExcel: bool, IsGSExcel: bool, IsTwitterMode: bool, PrivateKey: string, RequestIdentifier: string, UserCategoryModelName: string>, Subjectivity: string, SwearWords: table<SlangWordText: string, SlangWordTranslation: string>, Themes: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, Timestamp: int, TransactionCurrentDay: int, TransactionDailyLimit: int, TransactionTotalCreditsLeft: int, TransactionUseByDate: string, UserCategories: table<CategoryName: string, Score: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-PrivateKey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/Categorize")
  let req_body = {"DocumentLanguage": $document_language, "DocumentText": $document_text, "IsTwitterContent": $is_twitter_content, "PrivateKey": $private_key, "RequestIdentifier": $request_identifier, "Secret": $secret, "SerializeFormat": $serialize_format, "UserCategoryModelName": $user_category_model_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Test api response without api key
#
# GET /v3/Extract
# operationId: Extract_Get
export def "extract get" [
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
]: nothing -> record<AutoCategories: table<CategoryName: string, Score: float>, Citations: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, CloudTagHTML: string, CoreSentences: table<Magnitude: float, SentenceNumber: int, SentimentPolarity: string, SentimentResultString: string, SentimentValue: float, Text: string>, DetectedLanguage: string, DocSentimentPolarity: string, DocSentimentResultString: string, DocSentimentValue: float, Entities: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, ErrorMessage: string, Keywords: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, Magnitude: float, PartsOfSpeech: table<Action: string, Object: string, ObjectSentimentPolarity: string, ObjectSentimentResultString: string, ObjectSentimentValue: float, Subject: string, Text: string>, ResultTextHtml: string, SlangWords: table<SlangWordText: string, SlangWordTranslation: string>, Status: int, StorageInfo: record<CreateDate: string, DocumentText: string, IP: string, IsExcel: bool, IsGSExcel: bool, IsTwitterMode: bool, PrivateKey: string, RequestIdentifier: string, UserCategoryModelName: string>, Subjectivity: string, SwearWords: table<SlangWordText: string, SlangWordTranslation: string>, Themes: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, Timestamp: int, TransactionCurrentDay: int, TransactionDailyLimit: int, TransactionTotalCreditsLeft: int, TransactionUseByDate: string, UserCategories: table<CategoryName: string, Score: float>> {
  let auth = (build-auth $token ($auth_scheme | default "query-PrivateKey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/Extract")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Document extraction service
#
# POST /v3/Extract
# operationId: Extract_Post
export def "extract create" [
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
  --document-language: string
  document_text: string
  --is-twitter-content: oneof<nothing, bool>
  private_key: string
  --request-identifier: string
  --secret: string
  --serialize-format: int # format: int32
  --user-category-model-name: string
]: any -> record<AutoCategories: table<CategoryName: string, Score: float>, Citations: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, CloudTagHTML: string, CoreSentences: table<Magnitude: float, SentenceNumber: int, SentimentPolarity: string, SentimentResultString: string, SentimentValue: float, Text: string>, DetectedLanguage: string, DocSentimentPolarity: string, DocSentimentResultString: string, DocSentimentValue: float, Entities: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, ErrorMessage: string, Keywords: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, Magnitude: float, PartsOfSpeech: table<Action: string, Object: string, ObjectSentimentPolarity: string, ObjectSentimentResultString: string, ObjectSentimentValue: float, Subject: string, Text: string>, ResultTextHtml: string, SlangWords: table<SlangWordText: string, SlangWordTranslation: string>, Status: int, StorageInfo: record<CreateDate: string, DocumentText: string, IP: string, IsExcel: bool, IsGSExcel: bool, IsTwitterMode: bool, PrivateKey: string, RequestIdentifier: string, UserCategoryModelName: string>, Subjectivity: string, SwearWords: table<SlangWordText: string, SlangWordTranslation: string>, Themes: table<KeywordType: string, Magnitude: float, Mentions: int, SentencePartType: string, SentenceText: string, SentimentPolarity: string, SentimentResult: string, SentimentValue: float, Text: string>, Timestamp: int, TransactionCurrentDay: int, TransactionDailyLimit: int, TransactionTotalCreditsLeft: int, TransactionUseByDate: string, UserCategories: table<CategoryName: string, Score: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-PrivateKey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/Extract")
  let req_body = {"DocumentLanguage": $document_language, "DocumentText": $document_text, "IsTwitterContent": $is_twitter_content, "PrivateKey": $private_key, "RequestIdentifier": $request_identifier, "Secret": $secret, "SerializeFormat": $serialize_format, "UserCategoryModelName": $user_category_model_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
