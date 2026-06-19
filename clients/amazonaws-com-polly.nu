# Auto-generated client for Amazon Polly v2016-06-10
# Source: https://api.apis.guru/v2/specs/amazonaws.com/polly/2016-06-10/openapi.json
# Auth: --token flag or $env.AMAZON_POLLY_TOKEN

const BASE_URL = "http://polly.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_POLLY_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["http://polly.us-east-1.amazonaws.com" "http://polly.us-east-2.amazonaws.com" "http://polly.us-west-1.amazonaws.com" "http://polly.us-west-2.amazonaws.com" "http://polly.us-gov-west-1.amazonaws.com" "http://polly.us-gov-east-1.amazonaws.com" "http://polly.ca-central-1.amazonaws.com" "http://polly.eu-north-1.amazonaws.com" "http://polly.eu-west-1.amazonaws.com" "http://polly.eu-west-2.amazonaws.com" "http://polly.eu-west-3.amazonaws.com" "http://polly.eu-central-1.amazonaws.com" "http://polly.eu-south-1.amazonaws.com" "http://polly.af-south-1.amazonaws.com" "http://polly.ap-northeast-1.amazonaws.com" "http://polly.ap-northeast-2.amazonaws.com" "http://polly.ap-northeast-3.amazonaws.com" "http://polly.ap-southeast-1.amazonaws.com" "http://polly.ap-southeast-2.amazonaws.com" "http://polly.ap-east-1.amazonaws.com" "http://polly.ap-south-1.amazonaws.com" "http://polly.sa-east-1.amazonaws.com" "http://polly.me-south-1.amazonaws.com" "https://polly.us-east-1.amazonaws.com" "https://polly.us-east-2.amazonaws.com" "https://polly.us-west-1.amazonaws.com" "https://polly.us-west-2.amazonaws.com" "https://polly.us-gov-west-1.amazonaws.com" "https://polly.us-gov-east-1.amazonaws.com" "https://polly.ca-central-1.amazonaws.com" "https://polly.eu-north-1.amazonaws.com" "https://polly.eu-west-1.amazonaws.com" "https://polly.eu-west-2.amazonaws.com" "https://polly.eu-west-3.amazonaws.com" "https://polly.eu-central-1.amazonaws.com" "https://polly.eu-south-1.amazonaws.com" "https://polly.af-south-1.amazonaws.com" "https://polly.ap-northeast-1.amazonaws.com" "https://polly.ap-northeast-2.amazonaws.com" "https://polly.ap-northeast-3.amazonaws.com" "https://polly.ap-southeast-1.amazonaws.com" "https://polly.ap-southeast-2.amazonaws.com" "https://polly.ap-east-1.amazonaws.com" "https://polly.ap-south-1.amazonaws.com" "https://polly.sa-east-1.amazonaws.com" "https://polly.me-south-1.amazonaws.com" "http://polly.cn-north-1.amazonaws.com.cn" "http://polly.cn-northwest-1.amazonaws.com.cn" "https://polly.cn-north-1.amazonaws.com.cn" "https://polly.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def engine-completer [] { ["neural" "standard"] }
def language-code-completer [] { ["ar-AE" "arb" "ca-ES" "cmn-CN" "cy-GB" "da-DK" "de-AT" "de-DE" "en-AU" "en-GB" "en-GB-WLS" "en-IN" "en-NZ" "en-US" "en-ZA" "es-ES" "es-MX" "es-US" "fi-FI" "fr-CA" "fr-FR" "hi-IN" "is-IS" "it-IT" "ja-JP" "ko-KR" "nb-NO" "nl-NL" "pl-PL" "pt-BR" "pt-PT" "ro-RO" "ru-RU" "sv-SE" "tr-TR" "yue-CN"] }
def status-completer [] { ["completed" "failed" "inProgress" "scheduled"] }
def output-format-completer [] { ["json" "mp3" "ogg_vorbis" "pcm"] }
def text-type-completer [] { ["ssml" "text"] }
def voice-id-completer [] { ["Aditi" "Adriano" "Amy" "Andres" "Aria" "Arlet" "Arthur" "Astrid" "Ayanda" "Bianca" "Brian" "Camila" "Carla" "Carmen" "Celine" "Chantal" "Conchita" "Cristiano" "Daniel" "Dora" "Elin" "Emma" "Enrique" "Ewa" "Filiz" "Gabrielle" "Geraint" "Giorgio" "Gwyneth" "Hala" "Hannah" "Hans" "Hiujin" "Ida" "Ines" "Ivy" "Jacek" "Jan" "Joanna" "Joey" "Justin" "Kajal" "Karl" "Kazuha" "Kendra" "Kevin" "Kimberly" "Laura" "Lea" "Liam" "Liv" "Lotte" "Lucia" "Lupe" "Mads" "Maja" "Marlene" "Mathieu" "Matthew" "Maxim" "Mia" "Miguel" "Mizuki" "Naja" "Nicole" "Ola" "Olivia" "Pedro" "Penelope" "Raveena" "Remi" "Ricardo" "Ruben" "Russell" "Ruth" "Salli" "Seoyeon" "Sergio" "Stephen" "Suvi" "Takumi" "Tatyana" "Thiago" "Tomoko" "Vicki" "Vitoria" "Zeina" "Zhiyu"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "lexicons delete" } } | get name | first)
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

