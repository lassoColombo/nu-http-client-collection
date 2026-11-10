# Auto-generated client for Amazon Transcribe Service v2017-10-26
# Source: https://api.apis.guru/v2/specs/amazonaws.com/transcribe/2017-10-26/openapi.json
# Auth: --token flag or $env.AMAZON_TRANSCRIBE_SERVICE_TOKEN

const BASE_URL = "http://transcribe.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_TRANSCRIBE_SERVICE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://transcribe.us-east-1.amazonaws.com" "http://transcribe.us-east-2.amazonaws.com" "http://transcribe.us-west-1.amazonaws.com" "http://transcribe.us-west-2.amazonaws.com" "http://transcribe.us-gov-west-1.amazonaws.com" "http://transcribe.us-gov-east-1.amazonaws.com" "http://transcribe.ca-central-1.amazonaws.com" "http://transcribe.eu-north-1.amazonaws.com" "http://transcribe.eu-west-1.amazonaws.com" "http://transcribe.eu-west-2.amazonaws.com" "http://transcribe.eu-west-3.amazonaws.com" "http://transcribe.eu-central-1.amazonaws.com" "http://transcribe.eu-south-1.amazonaws.com" "http://transcribe.af-south-1.amazonaws.com" "http://transcribe.ap-northeast-1.amazonaws.com" "http://transcribe.ap-northeast-2.amazonaws.com" "http://transcribe.ap-northeast-3.amazonaws.com" "http://transcribe.ap-southeast-1.amazonaws.com" "http://transcribe.ap-southeast-2.amazonaws.com" "http://transcribe.ap-east-1.amazonaws.com" "http://transcribe.ap-south-1.amazonaws.com" "http://transcribe.sa-east-1.amazonaws.com" "http://transcribe.me-south-1.amazonaws.com" "https://transcribe.us-east-1.amazonaws.com" "https://transcribe.us-east-2.amazonaws.com" "https://transcribe.us-west-1.amazonaws.com" "https://transcribe.us-west-2.amazonaws.com" "https://transcribe.us-gov-west-1.amazonaws.com" "https://transcribe.us-gov-east-1.amazonaws.com" "https://transcribe.ca-central-1.amazonaws.com" "https://transcribe.eu-north-1.amazonaws.com" "https://transcribe.eu-west-1.amazonaws.com" "https://transcribe.eu-west-2.amazonaws.com" "https://transcribe.eu-west-3.amazonaws.com" "https://transcribe.eu-central-1.amazonaws.com" "https://transcribe.eu-south-1.amazonaws.com" "https://transcribe.af-south-1.amazonaws.com" "https://transcribe.ap-northeast-1.amazonaws.com" "https://transcribe.ap-northeast-2.amazonaws.com" "https://transcribe.ap-northeast-3.amazonaws.com" "https://transcribe.ap-southeast-1.amazonaws.com" "https://transcribe.ap-southeast-2.amazonaws.com" "https://transcribe.ap-east-1.amazonaws.com" "https://transcribe.ap-south-1.amazonaws.com" "https://transcribe.sa-east-1.amazonaws.com" "https://transcribe.me-south-1.amazonaws.com" "http://transcribe.cn-north-1.amazonaws.com.cn" "http://transcribe.cn-northwest-1.amazonaws.com.cn" "https://transcribe.cn-north-1.amazonaws.com.cn" "https://transcribe.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def input-type-completer [] { ["POST_CALL" "REAL_TIME"] }
def x-amz-target-completer [] { ["Transcribe.CreateCallAnalyticsCategory"] }
def language-code-completer [] { ["de-DE" "en-AU" "en-GB" "en-US" "es-US" "hi-IN" "ja-JP"] }
def base-model-name-completer [] { ["NarrowBand" "WideBand"] }
def x-amz-target-completer-1 [] { ["Transcribe.CreateLanguageModel"] }
def language-code-completer-1 [] { ["af-ZA" "ar-AE" "ar-SA" "da-DK" "de-CH" "de-DE" "en-AB" "en-AU" "en-GB" "en-IE" "en-IN" "en-NZ" "en-US" "en-WL" "en-ZA" "es-ES" "es-US" "fa-IR" "fr-CA" "fr-FR" "he-IL" "hi-IN" "id-ID" "it-IT" "ja-JP" "ko-KR" "ms-MY" "nl-NL" "pt-BR" "pt-PT" "ru-RU" "sv-SE" "ta-IN" "te-IN" "th-TH" "tr-TR" "vi-VN" "zh-CN" "zh-TW"] }
def x-amz-target-completer-2 [] { ["Transcribe.CreateMedicalVocabulary"] }
def x-amz-target-completer-3 [] { ["Transcribe.CreateVocabulary"] }
def x-amz-target-completer-4 [] { ["Transcribe.CreateVocabularyFilter"] }
def x-amz-target-completer-5 [] { ["Transcribe.DeleteCallAnalyticsCategory"] }
def x-amz-target-completer-6 [] { ["Transcribe.DeleteCallAnalyticsJob"] }
def x-amz-target-completer-7 [] { ["Transcribe.DeleteLanguageModel"] }
def x-amz-target-completer-8 [] { ["Transcribe.DeleteMedicalTranscriptionJob"] }
def x-amz-target-completer-9 [] { ["Transcribe.DeleteMedicalVocabulary"] }
def x-amz-target-completer-10 [] { ["Transcribe.DeleteTranscriptionJob"] }
def x-amz-target-completer-11 [] { ["Transcribe.DeleteVocabulary"] }
def x-amz-target-completer-12 [] { ["Transcribe.DeleteVocabularyFilter"] }
def x-amz-target-completer-13 [] { ["Transcribe.DescribeLanguageModel"] }
def x-amz-target-completer-14 [] { ["Transcribe.GetCallAnalyticsCategory"] }
def x-amz-target-completer-15 [] { ["Transcribe.GetCallAnalyticsJob"] }
def x-amz-target-completer-16 [] { ["Transcribe.GetMedicalTranscriptionJob"] }
def x-amz-target-completer-17 [] { ["Transcribe.GetMedicalVocabulary"] }
def x-amz-target-completer-18 [] { ["Transcribe.GetTranscriptionJob"] }
def x-amz-target-completer-19 [] { ["Transcribe.GetVocabulary"] }
def x-amz-target-completer-20 [] { ["Transcribe.GetVocabularyFilter"] }
def x-amz-target-completer-21 [] { ["Transcribe.ListCallAnalyticsCategories"] }
def status-completer [] { ["COMPLETED" "FAILED" "IN_PROGRESS" "QUEUED"] }
def x-amz-target-completer-22 [] { ["Transcribe.ListCallAnalyticsJobs"] }
def status-equals-completer [] { ["COMPLETED" "FAILED" "IN_PROGRESS"] }
def x-amz-target-completer-23 [] { ["Transcribe.ListLanguageModels"] }
def x-amz-target-completer-24 [] { ["Transcribe.ListMedicalTranscriptionJobs"] }
def state-equals-completer [] { ["FAILED" "PENDING" "READY"] }
def x-amz-target-completer-25 [] { ["Transcribe.ListMedicalVocabularies"] }
def x-amz-target-completer-26 [] { ["Transcribe.ListTagsForResource"] }
def x-amz-target-completer-27 [] { ["Transcribe.ListTranscriptionJobs"] }
def x-amz-target-completer-28 [] { ["Transcribe.ListVocabularies"] }
def x-amz-target-completer-29 [] { ["Transcribe.ListVocabularyFilters"] }
def x-amz-target-completer-30 [] { ["Transcribe.StartCallAnalyticsJob"] }
def media-format-completer [] { ["amr" "flac" "mp3" "mp4" "ogg" "wav" "webm"] }
def content-identification-type-completer [] { ["PHI"] }
def specialty-completer [] { ["PRIMARYCARE"] }
def type-completer [] { ["CONVERSATION" "DICTATION"] }
def x-amz-target-completer-31 [] { ["Transcribe.StartMedicalTranscriptionJob"] }
def x-amz-target-completer-32 [] { ["Transcribe.StartTranscriptionJob"] }
def x-amz-target-completer-33 [] { ["Transcribe.TagResource"] }
def x-amz-target-completer-34 [] { ["Transcribe.UntagResource"] }
def x-amz-target-completer-35 [] { ["Transcribe.UpdateCallAnalyticsCategory"] }
def x-amz-target-completer-36 [] { ["Transcribe.UpdateMedicalVocabulary"] }
def x-amz-target-completer-37 [] { ["Transcribe.UpdateVocabulary"] }
def x-amz-target-completer-38 [] { ["Transcribe.UpdateVocabularyFilter"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-call-analytics-category" "create-language-model" "create-medical-vocabulary" "create-vocabulary" "create-vocabulary-filter" "delete-call-analytics-category" "delete-call-analytics-job" "delete-language-model" "delete-medical-transcription-job" "delete-medical-vocabulary" "delete-transcription-job" "delete-vocabulary" "delete-vocabulary-filter" "describe-language-model" "get-call-analytics-category" "get-call-analytics-job" "get-medical-transcription-job" "get-medical-vocabulary" "get-transcription-job" "get-vocabulary" "get-vocabulary-filter" "list-call-analytics-categories" "list-call-analytics-jobs" "list-language-models" "list-medical-transcription-jobs" "list-medical-vocabularies" "list-tags-for-resource" "list-transcription-jobs" "list-vocabularies" "list-vocabulary-filters" "start-call-analytics-job" "start-medical-transcription-job" "start-transcription-job" "tag-resource" "untag-resource" "update-call-analytics-category" "update-medical-vocabulary" "update-vocabulary" "update-vocabulary-filter" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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

# Creates a new Call Analytics category. All categories are automatically applied to your Call Analytics transcriptions. Note that in order to apply categories to your transcriptions, you must create them before submitting your transcription request, as categories cannot be applied retroactively. When creating a new category, you can use the InputType parameter to label the category as a POST_CALL or a REAL_TIME category. POST_CALL categories can only be applied to post-call transcriptions and REAL_TIME categories can only be applied to real-time transcriptions. If you do not include InputType, your category is created as a POST_CALL category by default. Call Analytics categories are composed of rules. For each category, you must create between 1 and 20 rules. Rules can include these parameters: , , , and . To update an existing category, see . To learn more about Call Analytics categories, see Creating categories for post-call transcriptions (https://docs.aws.amazon.com/transcribe/latest/dg/tca-categories-batch.html) and Creating categories for real-time transcriptions (https://docs.aws.amazon.com/transcribe/latest/dg/tca-categories-stream.html).
#
# POST /
# operationId: CreateCallAnalyticsCategory
export def "create-call-analytics-category" [
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
  --x-amz-target: string@x-amz-target-completer # required
  category_name: string # A unique name, chosen by you, for your Call Analytics category. It's helpful to use a detailed naming system that will make sense to you in the future. For example, it's better to use sentiment-positive-last30seconds for a category over a generic name like test-category. Category names are case sensitive.
  rules: list # Rules define a Call Analytics category. When creating a new category, you must create between 1 and 20 rules for that category. For each rule, you specify a filter you want applied to the attributes of a call. For example, you can choose a sentiment filter that detects if a customer's sentiment was positive during the last 30 seconds of the call. — item shape: {NonTalkTimeFilter?: record, InterruptionFilter?: record, TranscriptFilter?: record, SentimentFilter?: record}
  --input-type: string@input-type-completer # Choose whether you want to create a real-time or a post-call category for your Call Analytics transcription. Specifying POST_CALL assigns your category to post-call transcriptions; categories with this input type cannot be applied to streaming (real-time) transcriptions. Specifying REAL_TIME assigns your category to streaming transcriptions; categories with this input type cannot be applied to post-call transcriptions. If you do not include InputType, your category is created as a post-call category by default.
]: any -> oneof<record<CategoryProperties: record<CategoryName: string, Rules: list<record>, CreateTime: string, LastUpdateTime: string, InputType: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.CreateCallAnalyticsCategory")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CategoryName": $category_name, "Rules": $rules, "InputType": $input_type} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Creates a new custom language model. When creating a new custom language model, you must specify: If you want a Wideband (audio sample rates over 16,000 Hz) or Narrowband (audio sample rates under 16,000 Hz) base model The location of your training and tuning files (this must be an Amazon S3 URI) The language of your model A unique name for your model
#
# POST /
# operationId: CreateLanguageModel
export def "create-language-model" [
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
  --x-amz-target: string@x-amz-target-completer-1 # required
  language_code: string@language-code-completer # The language code that represents the language of your model. Each custom language model must contain terms in only one language, and the language you select for your custom language model must match the language of your training and tuning data. For a list of supported languages and their associated language codes, refer to the Supported languages (https://docs.aws.amazon.com/transcribe/latest/dg/supported-languages.html) table. Note that US English (en-US) is the only language supported with Amazon Transcribe Medical. A custom language model can only be used to transcribe files in the same language as the model. For example, if you create a custom language model using US English (en-US), you can only apply this model to files that contain English audio.
  base_model_name: string@base-model-name-completer # The Amazon Transcribe standard language model, or base model, used to create your custom language model. Amazon Transcribe offers two options for base models: Wideband and Narrowband. If the audio you want to transcribe has a sample rate of 16,000 Hz or greater, choose WideBand. To transcribe audio with a sample rate less than 16,000 Hz, choose NarrowBand.
  model_name: string # A unique name, chosen by you, for your custom language model. This name is case sensitive, cannot contain spaces, and must be unique within an Amazon Web Services account. If you try to create a new custom language model with the same name as an existing custom language model, you get a ConflictException error.
  input_data_config: record # Contains the Amazon S3 location of the training data you want to use to create a new custom language model, and permissions to access this location. When using InputDataConfig, you must include these sub-parameters: S3Uri and DataAccessRoleArn. You can optionally include TuningDataS3Uri. — shape: {S3Uri: string, TuningDataS3Uri?: string, DataAccessRoleArn: string}
  --tags: list # Adds one or more custom tags, each in the form of a key:value pair, to a new custom language model at the time you create this new model. To learn more about using tags with Amazon Transcribe, refer to Tagging resources (https://docs.aws.amazon.com/transcribe/latest/dg/tagging.html). — item shape: {Key: string, Value: string}
]: any -> oneof<record<LanguageCode: string, BaseModelName: string, ModelName: string, InputDataConfig: record<S3Uri: string, TuningDataS3Uri: string, DataAccessRoleArn: string>, ModelStatus: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.CreateLanguageModel")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LanguageCode": $language_code, "BaseModelName": $base_model_name, "ModelName": $model_name, "InputDataConfig": $input_data_config, "Tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Creates a new custom medical vocabulary. Before creating a new custom medical vocabulary, you must first upload a text file that contains your vocabulary table into an Amazon S3 bucket. Note that this differs from , where you can include a list of terms within your request using the Phrases flag; CreateMedicalVocabulary does not support the Phrases flag and only accepts vocabularies in table format. Each language has a character set that contains all allowed characters for that specific language. If you use unsupported characters, your custom vocabulary request fails. Refer to Character Sets for Custom Vocabularies (https://docs.aws.amazon.com/transcribe/latest/dg/charsets.html) to get the character set for your language. For more information, see Custom vocabularies (https://docs.aws.amazon.com/transcribe/latest/dg/custom-vocabulary.html).
#
# POST /
# operationId: CreateMedicalVocabulary
export def "create-medical-vocabulary" [
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
  --x-amz-target: string@x-amz-target-completer-2 # required
  vocabulary_name: string # A unique name, chosen by you, for your new custom medical vocabulary. This name is case sensitive, cannot contain spaces, and must be unique within an Amazon Web Services account. If you try to create a new custom medical vocabulary with the same name as an existing custom medical vocabulary, you get a ConflictException error.
  language_code: string@language-code-completer-1 # The language code that represents the language of the entries in your custom vocabulary. US English (en-US) is the only language supported with Amazon Transcribe Medical.
  vocabulary_file_uri: string # The Amazon S3 location (URI) of the text file that contains your custom medical vocabulary. The URI must be in the same Amazon Web Services Region as the resource you're calling. Here's an example URI path: s3://DOC-EXAMPLE-BUCKET/my-vocab-file.txt
  --tags: list # Adds one or more custom tags, each in the form of a key:value pair, to a new custom medical vocabulary at the time you create this new custom vocabulary. To learn more about using tags with Amazon Transcribe, refer to Tagging resources (https://docs.aws.amazon.com/transcribe/latest/dg/tagging.html). — item shape: {Key: string, Value: string}
]: any -> oneof<record<VocabularyName: string, LanguageCode: string, VocabularyState: string, LastModifiedTime: string, FailureReason: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.CreateMedicalVocabulary")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"VocabularyName": $vocabulary_name, "LanguageCode": $language_code, "VocabularyFileUri": $vocabulary_file_uri, "Tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Creates a new custom vocabulary. When creating a new custom vocabulary, you can either upload a text file that contains your new entries, phrases, and terms into an Amazon S3 bucket and include the URI in your request. Or you can include a list of terms directly in your request using the Phrases flag. Each language has a character set that contains all allowed characters for that specific language. If you use unsupported characters, your custom vocabulary request fails. Refer to Character Sets for Custom Vocabularies (https://docs.aws.amazon.com/transcribe/latest/dg/charsets.html) to get the character set for your language. For more information, see Custom vocabularies (https://docs.aws.amazon.com/transcribe/latest/dg/custom-vocabulary.html).
#
# POST /
# operationId: CreateVocabulary
export def "create-vocabulary" [
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
  --x-amz-target: string@x-amz-target-completer-3 # required
  vocabulary_name: string # A unique name, chosen by you, for your new custom vocabulary. This name is case sensitive, cannot contain spaces, and must be unique within an Amazon Web Services account. If you try to create a new custom vocabulary with the same name as an existing custom vocabulary, you get a ConflictException error.
  language_code: string@language-code-completer-1 # The language code that represents the language of the entries in your custom vocabulary. Each custom vocabulary must contain terms in only one language. A custom vocabulary can only be used to transcribe files in the same language as the custom vocabulary. For example, if you create a custom vocabulary using US English (en-US), you can only apply this custom vocabulary to files that contain English audio. For a list of supported languages and their associated language codes, refer to the Supported languages (https://docs.aws.amazon.com/transcribe/latest/dg/supported-languages.html) table.
  --phrases: list<string> # Use this parameter if you want to create your custom vocabulary by including all desired terms, as comma-separated values, within your request. The other option for creating your custom vocabulary is to save your entries in a text file and upload them to an Amazon S3 bucket, then specify the location of your file using the VocabularyFileUri parameter. Note that if you include Phrases in your request, you cannot use VocabularyFileUri; you must choose one or the other. Each language has a character set that contains all allowed characters for that specific language. If you use unsupported characters, your custom vocabulary filter request fails. Refer to Character Sets for Custom Vocabularies (https://docs.aws.amazon.com/transcribe/latest/dg/charsets.html) to get the character set for your language.
  --vocabulary-file-uri: string # The Amazon S3 location of the text file that contains your custom vocabulary. The URI must be located in the same Amazon Web Services Region as the resource you're calling. Here's an example URI path: s3://DOC-EXAMPLE-BUCKET/my-vocab-file.txt Note that if you include VocabularyFileUri in your request, you cannot use the Phrases flag; you must choose one or the other.
  --tags: list # Adds one or more custom tags, each in the form of a key:value pair, to a new custom vocabulary at the time you create this new custom vocabulary. To learn more about using tags with Amazon Transcribe, refer to Tagging resources (https://docs.aws.amazon.com/transcribe/latest/dg/tagging.html). — item shape: {Key: string, Value: string}
  --data-access-role-arn: string # The Amazon Resource Name (ARN) of an IAM role that has permissions to access the Amazon S3 bucket that contains your input files (in this case, your custom vocabulary). If the role that you specify doesn’t have the appropriate permissions to access the specified Amazon S3 location, your request fails. IAM role ARNs have the format arn:partition:iam::account:role/role-name-with-path. For example: arn:aws:iam::111122223333:role/Admin. For more information, see IAM ARNs (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html#identifiers-arns).
]: any -> oneof<record<VocabularyName: string, LanguageCode: string, VocabularyState: string, LastModifiedTime: string, FailureReason: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.CreateVocabulary")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"VocabularyName": $vocabulary_name, "LanguageCode": $language_code, "Phrases": $phrases, "VocabularyFileUri": $vocabulary_file_uri, "Tags": $tags, "DataAccessRoleArn": $data_access_role_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Creates a new custom vocabulary filter. You can use custom vocabulary filters to mask, delete, or flag specific words from your transcript. Custom vocabulary filters are commonly used to mask profanity in transcripts. Each language has a character set that contains all allowed characters for that specific language. If you use unsupported characters, your custom vocabulary filter request fails. Refer to Character Sets for Custom Vocabularies (https://docs.aws.amazon.com/transcribe/latest/dg/charsets.html) to get the character set for your language. For more information, see Vocabulary filtering (https://docs.aws.amazon.com/transcribe/latest/dg/vocabulary-filtering.html).
#
# POST /
# operationId: CreateVocabularyFilter
export def "create-vocabulary-filter" [
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
  --x-amz-target: string@x-amz-target-completer-4 # required
  vocabulary_filter_name: string # A unique name, chosen by you, for your new custom vocabulary filter. This name is case sensitive, cannot contain spaces, and must be unique within an Amazon Web Services account. If you try to create a new custom vocabulary filter with the same name as an existing custom vocabulary filter, you get a ConflictException error.
  language_code: string@language-code-completer-1 # The language code that represents the language of the entries in your vocabulary filter. Each custom vocabulary filter must contain terms in only one language. A custom vocabulary filter can only be used to transcribe files in the same language as the filter. For example, if you create a custom vocabulary filter using US English (en-US), you can only apply this filter to files that contain English audio. For a list of supported languages and their associated language codes, refer to the Supported languages (https://docs.aws.amazon.com/transcribe/latest/dg/supported-languages.html) table.
  --words: list<string> # Use this parameter if you want to create your custom vocabulary filter by including all desired terms, as comma-separated values, within your request. The other option for creating your vocabulary filter is to save your entries in a text file and upload them to an Amazon S3 bucket, then specify the location of your file using the VocabularyFilterFileUri parameter. Note that if you include Words in your request, you cannot use VocabularyFilterFileUri; you must choose one or the other. Each language has a character set that contains all allowed characters for that specific language. If you use unsupported characters, your custom vocabulary filter request fails. Refer to Character Sets for Custom Vocabularies (https://docs.aws.amazon.com/transcribe/latest/dg/charsets.html) to get the character set for your language.
  --vocabulary-filter-file-uri: string # The Amazon S3 location of the text file that contains your custom vocabulary filter terms. The URI must be located in the same Amazon Web Services Region as the resource you're calling. Here's an example URI path: s3://DOC-EXAMPLE-BUCKET/my-vocab-filter-file.txt Note that if you include VocabularyFilterFileUri in your request, you cannot use Words; you must choose one or the other.
  --tags: list # Adds one or more custom tags, each in the form of a key:value pair, to a new custom vocabulary filter at the time you create this new vocabulary filter. To learn more about using tags with Amazon Transcribe, refer to Tagging resources (https://docs.aws.amazon.com/transcribe/latest/dg/tagging.html). — item shape: {Key: string, Value: string}
  --data-access-role-arn: string # The Amazon Resource Name (ARN) of an IAM role that has permissions to access the Amazon S3 bucket that contains your input files (in this case, your custom vocabulary filter). If the role that you specify doesn’t have the appropriate permissions to access the specified Amazon S3 location, your request fails. IAM role ARNs have the format arn:partition:iam::account:role/role-name-with-path. For example: arn:aws:iam::111122223333:role/Admin. For more information, see IAM ARNs (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html#identifiers-arns).
]: any -> oneof<record<VocabularyFilterName: string, LanguageCode: string, LastModifiedTime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.CreateVocabularyFilter")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"VocabularyFilterName": $vocabulary_filter_name, "LanguageCode": $language_code, "Words": $words, "VocabularyFilterFileUri": $vocabulary_filter_file_uri, "Tags": $tags, "DataAccessRoleArn": $data_access_role_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Deletes a Call Analytics category. To use this operation, specify the name of the category you want to delete using CategoryName. Category names are case sensitive.
#
# POST /
# operationId: DeleteCallAnalyticsCategory
export def "delete-call-analytics-category" [
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
  --x-amz-target: string@x-amz-target-completer-5 # required
  category_name: string # The name of the Call Analytics category you want to delete. Category names are case sensitive.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.DeleteCallAnalyticsCategory")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CategoryName": $category_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Deletes a Call Analytics job. To use this operation, specify the name of the job you want to delete using CallAnalyticsJobName. Job names are case sensitive.
#
# POST /
# operationId: DeleteCallAnalyticsJob
export def "delete-call-analytics-job" [
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
  --x-amz-target: string@x-amz-target-completer-6 # required
  call_analytics_job_name: string # The name of the Call Analytics job you want to delete. Job names are case sensitive.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.DeleteCallAnalyticsJob")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CallAnalyticsJobName": $call_analytics_job_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Deletes a custom language model. To use this operation, specify the name of the language model you want to delete using ModelName. custom language model names are case sensitive.
#
# POST /
# operationId: DeleteLanguageModel
export def "delete-language-model" [
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
  --x-amz-target: string@x-amz-target-completer-7 # required
  model_name: string # The name of the custom language model you want to delete. Model names are case sensitive.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.DeleteLanguageModel")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ModelName": $model_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Deletes a medical transcription job. To use this operation, specify the name of the job you want to delete using MedicalTranscriptionJobName. Job names are case sensitive.
#
# POST /
# operationId: DeleteMedicalTranscriptionJob
export def "delete-medical-transcription-job" [
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
  --x-amz-target: string@x-amz-target-completer-8 # required
  medical_transcription_job_name: string # The name of the medical transcription job you want to delete. Job names are case sensitive.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.DeleteMedicalTranscriptionJob")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"MedicalTranscriptionJobName": $medical_transcription_job_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Deletes a custom medical vocabulary. To use this operation, specify the name of the custom vocabulary you want to delete using VocabularyName. Custom vocabulary names are case sensitive.
#
# POST /
# operationId: DeleteMedicalVocabulary
export def "delete-medical-vocabulary" [
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
  --x-amz-target: string@x-amz-target-completer-9 # required
  vocabulary_name: string # The name of the custom medical vocabulary you want to delete. Custom medical vocabulary names are case sensitive.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.DeleteMedicalVocabulary")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"VocabularyName": $vocabulary_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Deletes a transcription job. To use this operation, specify the name of the job you want to delete using TranscriptionJobName. Job names are case sensitive.
#
# POST /
# operationId: DeleteTranscriptionJob
export def "delete-transcription-job" [
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
  --x-amz-target: string@x-amz-target-completer-10 # required
  transcription_job_name: string # The name of the transcription job you want to delete. Job names are case sensitive.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.DeleteTranscriptionJob")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TranscriptionJobName": $transcription_job_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Deletes a custom vocabulary. To use this operation, specify the name of the custom vocabulary you want to delete using VocabularyName. Custom vocabulary names are case sensitive.
#
# POST /
# operationId: DeleteVocabulary
export def "delete-vocabulary" [
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
  --x-amz-target: string@x-amz-target-completer-11 # required
  vocabulary_name: string # The name of the custom vocabulary you want to delete. Custom vocabulary names are case sensitive.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.DeleteVocabulary")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"VocabularyName": $vocabulary_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Deletes a custom vocabulary filter. To use this operation, specify the name of the custom vocabulary filter you want to delete using VocabularyFilterName. Custom vocabulary filter names are case sensitive.
#
# POST /
# operationId: DeleteVocabularyFilter
export def "delete-vocabulary-filter" [
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
  --x-amz-target: string@x-amz-target-completer-12 # required
  vocabulary_filter_name: string # The name of the custom vocabulary filter you want to delete. Custom vocabulary filter names are case sensitive.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.DeleteVocabularyFilter")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"VocabularyFilterName": $vocabulary_filter_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Provides information about the specified custom language model. This operation also shows if the base language model that you used to create your custom language model has been updated. If Amazon Transcribe has updated the base model, you can create a new custom language model using the updated base model. If you tried to create a new custom language model and the request wasn't successful, you can use DescribeLanguageModel to help identify the reason for this failure.
#
# POST /
# operationId: DescribeLanguageModel
export def "describe-language-model" [
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
  --x-amz-target: string@x-amz-target-completer-13 # required
  model_name: string # The name of the custom language model you want information about. Model names are case sensitive.
]: any -> oneof<record<LanguageModel: record<ModelName: string, CreateTime: string, LastModifiedTime: string, LanguageCode: string, BaseModelName: string, ModelStatus: string, UpgradeAvailability: bool, FailureReason: string, InputDataConfig: record<S3Uri: string, TuningDataS3Uri: string, DataAccessRoleArn: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.DescribeLanguageModel")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ModelName": $model_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Provides information about the specified Call Analytics category. To get a list of your Call Analytics categories, use the operation.
#
# POST /
# operationId: GetCallAnalyticsCategory
export def "get-call-analytics-category" [
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
  --x-amz-target: string@x-amz-target-completer-14 # required
  category_name: string # The name of the Call Analytics category you want information about. Category names are case sensitive.
]: any -> oneof<record<CategoryProperties: record<CategoryName: string, Rules: list<record>, CreateTime: string, LastUpdateTime: string, InputType: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.GetCallAnalyticsCategory")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CategoryName": $category_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Provides information about the specified Call Analytics job. To view the job's status, refer to CallAnalyticsJobStatus. If the status is COMPLETED, the job is finished. You can find your completed transcript at the URI specified in TranscriptFileUri. If the status is FAILED, FailureReason provides details on why your transcription job failed. If you enabled personally identifiable information (PII) redaction, the redacted transcript appears at the location specified in RedactedTranscriptFileUri. If you chose to redact the audio in your media file, you can find your redacted media file at the location specified in RedactedMediaFileUri. To get a list of your Call Analytics jobs, use the operation.
#
# POST /
# operationId: GetCallAnalyticsJob
export def "get-call-analytics-job" [
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
  --x-amz-target: string@x-amz-target-completer-15 # required
  call_analytics_job_name: string # The name of the Call Analytics job you want information about. Job names are case sensitive.
]: any -> oneof<record<CallAnalyticsJob: record<CallAnalyticsJobName: string, CallAnalyticsJobStatus: string, LanguageCode: string, MediaSampleRateHertz: int, MediaFormat: string, Media: record<MediaFileUri: string, RedactedMediaFileUri: string>, Transcript: record<TranscriptFileUri: string, RedactedTranscriptFileUri: string>, StartTime: string, CreationTime: string, CompletionTime: string, FailureReason: string, DataAccessRoleArn: string, IdentifiedLanguageScore: float, Settings: record<VocabularyName: string, VocabularyFilterName: string, VocabularyFilterMethod: string, LanguageModelName: string, ContentRedaction: record, LanguageOptions: list, LanguageIdSettings: record>, ChannelDefinitions: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.GetCallAnalyticsJob")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CallAnalyticsJobName": $call_analytics_job_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Provides information about the specified medical transcription job. To view the status of the specified medical transcription job, check the TranscriptionJobStatus field. If the status is COMPLETED, the job is finished. You can find the results at the location specified in TranscriptFileUri. If the status is FAILED, FailureReason provides details on why your transcription job failed. To get a list of your medical transcription jobs, use the operation.
#
# POST /
# operationId: GetMedicalTranscriptionJob
export def "get-medical-transcription-job" [
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  medical_transcription_job_name: string # The name of the medical transcription job you want information about. Job names are case sensitive.
]: any -> oneof<record<MedicalTranscriptionJob: record<MedicalTranscriptionJobName: string, TranscriptionJobStatus: string, LanguageCode: string, MediaSampleRateHertz: int, MediaFormat: string, Media: record<MediaFileUri: string, RedactedMediaFileUri: string>, Transcript: record<TranscriptFileUri: string>, StartTime: string, CreationTime: string, CompletionTime: string, FailureReason: string, Settings: record<ShowSpeakerLabels: bool, MaxSpeakerLabels: int, ChannelIdentification: bool, ShowAlternatives: bool, MaxAlternatives: int, VocabularyName: string>, ContentIdentificationType: string, Specialty: string, Type: string, Tags: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.GetMedicalTranscriptionJob")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"MedicalTranscriptionJobName": $medical_transcription_job_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Provides information about the specified custom medical vocabulary. To view the status of the specified custom medical vocabulary, check the VocabularyState field. If the status is READY, your custom vocabulary is available to use. If the status is FAILED, FailureReason provides details on why your vocabulary failed. To get a list of your custom medical vocabularies, use the operation.
#
# POST /
# operationId: GetMedicalVocabulary
export def "get-medical-vocabulary" [
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  vocabulary_name: string # The name of the custom medical vocabulary you want information about. Custom medical vocabulary names are case sensitive.
]: any -> oneof<record<VocabularyName: string, LanguageCode: string, VocabularyState: string, LastModifiedTime: string, FailureReason: string, DownloadUri: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.GetMedicalVocabulary")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"VocabularyName": $vocabulary_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Provides information about the specified transcription job. To view the status of the specified transcription job, check the TranscriptionJobStatus field. If the status is COMPLETED, the job is finished. You can find the results at the location specified in TranscriptFileUri. If the status is FAILED, FailureReason provides details on why your transcription job failed. If you enabled content redaction, the redacted transcript can be found at the location specified in RedactedTranscriptFileUri. To get a list of your transcription jobs, use the operation.
#
# POST /
# operationId: GetTranscriptionJob
export def "get-transcription-job" [
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  transcription_job_name: string # The name of the transcription job you want information about. Job names are case sensitive.
]: any -> oneof<record<TranscriptionJob: record<TranscriptionJobName: string, TranscriptionJobStatus: string, LanguageCode: string, MediaSampleRateHertz: int, MediaFormat: string, Media: record<MediaFileUri: string, RedactedMediaFileUri: string>, Transcript: record<TranscriptFileUri: string, RedactedTranscriptFileUri: string>, StartTime: string, CreationTime: string, CompletionTime: string, FailureReason: string, Settings: record<VocabularyName: string, ShowSpeakerLabels: bool, MaxSpeakerLabels: int, ChannelIdentification: bool, ShowAlternatives: bool, MaxAlternatives: int, VocabularyFilterName: string, VocabularyFilterMethod: string>, ModelSettings: record<LanguageModelName: string>, JobExecutionSettings: record<AllowDeferredExecution: bool, DataAccessRoleArn: string>, ContentRedaction: record<RedactionType: string, RedactionOutput: string, PiiEntityTypes: list>, IdentifyLanguage: bool, IdentifyMultipleLanguages: bool, LanguageOptions: list<string>, IdentifiedLanguageScore: float, LanguageCodes: list<record>, Tags: list<record>, Subtitles: record<Formats: list, SubtitleFileUris: list, OutputStartIndex: int>, LanguageIdSettings: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.GetTranscriptionJob")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TranscriptionJobName": $transcription_job_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Provides information about the specified custom vocabulary. To view the status of the specified custom vocabulary, check the VocabularyState field. If the status is READY, your custom vocabulary is available to use. If the status is FAILED, FailureReason provides details on why your custom vocabulary failed. To get a list of your custom vocabularies, use the operation.
#
# POST /
# operationId: GetVocabulary
export def "get-vocabulary" [
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  vocabulary_name: string # The name of the custom vocabulary you want information about. Custom vocabulary names are case sensitive.
]: any -> oneof<record<VocabularyName: string, LanguageCode: string, VocabularyState: string, LastModifiedTime: string, FailureReason: string, DownloadUri: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.GetVocabulary")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"VocabularyName": $vocabulary_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Provides information about the specified custom vocabulary filter. To get a list of your custom vocabulary filters, use the operation.
#
# POST /
# operationId: GetVocabularyFilter
export def "get-vocabulary-filter" [
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
  --x-amz-target: string@x-amz-target-completer-20 # required
  vocabulary_filter_name: string # The name of the custom vocabulary filter you want information about. Custom vocabulary filter names are case sensitive.
]: any -> oneof<record<VocabularyFilterName: string, LanguageCode: string, LastModifiedTime: string, DownloadUri: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.GetVocabularyFilter")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"VocabularyFilterName": $vocabulary_filter_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Provides a list of Call Analytics categories, including all rules that make up each category. To get detailed information about a specific Call Analytics category, use the operation.
#
# POST /
# operationId: ListCallAnalyticsCategories
export def "list-call-analytics-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-21 # required
  --body-next-token: string # If your ListCallAnalyticsCategories request returns more results than can be displayed, NextToken is displayed in the response with an associated string. To get the next page of results, copy this string and repeat your request, including NextToken with the value of the copied string. Repeat as needed to view all your results. (spec name: NextToken)
  --body-max-results: int # The maximum number of Call Analytics categories to return in each page of results. If there are fewer results than the value that you specify, only the actual results are returned. If you don't specify a value, a default of 5 is used. (spec name: MaxResults)
]: any -> oneof<record<NextToken: string, Categories: table<CategoryName: string, Rules: list, CreateTime: string, LastUpdateTime: string, InputType: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.ListCallAnalyticsCategories")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Provides a list of Call Analytics jobs that match the specified criteria. If no criteria are specified, all Call Analytics jobs are returned. To get detailed information about a specific Call Analytics job, use the operation.
#
# POST /
# operationId: ListCallAnalyticsJobs
export def "list-call-analytics-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-22 # required
  --status: string@status-completer # Returns only Call Analytics jobs with the specified status. Jobs are ordered by creation date, with the newest job first. If you don't include Status, all Call Analytics jobs are returned.
  --job-name-contains: string # Returns only the Call Analytics jobs that contain the specified string. The search is not case sensitive.
  --body-next-token: string # If your ListCallAnalyticsJobs request returns more results than can be displayed, NextToken is displayed in the response with an associated string. To get the next page of results, copy this string and repeat your request, including NextToken with the value of the copied string. Repeat as needed to view all your results. (spec name: NextToken)
  --body-max-results: int # The maximum number of Call Analytics jobs to return in each page of results. If there are fewer results than the value that you specify, only the actual results are returned. If you don't specify a value, a default of 5 is used. (spec name: MaxResults)
]: any -> oneof<record<Status: string, NextToken: string, CallAnalyticsJobSummaries: table<CallAnalyticsJobName: string, CreationTime: string, StartTime: string, CompletionTime: string, LanguageCode: string, CallAnalyticsJobStatus: string, FailureReason: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.ListCallAnalyticsJobs")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Status": $status, "JobNameContains": $job_name_contains, "NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Provides a list of custom language models that match the specified criteria. If no criteria are specified, all custom language models are returned. To get detailed information about a specific custom language model, use the operation.
#
# POST /
# operationId: ListLanguageModels
export def "list-language-models" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-23 # required
  --status-equals: string@status-equals-completer # Returns only custom language models with the specified status. Language models are ordered by creation date, with the newest model first. If you don't include StatusEquals, all custom language models are returned.
  --name-contains: string # Returns only the custom language models that contain the specified string. The search is not case sensitive.
  --body-next-token: string # If your ListLanguageModels request returns more results than can be displayed, NextToken is displayed in the response with an associated string. To get the next page of results, copy this string and repeat your request, including NextToken with the value of the copied string. Repeat as needed to view all your results. (spec name: NextToken)
  --body-max-results: int # The maximum number of custom language models to return in each page of results. If there are fewer results than the value that you specify, only the actual results are returned. If you don't specify a value, a default of 5 is used. (spec name: MaxResults)
]: any -> oneof<record<NextToken: string, Models: table<ModelName: string, CreateTime: string, LastModifiedTime: string, LanguageCode: string, BaseModelName: string, ModelStatus: string, UpgradeAvailability: bool, FailureReason: string, InputDataConfig: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.ListLanguageModels")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"StatusEquals": $status_equals, "NameContains": $name_contains, "NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Provides a list of medical transcription jobs that match the specified criteria. If no criteria are specified, all medical transcription jobs are returned. To get detailed information about a specific medical transcription job, use the operation.
#
# POST /
# operationId: ListMedicalTranscriptionJobs
export def "list-medical-transcription-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-24 # required
  --status: string@status-completer # Returns only medical transcription jobs with the specified status. Jobs are ordered by creation date, with the newest job first. If you don't include Status, all medical transcription jobs are returned.
  --job-name-contains: string # Returns only the medical transcription jobs that contain the specified string. The search is not case sensitive.
  --body-next-token: string # If your ListMedicalTranscriptionJobs request returns more results than can be displayed, NextToken is displayed in the response with an associated string. To get the next page of results, copy this string and repeat your request, including NextToken with the value of the copied string. Repeat as needed to view all your results. (spec name: NextToken)
  --body-max-results: int # The maximum number of medical transcription jobs to return in each page of results. If there are fewer results than the value that you specify, only the actual results are returned. If you don't specify a value, a default of 5 is used. (spec name: MaxResults)
]: any -> oneof<record<Status: string, NextToken: string, MedicalTranscriptionJobSummaries: table<MedicalTranscriptionJobName: string, CreationTime: string, StartTime: string, CompletionTime: string, LanguageCode: string, TranscriptionJobStatus: string, FailureReason: string, OutputLocationType: string, Specialty: string, ContentIdentificationType: string, Type: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.ListMedicalTranscriptionJobs")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Status": $status, "JobNameContains": $job_name_contains, "NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Provides a list of custom medical vocabularies that match the specified criteria. If no criteria are specified, all custom medical vocabularies are returned. To get detailed information about a specific custom medical vocabulary, use the operation.
#
# POST /
# operationId: ListMedicalVocabularies
export def "list-medical-vocabularies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-25 # required
  --body-next-token: string # If your ListMedicalVocabularies request returns more results than can be displayed, NextToken is displayed in the response with an associated string. To get the next page of results, copy this string and repeat your request, including NextToken with the value of the copied string. Repeat as needed to view all your results. (spec name: NextToken)
  --body-max-results: int # The maximum number of custom medical vocabularies to return in each page of results. If there are fewer results than the value that you specify, only the actual results are returned. If you don't specify a value, a default of 5 is used. (spec name: MaxResults)
  --state-equals: string@state-equals-completer # Returns only custom medical vocabularies with the specified state. Custom vocabularies are ordered by creation date, with the newest vocabulary first. If you don't include StateEquals, all custom medical vocabularies are returned.
  --name-contains: string # Returns only the custom medical vocabularies that contain the specified string. The search is not case sensitive.
]: any -> oneof<record<Status: string, NextToken: string, Vocabularies: table<VocabularyName: string, LanguageCode: string, LastModifiedTime: string, VocabularyState: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.ListMedicalVocabularies")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"NextToken": $body_next_token, "MaxResults": $body_max_results, "StateEquals": $state_equals, "NameContains": $name_contains} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists all tags associated with the specified transcription job, vocabulary, model, or resource. To learn more about using tags with Amazon Transcribe, refer to Tagging resources (https://docs.aws.amazon.com/transcribe/latest/dg/tagging.html).
#
# POST /
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
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
  --x-amz-target: string@x-amz-target-completer-26 # required
  resource_arn: string # Returns a list of all tags associated with the specified Amazon Resource Name (ARN). ARNs have the format arn:partition:service:region:account-id:resource-type/resource-id. For example, arn:aws:transcribe:us-west-2:111122223333:transcription-job/transcription-job-name. Valid values for resource-type are: transcription-job, medical-transcription-job, vocabulary, medical-vocabulary, vocabulary-filter, and language-model.
]: any -> oneof<record<ResourceArn: string, Tags: table<Key: string, Value: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.ListTagsForResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Provides a list of transcription jobs that match the specified criteria. If no criteria are specified, all transcription jobs are returned. To get detailed information about a specific transcription job, use the operation.
#
# POST /
# operationId: ListTranscriptionJobs
export def "list-transcription-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-27 # required
  --status: string@status-completer # Returns only transcription jobs with the specified status. Jobs are ordered by creation date, with the newest job first. If you don't include Status, all transcription jobs are returned.
  --job-name-contains: string # Returns only the transcription jobs that contain the specified string. The search is not case sensitive.
  --body-next-token: string # If your ListTranscriptionJobs request returns more results than can be displayed, NextToken is displayed in the response with an associated string. To get the next page of results, copy this string and repeat your request, including NextToken with the value of the copied string. Repeat as needed to view all your results. (spec name: NextToken)
  --body-max-results: int # The maximum number of transcription jobs to return in each page of results. If there are fewer results than the value that you specify, only the actual results are returned. If you don't specify a value, a default of 5 is used. (spec name: MaxResults)
]: any -> oneof<record<Status: string, NextToken: string, TranscriptionJobSummaries: table<TranscriptionJobName: string, CreationTime: string, StartTime: string, CompletionTime: string, LanguageCode: string, TranscriptionJobStatus: string, FailureReason: string, OutputLocationType: string, ContentRedaction: record, ModelSettings: record, IdentifyLanguage: bool, IdentifyMultipleLanguages: bool, IdentifiedLanguageScore: float, LanguageCodes: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.ListTranscriptionJobs")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Status": $status, "JobNameContains": $job_name_contains, "NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Provides a list of custom vocabularies that match the specified criteria. If no criteria are specified, all custom vocabularies are returned. To get detailed information about a specific custom vocabulary, use the operation.
#
# POST /
# operationId: ListVocabularies
export def "list-vocabularies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-28 # required
  --body-next-token: string # If your ListVocabularies request returns more results than can be displayed, NextToken is displayed in the response with an associated string. To get the next page of results, copy this string and repeat your request, including NextToken with the value of the copied string. Repeat as needed to view all your results. (spec name: NextToken)
  --body-max-results: int # The maximum number of custom vocabularies to return in each page of results. If there are fewer results than the value that you specify, only the actual results are returned. If you don't specify a value, a default of 5 is used. (spec name: MaxResults)
  --state-equals: string@state-equals-completer # Returns only custom vocabularies with the specified state. Vocabularies are ordered by creation date, with the newest vocabulary first. If you don't include StateEquals, all custom medical vocabularies are returned.
  --name-contains: string # Returns only the custom vocabularies that contain the specified string. The search is not case sensitive.
]: any -> oneof<record<Status: string, NextToken: string, Vocabularies: table<VocabularyName: string, LanguageCode: string, LastModifiedTime: string, VocabularyState: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.ListVocabularies")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"NextToken": $body_next_token, "MaxResults": $body_max_results, "StateEquals": $state_equals, "NameContains": $name_contains} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Provides a list of custom vocabulary filters that match the specified criteria. If no criteria are specified, all custom vocabularies are returned. To get detailed information about a specific custom vocabulary filter, use the operation.
#
# POST /
# operationId: ListVocabularyFilters
export def "list-vocabulary-filters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-29 # required
  --body-next-token: string # If your ListVocabularyFilters request returns more results than can be displayed, NextToken is displayed in the response with an associated string. To get the next page of results, copy this string and repeat your request, including NextToken with the value of the copied string. Repeat as needed to view all your results. (spec name: NextToken)
  --body-max-results: int # The maximum number of custom vocabulary filters to return in each page of results. If there are fewer results than the value that you specify, only the actual results are returned. If you don't specify a value, a default of 5 is used. (spec name: MaxResults)
  --name-contains: string # Returns only the custom vocabulary filters that contain the specified string. The search is not case sensitive.
]: any -> oneof<record<NextToken: string, VocabularyFilters: table<VocabularyFilterName: string, LanguageCode: string, LastModifiedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.ListVocabularyFilters")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"NextToken": $body_next_token, "MaxResults": $body_max_results, "NameContains": $name_contains} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Transcribes the audio from a customer service call and applies any additional Request Parameters you choose to include in your request. In addition to many standard transcription features, Call Analytics provides you with call characteristics, call summarization, speaker sentiment, and optional redaction of your text transcript and your audio file. You can also apply custom categories to flag specified conditions. To learn more about these features and insights, refer to Analyzing call center audio with Call Analytics (https://docs.aws.amazon.com/transcribe/latest/dg/call-analytics.html). If you want to apply categories to your Call Analytics job, you must create them before submitting your job request. Categories cannot be retroactively applied to a job. To create a new category, use the operation. To learn more about Call Analytics categories, see Creating categories for post-call transcriptions (https://docs.aws.amazon.com/transcribe/latest/dg/tca-categories-batch.html) and Creating categories for real-time transcriptions (https://docs.aws.amazon.com/transcribe/latest/dg/tca-categories-stream.html). To make a StartCallAnalyticsJob request, you must first upload your media file into an Amazon S3 bucket; you can then specify the Amazon S3 location of the file using the Media parameter. Note that job queuing is enabled by default for Call Analytics jobs. You must include the following parameters in your StartCallAnalyticsJob request: region: The Amazon Web Services Region where you are making your request. For a list of Amazon Web Services Regions supported with Amazon Transcribe, refer to Amazon Transcribe endpoints and quotas (https://docs.aws.amazon.com/general/latest/gr/transcribe.html). CallAnalyticsJobName: A custom name that you create for your transcription job that's unique within your Amazon Web Services account. DataAccessRoleArn: The Amazon Resource Name (ARN) of an IAM role that has permissions to access the Amazon S3 bucket that contains your input files. Media (MediaFileUri or RedactedMediaFileUri): The Amazon S3 location of your media file. With Call Analytics, you can redact the audio contained in your media file by including RedactedMediaFileUri, instead of MediaFileUri, to specify the location of your input audio. If you choose to redact your audio, you can find your redacted media at the location specified in the RedactedMediaFileUri field of your response.
#
# POST /
# operationId: StartCallAnalyticsJob
export def "start-call-analytics-job" [
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
  --x-amz-target: string@x-amz-target-completer-30 # required
  call_analytics_job_name: string # A unique name, chosen by you, for your Call Analytics job. This name is case sensitive, cannot contain spaces, and must be unique within an Amazon Web Services account. If you try to create a new job with the same name as an existing job, you get a ConflictException error.
  media: record # Describes the Amazon S3 location of the media file you want to use in your request. For information on supported media formats, refer to the MediaFormat (https://docs.aws.amazon.com/APIReference/API_StartTranscriptionJob.html#transcribe-StartTranscriptionJob-request-MediaFormat) parameter or the Media formats (https://docs.aws.amazon.com/transcribe/latest/dg/how-input.html#how-input-audio) section in the Amazon S3 Developer Guide. — shape: {MediaFileUri?: string, RedactedMediaFileUri?: string}
  --output-location: string # The Amazon S3 location where you want your Call Analytics transcription output stored. You can use any of the following formats to specify the output location: s3://DOC-EXAMPLE-BUCKET s3://DOC-EXAMPLE-BUCKET/my-output-folder/ s3://DOC-EXAMPLE-BUCKET/my-output-folder/my-call-analytics-job.json Unless you specify a file name (option 3), the name of your output file has a default value that matches the name you specified for your transcription job using the CallAnalyticsJobName parameter. You can specify a KMS key to encrypt your output using the OutputEncryptionKMSKeyId parameter. If you don't specify a KMS key, Amazon Transcribe uses the default Amazon S3 key for server-side encryption. If you don't specify OutputLocation, your transcript is placed in a service-managed Amazon S3 bucket and you are provided with a URI to access your transcript.
  --output-encryption-kms-key-id: string # The KMS key you want to use to encrypt your Call Analytics output. If using a key located in the current Amazon Web Services account, you can specify your KMS key in one of four ways: Use the KMS key ID itself. For example, 1234abcd-12ab-34cd-56ef-1234567890ab. Use an alias for the KMS key ID. For example, alias/ExampleAlias. Use the Amazon Resource Name (ARN) for the KMS key ID. For example, arn:aws:kms:region:account-ID:key/1234abcd-12ab-34cd-56ef-1234567890ab. Use the ARN for the KMS key alias. For example, arn:aws:kms:region:account-ID:alias/ExampleAlias. If using a key located in a different Amazon Web Services account than the current Amazon Web Services account, you can specify your KMS key in one of two ways: Use the ARN for the KMS key ID. For example, arn:aws:kms:region:account-ID:key/1234abcd-12ab-34cd-56ef-1234567890ab. Use the ARN for the KMS key alias. For example, arn:aws:kms:region:account-ID:alias/ExampleAlias. If you don't specify an encryption key, your output is encrypted with the default Amazon S3 key (SSE-S3). If you specify a KMS key to encrypt your output, you must also specify an output location using the OutputLocation parameter. Note that the role making the request must have permission to use the specified KMS key.
  --data-access-role-arn: string # The Amazon Resource Name (ARN) of an IAM role that has permissions to access the Amazon S3 bucket that contains your input files. If the role that you specify doesn’t have the appropriate permissions to access the specified Amazon S3 location, your request fails. IAM role ARNs have the format arn:partition:iam::account:role/role-name-with-path. For example: arn:aws:iam::111122223333:role/Admin. For more information, see IAM ARNs (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html#identifiers-arns).
  --settings: record # Provides additional optional settings for your request, including content redaction, automatic language identification; allows you to apply custom language models, custom vocabulary filters, and custom vocabularies. — shape: {VocabularyName?: string, VocabularyFilterName?: string, VocabularyFilterMethod?: "remove"|"mask"|"tag", LanguageModelName?: string, ContentRedaction?: record, LanguageOptions?: list<string>, LanguageIdSettings?: record}
  --channel-definitions: list # Makes it possible to specify which speaker is on which channel. For example, if your agent is the first participant to speak, you would set ChannelId to 0 (to indicate the first channel) and ParticipantRole to AGENT (to indicate that it's the agent speaking). — item shape: {ChannelId?: int, ParticipantRole?: "AGENT"|"CUSTOMER"}
]: any -> oneof<record<CallAnalyticsJob: record<CallAnalyticsJobName: string, CallAnalyticsJobStatus: string, LanguageCode: string, MediaSampleRateHertz: int, MediaFormat: string, Media: record<MediaFileUri: string, RedactedMediaFileUri: string>, Transcript: record<TranscriptFileUri: string, RedactedTranscriptFileUri: string>, StartTime: string, CreationTime: string, CompletionTime: string, FailureReason: string, DataAccessRoleArn: string, IdentifiedLanguageScore: float, Settings: record<VocabularyName: string, VocabularyFilterName: string, VocabularyFilterMethod: string, LanguageModelName: string, ContentRedaction: record, LanguageOptions: list, LanguageIdSettings: record>, ChannelDefinitions: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.StartCallAnalyticsJob")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CallAnalyticsJobName": $call_analytics_job_name, "Media": $media, "OutputLocation": $output_location, "OutputEncryptionKMSKeyId": $output_encryption_kms_key_id, "DataAccessRoleArn": $data_access_role_arn, "Settings": $settings, "ChannelDefinitions": $channel_definitions} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Transcribes the audio from a medical dictation or conversation and applies any additional Request Parameters you choose to include in your request. In addition to many standard transcription features, Amazon Transcribe Medical provides you with a robust medical vocabulary and, optionally, content identification, which adds flags to personal health information (PHI). To learn more about these features, refer to How Amazon Transcribe Medical works (https://docs.aws.amazon.com/transcribe/latest/dg/how-it-works-med.html). To make a StartMedicalTranscriptionJob request, you must first upload your media file into an Amazon S3 bucket; you can then specify the S3 location of the file using the Media parameter. You must include the following parameters in your StartMedicalTranscriptionJob request: region: The Amazon Web Services Region where you are making your request. For a list of Amazon Web Services Regions supported with Amazon Transcribe, refer to Amazon Transcribe endpoints and quotas (https://docs.aws.amazon.com/general/latest/gr/transcribe.html). MedicalTranscriptionJobName: A custom name you create for your transcription job that is unique within your Amazon Web Services account. Media (MediaFileUri): The Amazon S3 location of your media file. LanguageCode: This must be en-US. OutputBucketName: The Amazon S3 bucket where you want your transcript stored. If you want your output stored in a sub-folder of this bucket, you must also include OutputKey. Specialty: This must be PRIMARYCARE. Type: Choose whether your audio is a conversation or a dictation.
#
# POST /
# operationId: StartMedicalTranscriptionJob
export def "start-medical-transcription-job" [
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
  --x-amz-target: string@x-amz-target-completer-31 # required
  medical_transcription_job_name: string # A unique name, chosen by you, for your medical transcription job. The name that you specify is also used as the default name of your transcription output file. If you want to specify a different name for your transcription output, use the OutputKey parameter. This name is case sensitive, cannot contain spaces, and must be unique within an Amazon Web Services account. If you try to create a new job with the same name as an existing job, you get a ConflictException error.
  language_code: string@language-code-completer-1 # The language code that represents the language spoken in the input media file. US English (en-US) is the only valid value for medical transcription jobs. Any other value you enter for language code results in a BadRequestException error.
  --media-sample-rate-hertz: int # The sample rate, in hertz, of the audio track in your input media file. If you don't specify the media sample rate, Amazon Transcribe Medical determines it for you. If you specify the sample rate, it must match the rate detected by Amazon Transcribe Medical; if there's a mismatch between the value that you specify and the value detected, your job fails. Therefore, in most cases, it's advised to omit MediaSampleRateHertz and let Amazon Transcribe Medical determine the sample rate.
  --media-format: string@media-format-completer # Specify the format of your input media file.
  media: record # Describes the Amazon S3 location of the media file you want to use in your request. For information on supported media formats, refer to the MediaFormat (https://docs.aws.amazon.com/APIReference/API_StartTranscriptionJob.html#transcribe-StartTranscriptionJob-request-MediaFormat) parameter or the Media formats (https://docs.aws.amazon.com/transcribe/latest/dg/how-input.html#how-input-audio) section in the Amazon S3 Developer Guide. — shape: {MediaFileUri?: string, RedactedMediaFileUri?: string}
  output_bucket_name: string # The name of the Amazon S3 bucket where you want your medical transcription output stored. Do not include the S3:// prefix of the specified bucket. If you want your output to go to a sub-folder of this bucket, specify it using the OutputKey parameter; OutputBucketName only accepts the name of a bucket. For example, if you want your output stored in S3://DOC-EXAMPLE-BUCKET, set OutputBucketName to DOC-EXAMPLE-BUCKET. However, if you want your output stored in S3://DOC-EXAMPLE-BUCKET/test-files/, set OutputBucketName to DOC-EXAMPLE-BUCKET and OutputKey to test-files/. Note that Amazon Transcribe must have permission to use the specified location. You can change Amazon S3 permissions using the Amazon Web Services Management Console (https://console.aws.amazon.com/s3). See also Permissions Required for IAM User Roles (https://docs.aws.amazon.com/transcribe/latest/dg/security_iam_id-based-policy-examples.html#auth-role-iam-user).
  --output-key: string # Use in combination with OutputBucketName to specify the output location of your transcript and, optionally, a unique name for your output file. The default name for your transcription output is the same as the name you specified for your medical transcription job (MedicalTranscriptionJobName). Here are some examples of how you can use OutputKey: If you specify 'DOC-EXAMPLE-BUCKET' as the OutputBucketName and 'my-transcript.json' as the OutputKey, your transcription output path is s3://DOC-EXAMPLE-BUCKET/my-transcript.json. If you specify 'my-first-transcription' as the MedicalTranscriptionJobName, 'DOC-EXAMPLE-BUCKET' as the OutputBucketName, and 'my-transcript' as the OutputKey, your transcription output path is s3://DOC-EXAMPLE-BUCKET/my-transcript/my-first-transcription.json. If you specify 'DOC-EXAMPLE-BUCKET' as the OutputBucketName and 'test-files/my-transcript.json' as the OutputKey, your transcription output path is s3://DOC-EXAMPLE-BUCKET/test-files/my-transcript.json. If you specify 'my-first-transcription' as the MedicalTranscriptionJobName, 'DOC-EXAMPLE-BUCKET' as the OutputBucketName, and 'test-files/my-transcript' as the OutputKey, your transcription output path is s3://DOC-EXAMPLE-BUCKET/test-files/my-transcript/my-first-transcription.json. If you specify the name of an Amazon S3 bucket sub-folder that doesn't exist, one is created for you.
  --output-encryption-kms-key-id: string # The KMS key you want to use to encrypt your medical transcription output. If using a key located in the current Amazon Web Services account, you can specify your KMS key in one of four ways: Use the KMS key ID itself. For example, 1234abcd-12ab-34cd-56ef-1234567890ab. Use an alias for the KMS key ID. For example, alias/ExampleAlias. Use the Amazon Resource Name (ARN) for the KMS key ID. For example, arn:aws:kms:region:account-ID:key/1234abcd-12ab-34cd-56ef-1234567890ab. Use the ARN for the KMS key alias. For example, arn:aws:kms:region:account-ID:alias/ExampleAlias. If using a key located in a different Amazon Web Services account than the current Amazon Web Services account, you can specify your KMS key in one of two ways: Use the ARN for the KMS key ID. For example, arn:aws:kms:region:account-ID:key/1234abcd-12ab-34cd-56ef-1234567890ab. Use the ARN for the KMS key alias. For example, arn:aws:kms:region:account-ID:alias/ExampleAlias. If you don't specify an encryption key, your output is encrypted with the default Amazon S3 key (SSE-S3). If you specify a KMS key to encrypt your output, you must also specify an output location using the OutputLocation parameter. Note that the role making the request must have permission to use the specified KMS key.
  --kms-encryption-context: record # A map of plain text, non-secret key:value pairs, known as encryption context pairs, that provide an added layer of security for your data. For more information, see KMS encryption context (https://docs.aws.amazon.com/transcribe/latest/dg/key-management.html#kms-context) and Asymmetric keys in KMS (https://docs.aws.amazon.com/transcribe/latest/dg/symmetric-asymmetric.html).
  --settings: record # Allows additional optional settings in your request, including channel identification, alternative transcriptions, and speaker partitioning. You can use that to apply custom vocabularies to your medical transcription job. — shape: {ShowSpeakerLabels?: bool, MaxSpeakerLabels?: int, ChannelIdentification?: bool, ShowAlternatives?: bool, MaxAlternatives?: int, VocabularyName?: string}
  --content-identification-type: string@content-identification-type-completer # Labels all personal health information (PHI) identified in your transcript. For more information, see Identifying personal health information (PHI) in a transcription (https://docs.aws.amazon.com/transcribe/latest/dg/phi-id.html).
  specialty: string@specialty-completer # Specify the predominant medical specialty represented in your media. For batch transcriptions, PRIMARYCARE is the only valid value. If you require additional specialties, refer to .
  type: string@type-completer # Specify whether your input media contains only one person (DICTATION) or contains a conversation between two people (CONVERSATION). For example, DICTATION could be used for a medical professional wanting to transcribe voice memos; CONVERSATION could be used for transcribing the doctor-patient dialogue during the patient's office visit.
  --tags: list # Adds one or more custom tags, each in the form of a key:value pair, to a new medical transcription job at the time you start this new job. To learn more about using tags with Amazon Transcribe, refer to Tagging resources (https://docs.aws.amazon.com/transcribe/latest/dg/tagging.html). — item shape: {Key: string, Value: string}
]: any -> oneof<record<MedicalTranscriptionJob: record<MedicalTranscriptionJobName: string, TranscriptionJobStatus: string, LanguageCode: string, MediaSampleRateHertz: int, MediaFormat: string, Media: record<MediaFileUri: string, RedactedMediaFileUri: string>, Transcript: record<TranscriptFileUri: string>, StartTime: string, CreationTime: string, CompletionTime: string, FailureReason: string, Settings: record<ShowSpeakerLabels: bool, MaxSpeakerLabels: int, ChannelIdentification: bool, ShowAlternatives: bool, MaxAlternatives: int, VocabularyName: string>, ContentIdentificationType: string, Specialty: string, Type: string, Tags: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.StartMedicalTranscriptionJob")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"MedicalTranscriptionJobName": $medical_transcription_job_name, "LanguageCode": $language_code, "MediaSampleRateHertz": $media_sample_rate_hertz, "MediaFormat": $media_format, "Media": $media, "OutputBucketName": $output_bucket_name, "OutputKey": $output_key, "OutputEncryptionKMSKeyId": $output_encryption_kms_key_id, "KMSEncryptionContext": $kms_encryption_context, "Settings": $settings, "ContentIdentificationType": $content_identification_type, "Specialty": $specialty, "Type": $type, "Tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Transcribes the audio from a media file and applies any additional Request Parameters you choose to include in your request. To make a StartTranscriptionJob request, you must first upload your media file into an Amazon S3 bucket; you can then specify the Amazon S3 location of the file using the Media parameter. You must include the following parameters in your StartTranscriptionJob request: region: The Amazon Web Services Region where you are making your request. For a list of Amazon Web Services Regions supported with Amazon Transcribe, refer to Amazon Transcribe endpoints and quotas (https://docs.aws.amazon.com/general/latest/gr/transcribe.html). TranscriptionJobName: A custom name you create for your transcription job that is unique within your Amazon Web Services account. Media (MediaFileUri): The Amazon S3 location of your media file. One of LanguageCode, IdentifyLanguage, or IdentifyMultipleLanguages: If you know the language of your media file, specify it using the LanguageCode parameter; you can find all valid language codes in the Supported languages (https://docs.aws.amazon.com/transcribe/latest/dg/supported-languages.html) table. If you don't know the languages spoken in your media, use either IdentifyLanguage or IdentifyMultipleLanguages and let Amazon Transcribe identify the languages for you.
#
# POST /
# operationId: StartTranscriptionJob
export def "start-transcription-job" [
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
  --x-amz-target: string@x-amz-target-completer-32 # required
  transcription_job_name: string # A unique name, chosen by you, for your transcription job. The name that you specify is also used as the default name of your transcription output file. If you want to specify a different name for your transcription output, use the OutputKey parameter. This name is case sensitive, cannot contain spaces, and must be unique within an Amazon Web Services account. If you try to create a new job with the same name as an existing job, you get a ConflictException error.
  --language-code: string@language-code-completer-1 # The language code that represents the language spoken in the input media file. If you're unsure of the language spoken in your media file, consider using IdentifyLanguage or IdentifyMultipleLanguages to enable automatic language identification. Note that you must include one of LanguageCode, IdentifyLanguage, or IdentifyMultipleLanguages in your request. If you include more than one of these parameters, your transcription job fails. For a list of supported languages and their associated language codes, refer to the Supported languages (https://docs.aws.amazon.com/transcribe/latest/dg/supported-languages.html) table. To transcribe speech in Modern Standard Arabic (ar-SA), your media file must be encoded at a sample rate of 16,000 Hz or higher.
  --media-sample-rate-hertz: int # The sample rate, in hertz, of the audio track in your input media file. If you don't specify the media sample rate, Amazon Transcribe determines it for you. If you specify the sample rate, it must match the rate detected by Amazon Transcribe. If there's a mismatch between the value that you specify and the value detected, your job fails. In most cases, you can omit MediaSampleRateHertz and let Amazon Transcribe determine the sample rate.
  --media-format: string@media-format-completer # Specify the format of your input media file.
  media: record # Describes the Amazon S3 location of the media file you want to use in your request. For information on supported media formats, refer to the MediaFormat (https://docs.aws.amazon.com/APIReference/API_StartTranscriptionJob.html#transcribe-StartTranscriptionJob-request-MediaFormat) parameter or the Media formats (https://docs.aws.amazon.com/transcribe/latest/dg/how-input.html#how-input-audio) section in the Amazon S3 Developer Guide. — shape: {MediaFileUri?: string, RedactedMediaFileUri?: string}
  --output-bucket-name: string # The name of the Amazon S3 bucket where you want your transcription output stored. Do not include the S3:// prefix of the specified bucket. If you want your output to go to a sub-folder of this bucket, specify it using the OutputKey parameter; OutputBucketName only accepts the name of a bucket. For example, if you want your output stored in S3://DOC-EXAMPLE-BUCKET, set OutputBucketName to DOC-EXAMPLE-BUCKET. However, if you want your output stored in S3://DOC-EXAMPLE-BUCKET/test-files/, set OutputBucketName to DOC-EXAMPLE-BUCKET and OutputKey to test-files/. Note that Amazon Transcribe must have permission to use the specified location. You can change Amazon S3 permissions using the Amazon Web Services Management Console (https://console.aws.amazon.com/s3). See also Permissions Required for IAM User Roles (https://docs.aws.amazon.com/transcribe/latest/dg/security_iam_id-based-policy-examples.html#auth-role-iam-user). If you don't specify OutputBucketName, your transcript is placed in a service-managed Amazon S3 bucket and you are provided with a URI to access your transcript.
  --output-key: string # Use in combination with OutputBucketName to specify the output location of your transcript and, optionally, a unique name for your output file. The default name for your transcription output is the same as the name you specified for your transcription job (TranscriptionJobName). Here are some examples of how you can use OutputKey: If you specify 'DOC-EXAMPLE-BUCKET' as the OutputBucketName and 'my-transcript.json' as the OutputKey, your transcription output path is s3://DOC-EXAMPLE-BUCKET/my-transcript.json. If you specify 'my-first-transcription' as the TranscriptionJobName, 'DOC-EXAMPLE-BUCKET' as the OutputBucketName, and 'my-transcript' as the OutputKey, your transcription output path is s3://DOC-EXAMPLE-BUCKET/my-transcript/my-first-transcription.json. If you specify 'DOC-EXAMPLE-BUCKET' as the OutputBucketName and 'test-files/my-transcript.json' as the OutputKey, your transcription output path is s3://DOC-EXAMPLE-BUCKET/test-files/my-transcript.json. If you specify 'my-first-transcription' as the TranscriptionJobName, 'DOC-EXAMPLE-BUCKET' as the OutputBucketName, and 'test-files/my-transcript' as the OutputKey, your transcription output path is s3://DOC-EXAMPLE-BUCKET/test-files/my-transcript/my-first-transcription.json. If you specify the name of an Amazon S3 bucket sub-folder that doesn't exist, one is created for you.
  --output-encryption-kms-key-id: string # The KMS key you want to use to encrypt your transcription output. If using a key located in the current Amazon Web Services account, you can specify your KMS key in one of four ways: Use the KMS key ID itself. For example, 1234abcd-12ab-34cd-56ef-1234567890ab. Use an alias for the KMS key ID. For example, alias/ExampleAlias. Use the Amazon Resource Name (ARN) for the KMS key ID. For example, arn:aws:kms:region:account-ID:key/1234abcd-12ab-34cd-56ef-1234567890ab. Use the ARN for the KMS key alias. For example, arn:aws:kms:region:account-ID:alias/ExampleAlias. If using a key located in a different Amazon Web Services account than the current Amazon Web Services account, you can specify your KMS key in one of two ways: Use the ARN for the KMS key ID. For example, arn:aws:kms:region:account-ID:key/1234abcd-12ab-34cd-56ef-1234567890ab. Use the ARN for the KMS key alias. For example, arn:aws:kms:region:account-ID:alias/ExampleAlias. If you don't specify an encryption key, your output is encrypted with the default Amazon S3 key (SSE-S3). If you specify a KMS key to encrypt your output, you must also specify an output location using the OutputLocation parameter. Note that the role making the request must have permission to use the specified KMS key.
  --kms-encryption-context: record # A map of plain text, non-secret key:value pairs, known as encryption context pairs, that provide an added layer of security for your data. For more information, see KMS encryption context (https://docs.aws.amazon.com/transcribe/latest/dg/key-management.html#kms-context) and Asymmetric keys in KMS (https://docs.aws.amazon.com/transcribe/latest/dg/symmetric-asymmetric.html).
  --settings: record # Allows additional optional settings in your request, including channel identification, alternative transcriptions, and speaker partitioning. You can use that to apply custom vocabularies to your transcription job. — shape: {VocabularyName?: string, ShowSpeakerLabels?: bool, MaxSpeakerLabels?: int, ChannelIdentification?: bool, ShowAlternatives?: bool, MaxAlternatives?: int, VocabularyFilterName?: string, VocabularyFilterMethod?: "remove"|"mask"|"tag"}
  --model-settings: record # Provides the name of the custom language model that was included in the specified transcription job. Only use ModelSettings with the LanguageModelName sub-parameter if you're not using automatic language identification (). If using LanguageIdSettings in your request, this parameter contains a LanguageModelName sub-parameter. — shape: {LanguageModelName?: string}
  --job-execution-settings: record # Makes it possible to control how your transcription job is processed. Currently, the only JobExecutionSettings modification you can choose is enabling job queueing using the AllowDeferredExecution sub-parameter. If you include JobExecutionSettings in your request, you must also include the sub-parameters: AllowDeferredExecution and DataAccessRoleArn. — shape: {AllowDeferredExecution?: bool, DataAccessRoleArn?: string}
  --content-redaction: record # Makes it possible to redact or flag specified personally identifiable information (PII) in your transcript. If you use ContentRedaction, you must also include the sub-parameters: PiiEntityTypes, RedactionOutput, and RedactionType. — shape: {RedactionType: "PII", RedactionOutput: "redacted"|"redacted_and_unredacted", PiiEntityTypes?: list<string>}
  --identify-language: oneof<nothing, bool> # Enables automatic language identification in your transcription job request. Use this parameter if your media file contains only one language. If your media contains multiple languages, use IdentifyMultipleLanguages instead. If you include IdentifyLanguage, you can optionally include a list of language codes, using LanguageOptions, that you think may be present in your media file. Including LanguageOptions restricts IdentifyLanguage to only the language options that you specify, which can improve transcription accuracy. If you want to apply a custom language model, a custom vocabulary, or a custom vocabulary filter to your automatic language identification request, include LanguageIdSettings with the relevant sub-parameters (VocabularyName, LanguageModelName, and VocabularyFilterName). If you include LanguageIdSettings, also include LanguageOptions. Note that you must include one of LanguageCode, IdentifyLanguage, or IdentifyMultipleLanguages in your request. If you include more than one of these parameters, your transcription job fails.
  --identify-multiple-languages: oneof<nothing, bool> # Enables automatic multi-language identification in your transcription job request. Use this parameter if your media file contains more than one language. If your media contains only one language, use IdentifyLanguage instead. If you include IdentifyMultipleLanguages, you can optionally include a list of language codes, using LanguageOptions, that you think may be present in your media file. Including LanguageOptions restricts IdentifyLanguage to only the language options that you specify, which can improve transcription accuracy. If you want to apply a custom vocabulary or a custom vocabulary filter to your automatic language identification request, include LanguageIdSettings with the relevant sub-parameters (VocabularyName and VocabularyFilterName). If you include LanguageIdSettings, also include LanguageOptions. Note that you must include one of LanguageCode, IdentifyLanguage, or IdentifyMultipleLanguages in your request. If you include more than one of these parameters, your transcription job fails.
  --language-options: list<string> # You can specify two or more language codes that represent the languages you think may be present in your media. Including more than five is not recommended. If you're unsure what languages are present, do not include this parameter. If you include LanguageOptions in your request, you must also include IdentifyLanguage. For more information, refer to Supported languages (https://docs.aws.amazon.com/transcribe/latest/dg/supported-languages.html). To transcribe speech in Modern Standard Arabic (ar-SA), your media file must be encoded at a sample rate of 16,000 Hz or higher.
  --subtitles: record # Generate subtitles for your media file with your transcription request. You can choose a start index of 0 or 1, and you can specify either WebVTT or SubRip (or both) as your output format. Note that your subtitle files are placed in the same location as your transcription output. — shape: {Formats?: list<string>, OutputStartIndex?: int}
  --tags: list # Adds one or more custom tags, each in the form of a key:value pair, to a new transcription job at the time you start this new job. To learn more about using tags with Amazon Transcribe, refer to Tagging resources (https://docs.aws.amazon.com/transcribe/latest/dg/tagging.html). — item shape: {Key: string, Value: string}
  --language-id-settings: record # If using automatic language identification in your request and you want to apply a custom language model, a custom vocabulary, or a custom vocabulary filter, include LanguageIdSettings with the relevant sub-parameters (VocabularyName, LanguageModelName, and VocabularyFilterName). Note that multi-language identification (IdentifyMultipleLanguages) doesn't support custom language models. LanguageIdSettings supports two to five language codes. Each language code you include can have an associated custom language model, custom vocabulary, and custom vocabulary filter. The language codes that you specify must match the languages of the associated custom language models, custom vocabularies, and custom vocabulary filters. It's recommended that you include LanguageOptions when using LanguageIdSettings to ensure that the correct language dialect is identified. For example, if you specify a custom vocabulary that is in en-US but Amazon Transcribe determines that the language spoken in your media is en-AU, your custom vocabulary is not applied to your transcription. If you include LanguageOptions and include en-US as the only English language dialect, your custom vocabulary is applied to your transcription. If you want to include a custom language model with your request but do not want to use automatic language identification, use instead the parameter with the LanguageModelName sub-parameter. If you want to include a custom vocabulary or a custom vocabulary filter (or both) with your request but do not want to use automatic language identification, use instead the parameter with the VocabularyName or VocabularyFilterName (or both) sub-parameter.
]: any -> oneof<record<TranscriptionJob: record<TranscriptionJobName: string, TranscriptionJobStatus: string, LanguageCode: string, MediaSampleRateHertz: int, MediaFormat: string, Media: record<MediaFileUri: string, RedactedMediaFileUri: string>, Transcript: record<TranscriptFileUri: string, RedactedTranscriptFileUri: string>, StartTime: string, CreationTime: string, CompletionTime: string, FailureReason: string, Settings: record<VocabularyName: string, ShowSpeakerLabels: bool, MaxSpeakerLabels: int, ChannelIdentification: bool, ShowAlternatives: bool, MaxAlternatives: int, VocabularyFilterName: string, VocabularyFilterMethod: string>, ModelSettings: record<LanguageModelName: string>, JobExecutionSettings: record<AllowDeferredExecution: bool, DataAccessRoleArn: string>, ContentRedaction: record<RedactionType: string, RedactionOutput: string, PiiEntityTypes: list>, IdentifyLanguage: bool, IdentifyMultipleLanguages: bool, LanguageOptions: list<string>, IdentifiedLanguageScore: float, LanguageCodes: list<record>, Tags: list<record>, Subtitles: record<Formats: list, SubtitleFileUris: list, OutputStartIndex: int>, LanguageIdSettings: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.StartTranscriptionJob")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TranscriptionJobName": $transcription_job_name, "LanguageCode": $language_code, "MediaSampleRateHertz": $media_sample_rate_hertz, "MediaFormat": $media_format, "Media": $media, "OutputBucketName": $output_bucket_name, "OutputKey": $output_key, "OutputEncryptionKMSKeyId": $output_encryption_kms_key_id, "KMSEncryptionContext": $kms_encryption_context, "Settings": $settings, "ModelSettings": $model_settings, "JobExecutionSettings": $job_execution_settings, "ContentRedaction": $content_redaction, "IdentifyLanguage": $identify_language, "IdentifyMultipleLanguages": $identify_multiple_languages, "LanguageOptions": $language_options, "Subtitles": $subtitles, "Tags": $tags, "LanguageIdSettings": $language_id_settings} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Adds one or more custom tags, each in the form of a key:value pair, to the specified resource. To learn more about using tags with Amazon Transcribe, refer to Tagging resources (https://docs.aws.amazon.com/transcribe/latest/dg/tagging.html).
#
# POST /
# operationId: TagResource
export def "tag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-33 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource you want to tag. ARNs have the format arn:partition:service:region:account-id:resource-type/resource-id. For example, arn:aws:transcribe:us-west-2:111122223333:transcription-job/transcription-job-name. Valid values for resource-type are: transcription-job, medical-transcription-job, vocabulary, medical-vocabulary, vocabulary-filter, and language-model.
  tags: list # Adds one or more custom tags, each in the form of a key:value pair, to the specified resource. To learn more about using tags with Amazon Transcribe, refer to Tagging resources (https://docs.aws.amazon.com/transcribe/latest/dg/tagging.html). — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.TagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "Tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Removes the specified tags from the specified Amazon Transcribe resource. If you include UntagResource in your request, you must also include ResourceArn and TagKeys.
#
# POST /
# operationId: UntagResource
export def "untag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-34 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the Amazon Transcribe resource you want to remove tags from. ARNs have the format arn:partition:service:region:account-id:resource-type/resource-id. For example, arn:aws:transcribe:us-west-2:111122223333:transcription-job/transcription-job-name. Valid values for resource-type are: transcription-job, medical-transcription-job, vocabulary, medical-vocabulary, vocabulary-filter, and language-model.
  tag_keys: list<string> # Removes the specified tag keys from the specified Amazon Transcribe resource.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.UntagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "TagKeys": $tag_keys} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Updates the specified Call Analytics category with new rules. Note that the UpdateCallAnalyticsCategory operation overwrites all existing rules contained in the specified category. You cannot append additional rules onto an existing category. To create a new category, see .
#
# POST /
# operationId: UpdateCallAnalyticsCategory
export def "update-call-analytics-category" [
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
  --x-amz-target: string@x-amz-target-completer-35 # required
  category_name: string # The name of the Call Analytics category you want to update. Category names are case sensitive.
  rules: list # The rules used for the updated Call Analytics category. The rules you provide in this field replace the ones that are currently being used in the specified category. — item shape: {NonTalkTimeFilter?: record, InterruptionFilter?: record, TranscriptFilter?: record, SentimentFilter?: record}
  --input-type: string@input-type-completer # Choose whether you want to update a real-time or a post-call category. The input type you specify must match the input type specified when the category was created. For example, if you created a category with the POST_CALL input type, you must use POST_CALL as the input type when updating this category.
]: any -> oneof<record<CategoryProperties: record<CategoryName: string, Rules: list<record>, CreateTime: string, LastUpdateTime: string, InputType: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.UpdateCallAnalyticsCategory")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CategoryName": $category_name, "Rules": $rules, "InputType": $input_type} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Updates an existing custom medical vocabulary with new values. This operation overwrites all existing information with your new values; you cannot append new terms onto an existing custom vocabulary.
#
# POST /
# operationId: UpdateMedicalVocabulary
export def "update-medical-vocabulary" [
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  vocabulary_name: string # The name of the custom medical vocabulary you want to update. Custom medical vocabulary names are case sensitive.
  language_code: string@language-code-completer-1 # The language code that represents the language of the entries in the custom vocabulary you want to update. US English (en-US) is the only language supported with Amazon Transcribe Medical.
  vocabulary_file_uri: string # The Amazon S3 location of the text file that contains your custom medical vocabulary. The URI must be located in the same Amazon Web Services Region as the resource you're calling. Here's an example URI path: s3://DOC-EXAMPLE-BUCKET/my-vocab-file.txt
]: any -> oneof<record<VocabularyName: string, LanguageCode: string, LastModifiedTime: string, VocabularyState: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.UpdateMedicalVocabulary")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"VocabularyName": $vocabulary_name, "LanguageCode": $language_code, "VocabularyFileUri": $vocabulary_file_uri} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Updates an existing custom vocabulary with new values. This operation overwrites all existing information with your new values; you cannot append new terms onto an existing custom vocabulary.
#
# POST /
# operationId: UpdateVocabulary
export def "update-vocabulary" [
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
  --x-amz-target: string@x-amz-target-completer-37 # required
  vocabulary_name: string # The name of the custom vocabulary you want to update. Custom vocabulary names are case sensitive.
  language_code: string@language-code-completer-1 # The language code that represents the language of the entries in the custom vocabulary you want to update. Each custom vocabulary must contain terms in only one language. A custom vocabulary can only be used to transcribe files in the same language as the custom vocabulary. For example, if you create a custom vocabulary using US English (en-US), you can only apply this custom vocabulary to files that contain English audio. For a list of supported languages and their associated language codes, refer to the Supported languages (https://docs.aws.amazon.com/transcribe/latest/dg/supported-languages.html) table.
  --phrases: list<string> # Use this parameter if you want to update your custom vocabulary by including all desired terms, as comma-separated values, within your request. The other option for updating your custom vocabulary is to save your entries in a text file and upload them to an Amazon S3 bucket, then specify the location of your file using the VocabularyFileUri parameter. Note that if you include Phrases in your request, you cannot use VocabularyFileUri; you must choose one or the other. Each language has a character set that contains all allowed characters for that specific language. If you use unsupported characters, your custom vocabulary filter request fails. Refer to Character Sets for Custom Vocabularies (https://docs.aws.amazon.com/transcribe/latest/dg/charsets.html) to get the character set for your language.
  --vocabulary-file-uri: string # The Amazon S3 location of the text file that contains your custom vocabulary. The URI must be located in the same Amazon Web Services Region as the resource you're calling. Here's an example URI path: s3://DOC-EXAMPLE-BUCKET/my-vocab-file.txt Note that if you include VocabularyFileUri in your request, you cannot use the Phrases flag; you must choose one or the other.
  --data-access-role-arn: string # The Amazon Resource Name (ARN) of an IAM role that has permissions to access the Amazon S3 bucket that contains your input files (in this case, your custom vocabulary). If the role that you specify doesn’t have the appropriate permissions to access the specified Amazon S3 location, your request fails. IAM role ARNs have the format arn:partition:iam::account:role/role-name-with-path. For example: arn:aws:iam::111122223333:role/Admin. For more information, see IAM ARNs (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html#identifiers-arns).
]: any -> oneof<record<VocabularyName: string, LanguageCode: string, LastModifiedTime: string, VocabularyState: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.UpdateVocabulary")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"VocabularyName": $vocabulary_name, "LanguageCode": $language_code, "Phrases": $phrases, "VocabularyFileUri": $vocabulary_file_uri, "DataAccessRoleArn": $data_access_role_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Updates an existing custom vocabulary filter with a new list of words. The new list you provide overwrites all previous entries; you cannot append new terms onto an existing custom vocabulary filter.
#
# POST /
# operationId: UpdateVocabularyFilter
export def "update-vocabulary-filter" [
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
  --x-amz-target: string@x-amz-target-completer-38 # required
  vocabulary_filter_name: string # The name of the custom vocabulary filter you want to update. Custom vocabulary filter names are case sensitive.
  --words: list<string> # Use this parameter if you want to update your custom vocabulary filter by including all desired terms, as comma-separated values, within your request. The other option for updating your vocabulary filter is to save your entries in a text file and upload them to an Amazon S3 bucket, then specify the location of your file using the VocabularyFilterFileUri parameter. Note that if you include Words in your request, you cannot use VocabularyFilterFileUri; you must choose one or the other. Each language has a character set that contains all allowed characters for that specific language. If you use unsupported characters, your custom vocabulary filter request fails. Refer to Character Sets for Custom Vocabularies (https://docs.aws.amazon.com/transcribe/latest/dg/charsets.html) to get the character set for your language.
  --vocabulary-filter-file-uri: string # The Amazon S3 location of the text file that contains your custom vocabulary filter terms. The URI must be located in the same Amazon Web Services Region as the resource you're calling. Here's an example URI path: s3://DOC-EXAMPLE-BUCKET/my-vocab-filter-file.txt Note that if you include VocabularyFilterFileUri in your request, you cannot use Words; you must choose one or the other.
  --data-access-role-arn: string # The Amazon Resource Name (ARN) of an IAM role that has permissions to access the Amazon S3 bucket that contains your input files (in this case, your custom vocabulary filter). If the role that you specify doesn’t have the appropriate permissions to access the specified Amazon S3 location, your request fails. IAM role ARNs have the format arn:partition:iam::account:role/role-name-with-path. For example: arn:aws:iam::111122223333:role/Admin. For more information, see IAM ARNs (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html#identifiers-arns).
]: any -> oneof<record<VocabularyFilterName: string, LanguageCode: string, LastModifiedTime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Transcribe.UpdateVocabularyFilter")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"VocabularyFilterName": $vocabulary_filter_name, "Words": $words, "VocabularyFilterFileUri": $vocabulary_filter_file_uri, "DataAccessRoleArn": $data_access_role_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