# Deletes the specified pronunciation lexicon stored in an Amazon Web Services Region. A lexicon which has been deleted is not available for speech synthesis, nor is it possible to retrieve it using either the GetLexicon or ListLexicon APIs. For more information, see Managing Lexicons (https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html).
#
# DELETE /v1/lexicons/{LexiconName}
# operationId: DeleteLexicon
export def "lexicons delete" [
  lexicon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($lexicon_name | is-empty) { error make --unspanned { msg: "path parameter 'LexiconName' must be non-empty" } }
  let full_url = (build-url $base ({lexicon_name: (encode-path-segment $lexicon_name)} | format pattern "/v1/lexicons/{lexicon_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the content of the specified pronunciation lexicon stored in an Amazon Web Services Region. For more information, see Managing Lexicons (https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html).
#
# GET /v1/lexicons/{LexiconName}
# operationId: GetLexicon
export def "lexicons get" [
  lexicon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Lexicon: record<Content: record, Name: record>, LexiconAttributes: record<Alphabet: record, LanguageCode: record, LastModified: record, LexiconArn: record, LexemesCount: record, Size: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($lexicon_name | is-empty) { error make --unspanned { msg: "path parameter 'LexiconName' must be non-empty" } }
  let full_url = (build-url $base ({lexicon_name: (encode-path-segment $lexicon_name)} | format pattern "/v1/lexicons/{lexicon_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Stores a pronunciation lexicon in an Amazon Web Services Region. If a lexicon with the same name already exists in the region, it is overwritten by the new lexicon. Lexicon operations have eventual consistency, therefore, it might take some time before the lexicon is available to the SynthesizeSpeech operation. For more information, see Managing Lexicons (https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html).
#
# PUT /v1/lexicons/{LexiconName}
# operationId: PutLexicon
export def "lexicons update" [
  lexicon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  content: string # Content of the PLS lexicon as string data. (format: password)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($lexicon_name | is-empty) { error make --unspanned { msg: "path parameter 'LexiconName' must be non-empty" } }
  let full_url = (build-url $base ({lexicon_name: (encode-path-segment $lexicon_name)} | format pattern "/v1/lexicons/{lexicon_name}"))
  let req_body = {"Content": $content} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the list of voices that are available for use when requesting speech synthesis. Each voice speaks a specified language, is either male or female, and is identified by an ID, which is the ASCII version of the voice name. When synthesizing speech ( SynthesizeSpeech ), you provide the voice ID for the voice you want from the list of voices returned by DescribeVoices. For example, you want your news reader application to read news in a specific language, but giving a user the option to choose the voice. Using the DescribeVoices operation you can provide the user with a list of available voices to select from. You can optionally specify a language code to filter the available voices. For example, if you specify en-US, the operation returns a list of all available US English voices. This operation requires permissions to perform the polly:DescribeVoices action.
#
# GET /v1/voices
# operationId: DescribeVoices
export def "voices get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --engine: string@engine-completer # Specifies the engine (standard or neural) used by Amazon Polly when processing input text for speech synthesis.
  --language-code: string@language-code-completer # The language identification tag (ISO 639 code for the language name-ISO 3166 country code) for filtering the list of voices returned. If you don't specify this optional parameter, all available voices are returned.
  --include-additional-language-codes: oneof<nothing, bool> # Boolean value indicating whether to return any bilingual voices that use the specified language as an additional language. For instance, if you request all languages that use US English (es-US), and there is an Italian voice that speaks both Italian (it-IT) and US English, that voice will be included if you specify yes but not if you specify no.
  --next-token: string # An opaque pagination token returned from the previous DescribeVoices operation. If present, this indicates where to continue the listing.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Voices: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Engine" $engine "scalar") (serialize-qp "LanguageCode" $language_code "scalar") (serialize-qp "IncludeAdditionalLanguageCodes" $include_additional_language_codes "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/voices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Engine": $engine, "LanguageCode": $language_code, "IncludeAdditionalLanguageCodes": $include_additional_language_codes, "NextToken": $next_token} | compact), body: null}
}

# Retrieves a specific SpeechSynthesisTask object based on its TaskID. This object contains information about the given speech synthesis task, including the status of the task, and a link to the S3 bucket containing the output of the task.
#
# GET /v1/synthesisTasks/{TaskId}
# operationId: GetSpeechSynthesisTask
export def "synthesis-tasks get-speech" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<SynthesisTask: record<Engine: record, TaskId: record, TaskStatus: record, TaskStatusReason: record, OutputUri: record, CreationTime: record, RequestCharacters: record, SnsTopicArn: record, LexiconNames: record, OutputFormat: record, SampleRate: record, SpeechMarkTypes: record, TextType: record, VoiceId: record, LanguageCode: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'TaskId' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/v1/synthesisTasks/{task_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of pronunciation lexicons stored in an Amazon Web Services Region. For more information, see Managing Lexicons (https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html).
#
# GET /v1/lexicons
# operationId: ListLexicons
export def "lexicons list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # An opaque pagination token returned from previous ListLexicons operation. If present, indicates where to continue the list of lexicons.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Lexicons: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/lexicons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"NextToken": $next_token} | compact), body: null}
}

# Returns a list of SpeechSynthesisTask objects ordered by their creation date. This operation can filter the tasks by their status, for example, allowing users to list only tasks that are completed.
#
# GET /v1/synthesisTasks
# operationId: ListSpeechSynthesisTasks
export def "synthesis-tasks list-speech" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # Maximum number of speech synthesis tasks returned in a List operation.
  --next-token: string # The pagination token to use in the next request to continue the listing of speech synthesis tasks.
  --status: string@status-completer # Status of the speech synthesis tasks returned in a List operation
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextToken: record, SynthesisTasks: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "Status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/synthesisTasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"MaxResults": $max_results, "NextToken": $next_token, "Status": $status} | compact), body: null}
}

# Allows the creation of an asynchronous synthesis task, by starting a new SpeechSynthesisTask. This operation requires all the standard information needed for speech synthesis, plus the name of an Amazon S3 bucket for the service to store the output of the synthesis task and two optional parameters (OutputS3KeyPrefix and SnsTopicArn). Once the synthesis task is created, this operation will return a SpeechSynthesisTask object, which will include an identifier of this task as well as the current status. The SpeechSynthesisTask object is available for 72 hours after starting the asynchronous synthesis task.
#
# POST /v1/synthesisTasks
# operationId: StartSpeechSynthesisTask
export def "synthesis-tasks start-speech" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --engine: string@engine-completer # Specifies the engine (standard or neural) for Amazon Polly to use when processing input text for speech synthesis. Using a voice that is not supported for the engine selected will result in an error.
  --language-code: string@language-code-completer # Optional language code for the Speech Synthesis request. This is only necessary if using a bilingual voice, such as Aditi, which can be used for either Indian English (en-IN) or Hindi (hi-IN). If a bilingual voice is used and no language code is specified, Amazon Polly uses the default language of the bilingual voice. The default language for any voice is the one returned by the DescribeVoices (https://docs.aws.amazon.com/polly/latest/dg/API_DescribeVoices.html) operation for the LanguageCode parameter. For example, if no language code is specified, Aditi will use Indian English rather than Hindi.
  --lexicon-names: list<string> # List of one or more pronunciation lexicon names you want the service to apply during synthesis. Lexicons are applied only if the language of the lexicon is the same as the language of the voice.
  output_format: string@output-format-completer # The format in which the returned output will be encoded. For audio stream, this will be mp3, ogg_vorbis, or pcm. For speech marks, this will be json.
  output_s3_bucket_name: string # Amazon S3 bucket name to which the output file will be saved.
  --output-s3-key-prefix: string # The Amazon S3 key prefix for the output speech file.
  --sample-rate: string # The audio frequency specified in Hz. The valid values for mp3 and ogg_vorbis are "8000", "16000", "22050", and "24000". The default value for standard voices is "22050". The default value for neural voices is "24000". Valid values for pcm are "8000" and "16000" The default value is "16000".
  --sns-topic-arn: string # ARN for the SNS topic optionally used for providing status notification for a speech synthesis task.
  --speech-mark-types: list<string> # The type of speech marks returned for the input text.
  text: string # The input text to synthesize. If you specify ssml as the TextType, follow the SSML format for the input text.
  --text-type: string@text-type-completer # Specifies whether the input text is plain text or SSML. The default value is plain text.
  voice_id: string@voice-id-completer # Voice ID to use for the synthesis.
]: any -> record<SynthesisTask: record<Engine: record, TaskId: record, TaskStatus: record, TaskStatusReason: record, OutputUri: record, CreationTime: record, RequestCharacters: record, SnsTopicArn: record, LexiconNames: record, OutputFormat: record, SampleRate: record, SpeechMarkTypes: record, TextType: record, VoiceId: record, LanguageCode: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/synthesisTasks")
  let req_body = {"Engine": $engine, "LanguageCode": $language_code, "LexiconNames": $lexicon_names, "OutputFormat": $output_format, "OutputS3BucketName": $output_s3_bucket_name, "OutputS3KeyPrefix": $output_s3_key_prefix, "SampleRate": $sample_rate, "SnsTopicArn": $sns_topic_arn, "SpeechMarkTypes": $speech_mark_types, "Text": $text, "TextType": $text_type, "VoiceId": $voice_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Synthesizes UTF-8 input, plain text or SSML, to a stream of bytes. SSML input must be valid, well-formed SSML. Some alphabets might not be available with all the voices (for example, Cyrillic might not be read at all by English voices) unless phoneme mapping is used. For more information, see How it Works (https://docs.aws.amazon.com/polly/latest/dg/how-text-to-speech-works.html).
#
# POST /v1/speech
# operationId: SynthesizeSpeech
export def "speech create-synthesize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --engine: string@engine-completer # Specifies the engine (standard or neural) for Amazon Polly to use when processing input text for speech synthesis. For information on Amazon Polly voices and which voices are available in standard-only, NTTS-only, and both standard and NTTS formats, see Available Voices (https://docs.aws.amazon.com/polly/latest/dg/voicelist.html). NTTS-only voices When using NTTS-only voices such as Kevin (en-US), this parameter is required and must be set to neural. If the engine is not specified, or is set to standard, this will result in an error. Type: String Valid Values: standard | neural Required: Yes Standard voices For standard voices, this is not required; the engine parameter defaults to standard. If the engine is not specified, or is set to standard and an NTTS-only voice is selected, this will result in an error.
  --language-code: string@language-code-completer # Optional language code for the Synthesize Speech request. This is only necessary if using a bilingual voice, such as Aditi, which can be used for either Indian English (en-IN) or Hindi (hi-IN). If a bilingual voice is used and no language code is specified, Amazon Polly uses the default language of the bilingual voice. The default language for any voice is the one returned by the DescribeVoices (https://docs.aws.amazon.com/polly/latest/dg/API_DescribeVoices.html) operation for the LanguageCode parameter. For example, if no language code is specified, Aditi will use Indian English rather than Hindi.
  --lexicon-names: list<string> # List of one or more pronunciation lexicon names you want the service to apply during synthesis. Lexicons are applied only if the language of the lexicon is the same as the language of the voice. For information about storing lexicons, see PutLexicon (https://docs.aws.amazon.com/polly/latest/dg/API_PutLexicon.html).
  output_format: string@output-format-completer # The format in which the returned output will be encoded. For audio stream, this will be mp3, ogg_vorbis, or pcm. For speech marks, this will be json. When pcm is used, the content returned is audio/pcm in a signed 16-bit, 1 channel (mono), little-endian format.
  --sample-rate: string # The audio frequency specified in Hz. The valid values for mp3 and ogg_vorbis are "8000", "16000", "22050", and "24000". The default value for standard voices is "22050". The default value for neural voices is "24000". Valid values for pcm are "8000" and "16000" The default value is "16000".
  --speech-mark-types: list<string> # The type of speech marks returned for the input text.
  text: string # Input text to synthesize. If you specify ssml as the TextType, follow the SSML format for the input text.
  --text-type: string@text-type-completer # Specifies whether the input text is plain text or SSML. The default value is plain text. For more information, see Using SSML (https://docs.aws.amazon.com/polly/latest/dg/ssml.html).
  voice_id: string@voice-id-completer # Voice ID to use for the synthesis. You can get a list of available voice IDs by calling the DescribeVoices (https://docs.aws.amazon.com/polly/latest/dg/API_DescribeVoices.html) operation.
]: any -> record<AudioStream: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/speech")
  let req_body = {"Engine": $engine, "LanguageCode": $language_code, "LexiconNames": $lexicon_names, "OutputFormat": $output_format, "SampleRate": $sample_rate, "SpeechMarkTypes": $speech_mark_types, "Text": $text, "TextType": $text_type, "VoiceId": $voice_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
