# Auto-generated client for Twitter API v2 v2.61
# Source: https://api.apis.guru/v2/specs/twitter.com/current/2.61/openapi.json
# Auth: --token flag or $env.TWITTER_API_V2_TOKEN

const BASE_URL = "https://api.twitter.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWITTER_API_V2_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "oauth" => { {scheme: $scheme, headers: {Authorization: $"Oauth ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.twitter.com"] }
def auth-scheme-completer [] { ["bearer" "oauth"] }

# Completers for enum parameters
def type-completer [] { ["tweets" "users"] }
def status-completer [] { ["complete" "created" "failed" "in_progress"] }
def accept-completer [] { ["application/json" "application/problem+json"] }
def conversation-type-completer [] { ["Group"] }
def state-completer [] { ["all" "live" "scheduled"] }
def reply-settings-completer [] { ["following" "mentionedUsers"] }
def granularity-completer [] { ["day" "hour" "minute"] }
def sort-order-completer [] { ["recency" "relevancy"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "2-compliance-jobs list-batch" } } | get name | first)
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

# List Compliance Jobs
#
# GET /2/compliance/jobs
# Docs: https://developer.twitter.com/en/docs/twitter-api/compliance/batch-compliance/api-reference/get-compliance-jobs
# operationId: listBatchComplianceJobs
export def "2-compliance-jobs list-batch" [
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
  --type: string@type-completer # Type of Compliance Job to list.
  --status: string@status-completer # Status of Compliance Job to list.
  --compliance-job-fields: list<string> # A comma separated list of ComplianceJob fields to display. (e.g. [created_at, download_expires_at, download_url, id, name, resumable, status, type, upload_expires_at, upload_url])
]: nothing -> record<data: table<created_at: string, download_expires_at: string, download_url: string, id: string, name: string, status: string, type: string, upload_expires_at: string, upload_url: string>, errors: table<detail: string, status: int, title: string, type: string>, meta: record<result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "compliance_job.fields" $compliance_job_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2/compliance/jobs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"type": $type, "status": $status, "compliance_job.fields": $compliance_job_fields} | compact), body: null}
}

# Create compliance job
#
# POST /2/compliance/jobs
# Docs: https://developer.twitter.com/en/docs/twitter-api/compliance/batch-compliance/api-reference/post-compliance-jobs
# operationId: createBatchComplianceJob
export def "2-compliance-jobs create-batch" [
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
  --name: string # User-provided name for a compliance job. (e.g. my-job)
  --resumable: oneof<nothing, bool> # If true, this endpoint will return a pre-signed URL with resumable uploads enabled.
  type: string@type-completer # Type of compliance job to list.
]: any -> record<data: record<created_at: string, download_expires_at: string, download_url: string, id: string, name: string, status: string, type: string, upload_expires_at: string, upload_url: string>, errors: table<detail: string, status: int, title: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2/compliance/jobs")
  let req_body = {"name": $name, "resumable": $resumable, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Compliance Job
#
# GET /2/compliance/jobs/{id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/compliance/batch-compliance/api-reference/get-compliance-jobs-id
# operationId: getBatchComplianceJob
export def "2-compliance-jobs get-batch" [
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
  --accept: string@accept-completer # Response content type
  --compliance-job-fields: list<string> # A comma separated list of ComplianceJob fields to display. (e.g. [created_at, download_expires_at, download_url, id, name, resumable, status, type, upload_expires_at, upload_url])
]: nothing -> record<data: record<created_at: string, download_expires_at: string, download_url: string, id: string, name: string, status: string, type: string, upload_expires_at: string, upload_url: string>, errors: table<detail: string, status: int, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "compliance_job.fields" $compliance_job_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/compliance/jobs/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"compliance_job.fields": $compliance_job_fields} | compact), body: null}
}

# Create a new DM Conversation
#
# POST /2/dm_conversations
# operationId: dmConversationIdCreate
export def "2-dm-conversations create" [
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
  conversation_type: string@conversation-type-completer # The conversation type that is being created.
  message: any
  participant_ids: list<string> # Participants for the DM Conversation.
]: any -> record<data: record<dm_conversation_id: string, dm_event_id: string>, errors: table<detail: string, status: int, title: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2/dm_conversations")
  let req_body = {"conversation_type": $conversation_type, "message": $message, "participant_ids": $participant_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get DM Events for a DM Conversation
#
# GET /2/dm_conversations/with/{participant_id}/dm_events
# operationId: getDmConversationsWithParticipantIdDmEvents
export def "2-dm-conversations-with-dm-events get" [
  participant_id: string
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
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --event-types: list<string> # The set of event_types to include in the results. (default: [MessageCreate, ParticipantsLeave, ParticipantsJoin], e.g. [MessageCreate, ParticipantsLeave])
  --dm-event-fields: list<string> # A comma separated list of DmEvent fields to display. (e.g. [attachments, created_at, dm_conversation_id, event_type, id, participant_ids, referenced_tweets, sender_id, text])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, participant_ids, referenced_tweets.id, sender_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> record<data: table<attachments: record, created_at: string, dm_conversation_id: string, event_type: string, id: string, participant_ids: list, referenced_tweets: list, sender_id: string, text: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($participant_id | is-empty) { error make --unspanned { msg: "path parameter 'participant_id' must be non-empty" } }
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "event_types" $event_types "csv") (serialize-qp "dm_event.fields" $dm_event_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "media.fields" $media_fields "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "tweet.fields" $tweet_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({participant_id: (encode-path-segment $participant_id)} | format pattern "/2/dm_conversations/with/{participant_id}/dm_events") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_results": $max_results, "pagination_token": $pagination_token, "event_types": $event_types, "dm_event.fields": $dm_event_fields, "expansions": $expansions, "media.fields": $media_fields, "user.fields": $user_fields, "tweet.fields": $tweet_fields} | compact), body: null}
}

# Send a new message to a user
#
# POST /2/dm_conversations/with/{participant_id}/messages
# operationId: dmConversationWithUserEventIdCreate
# --attachments item shape: {media_id: string}
export def "2-dm-conversations-with-messages create-user-event" [
  participant_id: string
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
  --attachments: list # Attachments to a DM Event. — item shape: {media_id: string}
  --text: string # Text of the message.
]: any -> record<data: record<dm_conversation_id: string, dm_event_id: string>, errors: table<detail: string, status: int, title: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($participant_id | is-empty) { error make --unspanned { msg: "path parameter 'participant_id' must be non-empty" } }
  let full_url = (build-url $base ({participant_id: (encode-path-segment $participant_id)} | format pattern "/2/dm_conversations/with/{participant_id}/messages"))
  let req_body = {"attachments": $attachments, "text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Send a new message to a DM Conversation
#
# POST /2/dm_conversations/{dm_conversation_id}/messages
# operationId: dmConversationByIdEventIdCreate
# --attachments item shape: {media_id: string}
export def "2-dm-conversations-messages create-by-event" [
  dm_conversation_id: string
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
  --attachments: list # Attachments to a DM Event. — item shape: {media_id: string}
  --text: string # Text of the message.
]: any -> record<data: record<dm_conversation_id: string, dm_event_id: string>, errors: table<detail: string, status: int, title: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($dm_conversation_id | is-empty) { error make --unspanned { msg: "path parameter 'dm_conversation_id' must be non-empty" } }
  let full_url = (build-url $base ({dm_conversation_id: (encode-path-segment $dm_conversation_id)} | format pattern "/2/dm_conversations/{dm_conversation_id}/messages"))
  let req_body = {"attachments": $attachments, "text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get DM Events for a DM Conversation
#
# GET /2/dm_conversations/{id}/dm_events
# operationId: getDmConversationsIdDmEvents
export def "2-dm-conversations-dm-events get" [
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
  --accept: string@accept-completer # Response content type
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --event-types: list<string> # The set of event_types to include in the results. (default: [MessageCreate, ParticipantsLeave, ParticipantsJoin], e.g. [MessageCreate, ParticipantsLeave])
  --dm-event-fields: list<string> # A comma separated list of DmEvent fields to display. (e.g. [attachments, created_at, dm_conversation_id, event_type, id, participant_ids, referenced_tweets, sender_id, text])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, participant_ids, referenced_tweets.id, sender_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> record<data: table<attachments: record, created_at: string, dm_conversation_id: string, event_type: string, id: string, participant_ids: list, referenced_tweets: list, sender_id: string, text: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "event_types" $event_types "csv") (serialize-qp "dm_event.fields" $dm_event_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "media.fields" $media_fields "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "tweet.fields" $tweet_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/dm_conversations/{id}/dm_events") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_results": $max_results, "pagination_token": $pagination_token, "event_types": $event_types, "dm_event.fields": $dm_event_fields, "expansions": $expansions, "media.fields": $media_fields, "user.fields": $user_fields, "tweet.fields": $tweet_fields} | compact), body: null}
}

# Get recent DM Events
#
# GET /2/dm_events
# operationId: getDmEvents
export def "2-dm-events get" [
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
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --event-types: list<string> # The set of event_types to include in the results. (default: [MessageCreate, ParticipantsLeave, ParticipantsJoin], e.g. [MessageCreate, ParticipantsLeave])
  --dm-event-fields: list<string> # A comma separated list of DmEvent fields to display. (e.g. [attachments, created_at, dm_conversation_id, event_type, id, participant_ids, referenced_tweets, sender_id, text])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, participant_ids, referenced_tweets.id, sender_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> record<data: table<attachments: record, created_at: string, dm_conversation_id: string, event_type: string, id: string, participant_ids: list, referenced_tweets: list, sender_id: string, text: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "event_types" $event_types "csv") (serialize-qp "dm_event.fields" $dm_event_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "media.fields" $media_fields "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "tweet.fields" $tweet_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2/dm_events" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_results": $max_results, "pagination_token": $pagination_token, "event_types": $event_types, "dm_event.fields": $dm_event_fields, "expansions": $expansions, "media.fields": $media_fields, "user.fields": $user_fields, "tweet.fields": $tweet_fields} | compact), body: null}
}

# Create List
#
# POST /2/lists
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/manage-lists/api-reference/post-lists
# operationId: listIdCreate
export def "2-lists create" [
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
  --description: string
  name: string
  --private: oneof<nothing, bool> # default: false
]: any -> record<data: record<id: string, name: string>, errors: table<detail: string, status: int, title: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2/lists")
  let req_body = {"description": $description, "name": $name, "private": $private} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete List
#
# DELETE /2/lists/{id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/manage-lists/api-reference/delete-lists-id
# operationId: listIdDelete
export def "2-lists delete" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<data: record<deleted: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/lists/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List lookup by List ID.
#
# GET /2/lists/{id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-lookup/api-reference/get-lists-id
# operationId: listIdGet
export def "2-lists get" [
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
  --accept: string@accept-completer # Response content type
  --list-fields: list<string> # A comma separated list of List fields to display. (e.g. [created_at, description, follower_count, id, member_count, name, owner_id, private])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [owner_id])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
]: nothing -> record<data: record<created_at: string, description: string, follower_count: int, id: string, member_count: int, name: string, owner_id: string, private: bool>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "list.fields" $list_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "user.fields" $user_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/lists/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"list.fields": $list_fields, "expansions": $expansions, "user.fields": $user_fields} | compact), body: null}
}

# Update List.
#
# PUT /2/lists/{id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/manage-lists/api-reference/put-lists-id
# operationId: listIdUpdate
export def "2-lists update" [
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
  --accept: string@accept-completer # Response content type
  --description: string
  --name: string
  --private: oneof<nothing, bool>
]: any -> record<data: record<updated: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/lists/{id}"))
  let req_body = {"description": $description, "name": $name, "private": $private} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns User objects that follow a List by the provided List ID
#
# GET /2/lists/{id}/followers
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/follows/api-reference/get-users-id-followers
# operationId: listGetFollowers
export def "2-lists-followers get" [
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
  --accept: string@accept-completer # Response content type
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "tweet.fields" $tweet_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/lists/{id}/followers") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_results": $max_results, "pagination_token": $pagination_token, "user.fields": $user_fields, "expansions": $expansions, "tweet.fields": $tweet_fields} | compact), body: null}
}

# Returns User objects that are members of a List by the provided List ID.
#
# GET /2/lists/{id}/members
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-members/api-reference/get-users-id-list_memberships
# operationId: listGetMembers
export def "2-lists-members get" [
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
  --accept: string@accept-completer # Response content type
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "tweet.fields" $tweet_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/lists/{id}/members") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_results": $max_results, "pagination_token": $pagination_token, "user.fields": $user_fields, "expansions": $expansions, "tweet.fields": $tweet_fields} | compact), body: null}
}

# Add a List member
#
# POST /2/lists/{id}/members
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-members/api-reference/post-lists-id-members
# operationId: listAddMember
export def "2-lists-members create" [
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
  --accept: string@accept-completer # Response content type
  user_id: string # Unique identifier of this User. This is returned as a string in order to avoid complications with languages and tools that cannot handle large integers. (e.g. 2244994945)
]: any -> record<data: record<is_member: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/lists/{id}/members"))
  let req_body = {"user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove a List member
#
# DELETE /2/lists/{id}/members/{user_id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-members/api-reference/delete-lists-id-members-user_id
# operationId: listRemoveMember
export def "2-lists-members delete" [
  id: string
  user_id: string
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
]: nothing -> record<data: record<is_member: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), user_id: (encode-path-segment $user_id)} | format pattern "/2/lists/{id}/members/{user_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Tweets timeline by List ID.
#
# GET /2/lists/{id}/tweets
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-tweets/api-reference/get-lists-id-tweets
# operationId: listsIdTweets
export def "2-lists-tweets get" [
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
  --accept: string@accept-completer # Response content type
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get the next 'page' of results.
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "tweet.fields" $tweet_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "media.fields" $media_fields "csv") (serialize-qp "poll.fields" $poll_fields "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "place.fields" $place_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/lists/{id}/tweets") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_results": $max_results, "pagination_token": $pagination_token, "tweet.fields": $tweet_fields, "expansions": $expansions, "media.fields": $media_fields, "poll.fields": $poll_fields, "user.fields": $user_fields, "place.fields": $place_fields} | compact), body: null}
}

# Returns the OpenAPI Specification document.
#
# GET /2/openapi.json
# operationId: getOpenApiSpec
export def "2-openapi-json get-open-spec" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2/openapi.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Space lookup up Space IDs
#
# GET /2/spaces
# Docs: https://developer.twitter.com/en/docs/twitter-api/spaces/lookup/api-reference/get-spaces
# operationId: findSpacesByIds
export def "2-spaces list" [
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
  --ids: list<string> # The list of Space IDs to return.
  --space-fields: list<string> # A comma separated list of Space fields to display. (e.g. [created_at, creator_id, ended_at, host_ids, id, invited_user_ids, is_ticketed, lang, participant_count, scheduled_start, speaker_ids, started_at, state, subscriber_count, title, topic_ids, updated_at])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [creator_id, host_ids, invited_user_ids, speaker_ids, topic_ids])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --topic-fields: list<string> # A comma separated list of Topic fields to display. (e.g. [description, id, name])
]: nothing -> record<data: table<created_at: string, creator_id: string, ended_at: string, host_ids: list, id: string, invited_user_ids: list, is_ticketed: bool, lang: string, participant_count: int, scheduled_start: string, speaker_ids: list, started_at: string, state: string, subscriber_count: int, title: string, topics: list, updated_at: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "space.fields" $space_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "topic.fields" $topic_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2/spaces" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "space.fields": $space_fields, "expansions": $expansions, "user.fields": $user_fields, "topic.fields": $topic_fields} | compact), body: null}
}

# Space lookup by their creators
#
# GET /2/spaces/by/creator_ids
# Docs: https://developer.twitter.com/en/docs/twitter-api/spaces/lookup/api-reference/get-spaces-by-creator-ids
# operationId: findSpacesByCreatorIds
export def "2-spaces-by-creator-ids find" [
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
  --user-ids: list # The IDs of Users to search through.
  --space-fields: list<string> # A comma separated list of Space fields to display. (e.g. [created_at, creator_id, ended_at, host_ids, id, invited_user_ids, is_ticketed, lang, participant_count, scheduled_start, speaker_ids, started_at, state, subscriber_count, title, topic_ids, updated_at])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [creator_id, host_ids, invited_user_ids, speaker_ids, topic_ids])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --topic-fields: list<string> # A comma separated list of Topic fields to display. (e.g. [description, id, name])
]: nothing -> record<data: table<created_at: string, creator_id: string, ended_at: string, host_ids: list, id: string, invited_user_ids: list, is_ticketed: bool, lang: string, participant_count: int, scheduled_start: string, speaker_ids: list, started_at: string, state: string, subscriber_count: int, title: string, topics: list, updated_at: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_ids" $user_ids "multi") (serialize-qp "space.fields" $space_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "topic.fields" $topic_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2/spaces/by/creator_ids" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"user_ids": $user_ids, "space.fields": $space_fields, "expansions": $expansions, "user.fields": $user_fields, "topic.fields": $topic_fields} | compact), body: null}
}

# Search for Spaces
#
# GET /2/spaces/search
# Docs: https://developer.twitter.com/en/docs/twitter-api/spaces/search/api-reference/get-spaces-search
# operationId: searchSpaces
export def "2-spaces-search list" [
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
  --query: string # The search query. (e.g. crypto)
  --state: string@state-completer # The state of Spaces to search for. (default: all)
  --max-results: int # The number of results to return. (format: int32, default: 100)
  --space-fields: list<string> # A comma separated list of Space fields to display. (e.g. [created_at, creator_id, ended_at, host_ids, id, invited_user_ids, is_ticketed, lang, participant_count, scheduled_start, speaker_ids, started_at, state, subscriber_count, title, topic_ids, updated_at])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [creator_id, host_ids, invited_user_ids, speaker_ids, topic_ids])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --topic-fields: list<string> # A comma separated list of Topic fields to display. (e.g. [description, id, name])
]: nothing -> record<data: table<created_at: string, creator_id: string, ended_at: string, host_ids: list, id: string, invited_user_ids: list, is_ticketed: bool, lang: string, participant_count: int, scheduled_start: string, speaker_ids: list, started_at: string, state: string, subscriber_count: int, title: string, topics: list, updated_at: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "space.fields" $space_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "topic.fields" $topic_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2/spaces/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "state": $state, "max_results": $max_results, "space.fields": $space_fields, "expansions": $expansions, "user.fields": $user_fields, "topic.fields": $topic_fields} | compact), body: null}
}

# Space lookup by Space ID
#
# GET /2/spaces/{id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/spaces/lookup/api-reference/get-spaces-id
# operationId: findSpaceById
export def "2-spaces find" [
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
  --accept: string@accept-completer # Response content type
  --space-fields: list<string> # A comma separated list of Space fields to display. (e.g. [created_at, creator_id, ended_at, host_ids, id, invited_user_ids, is_ticketed, lang, participant_count, scheduled_start, speaker_ids, started_at, state, subscriber_count, title, topic_ids, updated_at])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [creator_id, host_ids, invited_user_ids, speaker_ids, topic_ids])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --topic-fields: list<string> # A comma separated list of Topic fields to display. (e.g. [description, id, name])
]: nothing -> record<data: record<created_at: string, creator_id: string, ended_at: string, host_ids: list<string>, id: string, invited_user_ids: list<string>, is_ticketed: bool, lang: string, participant_count: int, scheduled_start: string, speaker_ids: list<string>, started_at: string, state: string, subscriber_count: int, title: string, topics: list<record>, updated_at: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "space.fields" $space_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "topic.fields" $topic_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/spaces/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"space.fields": $space_fields, "expansions": $expansions, "user.fields": $user_fields, "topic.fields": $topic_fields} | compact), body: null}
}

# Retrieve the list of Users who purchased a ticket to the given space
#
# GET /2/spaces/{id}/buyers
# Docs: https://developer.twitter.com/en/docs/twitter-api/spaces/lookup/api-reference/get-spaces-id-buyers
# operationId: spaceBuyers
export def "2-spaces-buyers get" [
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
  --accept: string@accept-completer # Response content type
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "tweet.fields" $tweet_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/spaces/{id}/buyers") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pagination_token": $pagination_token, "max_results": $max_results, "user.fields": $user_fields, "expansions": $expansions, "tweet.fields": $tweet_fields} | compact), body: null}
}

# Retrieve Tweets from a Space.
#
# GET /2/spaces/{id}/tweets
# Docs: https://developer.twitter.com/en/docs/twitter-api/spaces/lookup/api-reference/get-spaces-id-tweets
# operationId: spaceTweets
export def "2-spaces-tweets get" [
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
  --accept: string@accept-completer # Response content type
  --max-results: int # The number of Tweets to fetch from the provided space. If not provided, the value will default to the maximum of 100. (format: int32, default: 100, e.g. 25)
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "tweet.fields" $tweet_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "media.fields" $media_fields "csv") (serialize-qp "poll.fields" $poll_fields "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "place.fields" $place_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/spaces/{id}/tweets") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_results": $max_results, "tweet.fields": $tweet_fields, "expansions": $expansions, "media.fields": $media_fields, "poll.fields": $poll_fields, "user.fields": $user_fields, "place.fields": $place_fields} | compact), body: null}
}

# Tweet lookup by Tweet IDs
#
# GET /2/tweets
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/lookup/api-reference/get-tweets
# operationId: findTweetsById
export def "2-tweets list" [
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
  --ids: list # A comma separated list of Tweet IDs. Up to 100 are allowed in a single request.
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "tweet.fields" $tweet_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "media.fields" $media_fields "csv") (serialize-qp "poll.fields" $poll_fields "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "place.fields" $place_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2/tweets" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "tweet.fields": $tweet_fields, "expansions": $expansions, "media.fields": $media_fields, "poll.fields": $poll_fields, "user.fields": $user_fields, "place.fields": $place_fields} | compact), body: null}
}

# Creation of a Tweet
#
# POST /2/tweets
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/manage-tweets/api-reference/post-tweets
# operationId: createTweet
# --geo shape: {place_id?: string}
# --media shape: {media_ids: list<string>, tagged_user_ids?: list<string>}
# --poll shape: {duration_minutes: int, options: list<string>, reply_settings?: "following"|"mentionedUsers"}
# --reply shape: {exclude_reply_user_ids?: list<string>, in_reply_to_tweet_id: string}
export def "2-tweets create" [
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
  --card-uri: string # Card Uri Parameter. This is mutually exclusive from Quote Tweet Id, Poll, Media, and Direct Message Deep Link.
  --direct-message-deep-link: string # Link to take the conversation from the public timeline to a private Direct Message.
  --for-super-followers-only: oneof<nothing, bool> # Exclusive Tweet for super followers. (default: false)
  --geo: record # Place ID being attached to the Tweet for geo location. — shape: {place_id?: string}
  --media: record # Media information being attached to created Tweet. This is mutually exclusive from Quote Tweet Id, Poll, and Card URI. — shape: {media_ids: list<string>, tagged_user_ids?: list<string>}
  --nullcast: oneof<nothing, bool> # Nullcasted (promoted-only) Tweets do not appear in the public timeline and are not served to followers. (default: false)
  --poll: record # Poll options for a Tweet with a poll. This is mutually exclusive from Media, Quote Tweet Id, and Card URI. — shape: {duration_minutes: int, options: list<string>, reply_settings?: "following"|"mentionedUsers"}
  --quote-tweet-id: string # Unique identifier of this Tweet. This is returned as a string in order to avoid complications with languages and tools that cannot handle large integers. (e.g. 1346889436626259968)
  --reply: record # Tweet information of the Tweet being replied to. — shape: {exclude_reply_user_ids?: list<string>, in_reply_to_tweet_id: string}
  --reply-settings: string@reply-settings-completer # Settings to indicate who can reply to the Tweet.
  --text: string # The content of the Tweet. (e.g. Learn how to use the user Tweet timeline and user mention timeline endpoints in the Twitter API v2 to explore Tweet\u2026 https:\/\/t.co\/56a0vZUx7i)
]: any -> record<data: record<id: string, text: string>, errors: table<detail: string, status: int, title: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2/tweets")
  let req_body = {"card_uri": $card_uri, "direct_message_deep_link": $direct_message_deep_link, "for_super_followers_only": $for_super_followers_only, "geo": $geo, "media": $media, "nullcast": $nullcast, "poll": $poll, "quote_tweet_id": $quote_tweet_id, "reply": $reply, "reply_settings": $reply_settings, "text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Tweets Compliance stream
#
# GET /2/tweets/compliance/stream
# operationId: getTweetsComplianceStream
export def "2-tweets-compliance-stream get" [
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
  --backfill-minutes: int # The number of minutes of backfill requested. (format: int32)
  --partition: int # The partition number. (format: int32)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The earliest UTC timestamp from which the Tweet Compliance events will be provided. (format: date-time, e.g. 2021-02-01T18:40:40.000Z)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The latest UTC timestamp to which the Tweet Compliance events will be provided. (format: date-time, e.g. 2021-02-14T18:40:40.000Z)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "backfill_minutes" $backfill_minutes "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2/tweets/compliance/stream" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"backfill_minutes": $backfill_minutes, "partition": $partition, "start_time": $start_time, "end_time": $end_time} | compact), body: null}
}

# Full archive search counts
#
# GET /2/tweets/counts/all
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/search/api-reference/get-tweets-search-all
# operationId: tweetCountsFullArchiveSearch
export def "2-tweets-counts-all archive-full-list" [
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
  --query: string # One query/rule/filter for matching Tweets. Refer to https://t.co/rulelength to identify the max query length. (e.g. (from:TwitterDev OR from:TwitterAPI) has:media -is:retweet)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The oldest UTC timestamp (from most recent 7 days) from which the Tweets will be provided. Timestamp is in second granularity and is inclusive (i.e. 12:00:01 includes the first second of the minute). (format: date-time)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The newest, most recent UTC timestamp to which the Tweets will be provided. Timestamp is in second granularity and is exclusive (i.e. 12:00:01 excludes the first second of the minute). (format: date-time)
  --since-id: string # Returns results with a Tweet ID greater than (that is, more recent than) the specified ID. (e.g. 1346889436626259968)
  --until-id: string # Returns results with a Tweet ID less than (that is, older than) the specified ID. (e.g. 1346889436626259968)
  --next-token: string # This parameter is used to get the next 'page' of results. The value used with the parameter is pulled directly from the response provided by the API, and should not be modified.
  --pagination-token: string # This parameter is used to get the next 'page' of results. The value used with the parameter is pulled directly from the response provided by the API, and should not be modified.
  --granularity: string@granularity-completer # The granularity for the search counts results. (default: hour)
  --search-count-fields: list<string> # A comma separated list of SearchCount fields to display. (e.g. [end, start, tweet_count])
]: nothing -> record<data: table<end: string, start: string, tweet_count: int>, errors: table<detail: string, status: int, title: string, type: string>, meta: record<newest_id: string, next_token: string, oldest_id: string, total_tweet_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "next_token" $next_token "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "granularity" $granularity "scalar") (serialize-qp "search_count.fields" $search_count_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2/tweets/counts/all" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "start_time": $start_time, "end_time": $end_time, "since_id": $since_id, "until_id": $until_id, "next_token": $next_token, "pagination_token": $pagination_token, "granularity": $granularity, "search_count.fields": $search_count_fields} | compact), body: null}
}

# Recent search counts
#
# GET /2/tweets/counts/recent
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/counts/api-reference/get-tweets-counts-recent
# operationId: tweetCountsRecentSearch
export def "2-tweets-counts-recent list" [
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
  --query: string # One query/rule/filter for matching Tweets. Refer to https://t.co/rulelength to identify the max query length. (e.g. (from:TwitterDev OR from:TwitterAPI) has:media -is:retweet)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The oldest UTC timestamp (from most recent 7 days) from which the Tweets will be provided. Timestamp is in second granularity and is inclusive (i.e. 12:00:01 includes the first second of the minute). (format: date-time)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The newest, most recent UTC timestamp to which the Tweets will be provided. Timestamp is in second granularity and is exclusive (i.e. 12:00:01 excludes the first second of the minute). (format: date-time)
  --since-id: string # Returns results with a Tweet ID greater than (that is, more recent than) the specified ID. (e.g. 1346889436626259968)
  --until-id: string # Returns results with a Tweet ID less than (that is, older than) the specified ID. (e.g. 1346889436626259968)
  --next-token: string # This parameter is used to get the next 'page' of results. The value used with the parameter is pulled directly from the response provided by the API, and should not be modified.
  --pagination-token: string # This parameter is used to get the next 'page' of results. The value used with the parameter is pulled directly from the response provided by the API, and should not be modified.
  --granularity: string@granularity-completer # The granularity for the search counts results. (default: hour)
  --search-count-fields: list<string> # A comma separated list of SearchCount fields to display. (e.g. [end, start, tweet_count])
]: nothing -> record<data: table<end: string, start: string, tweet_count: int>, errors: table<detail: string, status: int, title: string, type: string>, meta: record<newest_id: string, next_token: string, oldest_id: string, total_tweet_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "next_token" $next_token "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "granularity" $granularity "scalar") (serialize-qp "search_count.fields" $search_count_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2/tweets/counts/recent" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "start_time": $start_time, "end_time": $end_time, "since_id": $since_id, "until_id": $until_id, "next_token": $next_token, "pagination_token": $pagination_token, "granularity": $granularity, "search_count.fields": $search_count_fields} | compact), body: null}
}

# Firehose stream
#
# GET /2/tweets/firehose/stream
# operationId: getTweetsFirehoseStream
export def "2-tweets-firehose-stream get" [
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
  --backfill-minutes: int # The number of minutes of backfill requested. (format: int32)
  --partition: int # The partition number. (format: int32)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The earliest UTC timestamp to which the Tweets will be provided. (format: date-time, e.g. 2021-02-14T18:40:40.000Z)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The latest UTC timestamp to which the Tweets will be provided. (format: date-time, e.g. 2021-02-14T18:40:40.000Z)
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> record<data: record<attachments: record<media_keys: list, poll_ids: list>, author_id: string, context_annotations: list<record>, conversation_id: string, created_at: string, edit_controls: record<editable_until: string, edits_remaining: int, is_edit_eligible: bool>, edit_history_tweet_ids: list<string>, entities: record<annotations: list, cashtags: list, hashtags: list, mentions: list, urls: list>, geo: record<coordinates: record, place_id: string>, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record<impression_count: int>, organic_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, possibly_sensitive: bool, promoted_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, public_metrics: record<impression_count: int, like_count: int, quote_count: int, reply_count: int, retweet_count: int>, referenced_tweets: list<record>, reply_settings: string, source: string, text: string, withheld: record<copyright: bool, country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "backfill_minutes" $backfill_minutes "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "tweet.fields" $tweet_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "media.fields" $media_fields "csv") (serialize-qp "poll.fields" $poll_fields "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "place.fields" $place_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2/tweets/firehose/stream" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"backfill_minutes": $backfill_minutes, "partition": $partition, "start_time": $start_time, "end_time": $end_time, "tweet.fields": $tweet_fields, "expansions": $expansions, "media.fields": $media_fields, "poll.fields": $poll_fields, "user.fields": $user_fields, "place.fields": $place_fields} | compact), body: null}
}

# Tweets Label stream
#
# GET /2/tweets/label/stream
# operationId: getTweetsLabelStream
export def "2-tweets-label-stream get" [
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
  --backfill-minutes: int # The number of minutes of backfill requested. (format: int32)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The earliest UTC timestamp from which the Tweet labels will be provided. (format: date-time, e.g. 2021-02-01T18:40:40.000Z)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The latest UTC timestamp from which the Tweet labels will be provided. (format: date-time, e.g. 2021-02-01T18:40:40.000Z)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "backfill_minutes" $backfill_minutes "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2/tweets/label/stream" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"backfill_minutes": $backfill_minutes, "start_time": $start_time, "end_time": $end_time} | compact), body: null}
}

# Sample stream
#
# GET /2/tweets/sample/stream
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/volume-streams/api-reference/get-tweets-sample-stream
# operationId: sampleStream
export def "2-tweets-sample-stream get" [
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
  --backfill-minutes: int # The number of minutes of backfill requested. (format: int32)
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> record<data: record<attachments: record<media_keys: list, poll_ids: list>, author_id: string, context_annotations: list<record>, conversation_id: string, created_at: string, edit_controls: record<editable_until: string, edits_remaining: int, is_edit_eligible: bool>, edit_history_tweet_ids: list<string>, entities: record<annotations: list, cashtags: list, hashtags: list, mentions: list, urls: list>, geo: record<coordinates: record, place_id: string>, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record<impression_count: int>, organic_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, possibly_sensitive: bool, promoted_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, public_metrics: record<impression_count: int, like_count: int, quote_count: int, reply_count: int, retweet_count: int>, referenced_tweets: list<record>, reply_settings: string, source: string, text: string, withheld: record<copyright: bool, country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "backfill_minutes" $backfill_minutes "scalar") (serialize-qp "tweet.fields" $tweet_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "media.fields" $media_fields "csv") (serialize-qp "poll.fields" $poll_fields "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "place.fields" $place_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2/tweets/sample/stream" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"backfill_minutes": $backfill_minutes, "tweet.fields": $tweet_fields, "expansions": $expansions, "media.fields": $media_fields, "poll.fields": $poll_fields, "user.fields": $user_fields, "place.fields": $place_fields} | compact), body: null}
}

# Sample 10% stream
#
# GET /2/tweets/sample10/stream
# operationId: getTweetsSample10Stream
export def "2-tweets-sample10-stream get" [
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
  --backfill-minutes: int # The number of minutes of backfill requested. (format: int32)
  --partition: int # The partition number. (format: int32)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The earliest UTC timestamp to which the Tweets will be provided. (format: date-time, e.g. 2021-02-14T18:40:40.000Z)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The latest UTC timestamp to which the Tweets will be provided. (format: date-time, e.g. 2021-02-14T18:40:40.000Z)
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> record<data: record<attachments: record<media_keys: list, poll_ids: list>, author_id: string, context_annotations: list<record>, conversation_id: string, created_at: string, edit_controls: record<editable_until: string, edits_remaining: int, is_edit_eligible: bool>, edit_history_tweet_ids: list<string>, entities: record<annotations: list, cashtags: list, hashtags: list, mentions: list, urls: list>, geo: record<coordinates: record, place_id: string>, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record<impression_count: int>, organic_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, possibly_sensitive: bool, promoted_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, public_metrics: record<impression_count: int, like_count: int, quote_count: int, reply_count: int, retweet_count: int>, referenced_tweets: list<record>, reply_settings: string, source: string, text: string, withheld: record<copyright: bool, country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "backfill_minutes" $backfill_minutes "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "tweet.fields" $tweet_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "media.fields" $media_fields "csv") (serialize-qp "poll.fields" $poll_fields "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "place.fields" $place_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2/tweets/sample10/stream" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"backfill_minutes": $backfill_minutes, "partition": $partition, "start_time": $start_time, "end_time": $end_time, "tweet.fields": $tweet_fields, "expansions": $expansions, "media.fields": $media_fields, "poll.fields": $poll_fields, "user.fields": $user_fields, "place.fields": $place_fields} | compact), body: null}
}

# Full-archive search
#
# GET /2/tweets/search/all
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/search/api-reference/get-tweets-search-all
# operationId: tweetsFullarchiveSearch
export def "2-tweets-search-all list-fullarchive" [
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
  --query: string # One query/rule/filter for matching Tweets. Refer to https://t.co/rulelength to identify the max query length. (e.g. (from:TwitterDev OR from:TwitterAPI) has:media -is:retweet)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The oldest UTC timestamp from which the Tweets will be provided. Timestamp is in second granularity and is inclusive (i.e. 12:00:01 includes the first second of the minute). (format: date-time)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The newest, most recent UTC timestamp to which the Tweets will be provided. Timestamp is in second granularity and is exclusive (i.e. 12:00:01 excludes the first second of the minute). (format: date-time)
  --since-id: string # Returns results with a Tweet ID greater than (that is, more recent than) the specified ID. (e.g. 1346889436626259968)
  --until-id: string # Returns results with a Tweet ID less than (that is, older than) the specified ID. (e.g. 1346889436626259968)
  --max-results: int # The maximum number of search results to be returned by a request. (format: int32, default: 10)
  --next-token: string # This parameter is used to get the next 'page' of results. The value used with the parameter is pulled directly from the response provided by the API, and should not be modified.
  --pagination-token: string # This parameter is used to get the next 'page' of results. The value used with the parameter is pulled directly from the response provided by the API, and should not be modified.
  --sort-order: string@sort-order-completer # This order in which to return results.
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<newest_id: string, next_token: string, oldest_id: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "next_token" $next_token "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "tweet.fields" $tweet_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "media.fields" $media_fields "csv") (serialize-qp "poll.fields" $poll_fields "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "place.fields" $place_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2/tweets/search/all" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "start_time": $start_time, "end_time": $end_time, "since_id": $since_id, "until_id": $until_id, "max_results": $max_results, "next_token": $next_token, "pagination_token": $pagination_token, "sort_order": $sort_order, "tweet.fields": $tweet_fields, "expansions": $expansions, "media.fields": $media_fields, "poll.fields": $poll_fields, "user.fields": $user_fields, "place.fields": $place_fields} | compact), body: null}
}

# Recent search
#
# GET /2/tweets/search/recent
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/search/api-reference/get-tweets-search-recent
# operationId: tweetsRecentSearch
export def "2-tweets-search-recent list" [
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
  --query: string # One query/rule/filter for matching Tweets. Refer to https://t.co/rulelength to identify the max query length. (e.g. (from:TwitterDev OR from:TwitterAPI) has:media -is:retweet)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The oldest UTC timestamp from which the Tweets will be provided. Timestamp is in second granularity and is inclusive (i.e. 12:00:01 includes the first second of the minute). (format: date-time)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The newest, most recent UTC timestamp to which the Tweets will be provided. Timestamp is in second granularity and is exclusive (i.e. 12:00:01 excludes the first second of the minute). (format: date-time)
  --since-id: string # Returns results with a Tweet ID greater than (that is, more recent than) the specified ID. (e.g. 1346889436626259968)
  --until-id: string # Returns results with a Tweet ID less than (that is, older than) the specified ID. (e.g. 1346889436626259968)
  --max-results: int # The maximum number of search results to be returned by a request. (format: int32, default: 10)
  --next-token: string # This parameter is used to get the next 'page' of results. The value used with the parameter is pulled directly from the response provided by the API, and should not be modified.
  --pagination-token: string # This parameter is used to get the next 'page' of results. The value used with the parameter is pulled directly from the response provided by the API, and should not be modified.
  --sort-order: string@sort-order-completer # This order in which to return results.
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<newest_id: string, next_token: string, oldest_id: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "next_token" $next_token "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "tweet.fields" $tweet_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "media.fields" $media_fields "csv") (serialize-qp "poll.fields" $poll_fields "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "place.fields" $place_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2/tweets/search/recent" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "start_time": $start_time, "end_time": $end_time, "since_id": $since_id, "until_id": $until_id, "max_results": $max_results, "next_token": $next_token, "pagination_token": $pagination_token, "sort_order": $sort_order, "tweet.fields": $tweet_fields, "expansions": $expansions, "media.fields": $media_fields, "poll.fields": $poll_fields, "user.fields": $user_fields, "place.fields": $place_fields} | compact), body: null}
}

# Filtered stream
#
# GET /2/tweets/search/stream
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/filtered-stream/api-reference/get-tweets-search-stream
# operationId: searchStream
export def "2-tweets-search-stream list" [
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
  --backfill-minutes: int # The number of minutes of backfill requested. (format: int32)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The earliest UTC timestamp from which the Tweets will be provided. (format: date-time, e.g. 2021-02-01T18:40:40.000Z)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The latest UTC timestamp to which the Tweets will be provided. (format: date-time, e.g. 2021-02-14T18:40:40.000Z)
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> record<data: record<attachments: record<media_keys: list, poll_ids: list>, author_id: string, context_annotations: list<record>, conversation_id: string, created_at: string, edit_controls: record<editable_until: string, edits_remaining: int, is_edit_eligible: bool>, edit_history_tweet_ids: list<string>, entities: record<annotations: list, cashtags: list, hashtags: list, mentions: list, urls: list>, geo: record<coordinates: record, place_id: string>, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record<impression_count: int>, organic_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, possibly_sensitive: bool, promoted_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, public_metrics: record<impression_count: int, like_count: int, quote_count: int, reply_count: int, retweet_count: int>, referenced_tweets: list<record>, reply_settings: string, source: string, text: string, withheld: record<copyright: bool, country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, matching_rules: table<id: string, tag: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "backfill_minutes" $backfill_minutes "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "tweet.fields" $tweet_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "media.fields" $media_fields "csv") (serialize-qp "poll.fields" $poll_fields "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "place.fields" $place_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2/tweets/search/stream" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"backfill_minutes": $backfill_minutes, "start_time": $start_time, "end_time": $end_time, "tweet.fields": $tweet_fields, "expansions": $expansions, "media.fields": $media_fields, "poll.fields": $poll_fields, "user.fields": $user_fields, "place.fields": $place_fields} | compact), body: null}
}

# Rules lookup
#
# GET /2/tweets/search/stream/rules
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/filtered-stream/api-reference/get-tweets-search-stream-rules
# operationId: getRules
export def "2-tweets-search-stream-rules get" [
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
  --ids: list # A comma-separated list of Rule IDs.
  --max-results: int # The maximum number of results. (format: int32, default: 1000)
  --pagination-token: string # This value is populated by passing the 'next_token' returned in a request to paginate through results.
]: nothing -> record<data: table<id: string, tag: string, value: string>, meta: record<next_token: string, result_count: int, sent: string, summary: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2/tweets/search/stream/rules" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "max_results": $max_results, "pagination_token": $pagination_token} | compact), body: null}
}

# Add/Delete rules
#
# POST /2/tweets/search/stream/rules
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/filtered-stream/api-reference/post-tweets-search-stream-rules
# operationId: addOrDeleteRules
# --add item shape: {tag?: string, value: string}
# --delete shape: {ids?: list<string>, values?: list<string>}
export def "2-tweets-search-stream-rules create-or-delete" [
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
  --qp-dry-run: oneof<nothing, bool> # Dry Run can be used with both the add and delete action, with the expected result given, but without actually taking any action in the system (meaning the end state will always be as it was when the request was submitted). This is particularly useful to validate rule changes.
  --add: list # item shape: {tag?: string, value: string}
  --delete: record # IDs and values of all deleted user-specified stream filtering rules. — shape: {ids?: list<string>, values?: list<string>}
]: any -> record<data: table<id: string, tag: string, value: string>, errors: table<detail: string, status: int, title: string, type: string>, meta: record<next_token: string, result_count: int, sent: string, summary: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dry_run" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2/tweets/search/stream/rules" $qp)
  let req_body = {"add": $add, "delete": $delete} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"dry_run": $qp_dry_run} | compact), body: $req_body}
}

# Tweet delete by Tweet ID
#
# DELETE /2/tweets/{id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/manage-tweets/api-reference/delete-tweets-id
# operationId: deleteTweetById
export def "2-tweets delete" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<data: record<deleted: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/tweets/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Tweet lookup by Tweet ID
#
# GET /2/tweets/{id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/lookup/api-reference/get-tweets-id
# operationId: findTweetById
export def "2-tweets find" [
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
  --accept: string@accept-completer # Response content type
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> record<data: record<attachments: record<media_keys: list, poll_ids: list>, author_id: string, context_annotations: list<record>, conversation_id: string, created_at: string, edit_controls: record<editable_until: string, edits_remaining: int, is_edit_eligible: bool>, edit_history_tweet_ids: list<string>, entities: record<annotations: list, cashtags: list, hashtags: list, mentions: list, urls: list>, geo: record<coordinates: record, place_id: string>, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record<impression_count: int>, organic_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, possibly_sensitive: bool, promoted_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, public_metrics: record<impression_count: int, like_count: int, quote_count: int, reply_count: int, retweet_count: int>, referenced_tweets: list<record>, reply_settings: string, source: string, text: string, withheld: record<copyright: bool, country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "tweet.fields" $tweet_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "media.fields" $media_fields "csv") (serialize-qp "poll.fields" $poll_fields "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "place.fields" $place_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/tweets/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tweet.fields": $tweet_fields, "expansions": $expansions, "media.fields": $media_fields, "poll.fields": $poll_fields, "user.fields": $user_fields, "place.fields": $place_fields} | compact), body: null}
}

# Returns User objects that have liked the provided Tweet ID
#
# GET /2/tweets/{id}/liking_users
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/likes/api-reference/get-tweets-id-liking_users
# operationId: tweetsIdLikingUsers
export def "2-tweets-liking-users get" [
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
  --accept: string@accept-completer # Response content type
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get the next 'page' of results.
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "tweet.fields" $tweet_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/tweets/{id}/liking_users") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_results": $max_results, "pagination_token": $pagination_token, "user.fields": $user_fields, "expansions": $expansions, "tweet.fields": $tweet_fields} | compact), body: null}
}

# Retrieve Tweets that quote a Tweet.
#
# GET /2/tweets/{id}/quote_tweets
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/quote-tweets/api-reference/get-tweets-id-quote_tweets
# operationId: findTweetsThatQuoteATweet
export def "2-tweets-quote-tweets find-that" [
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
  --accept: string@accept-completer # Response content type
  --max-results: int # The maximum number of results to be returned. (format: int32, default: 10)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --exclude: list<string> # The set of entities to exclude (e.g. 'replies' or 'retweets'). (e.g. [replies, retweets])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "exclude" $exclude "csv") (serialize-qp "tweet.fields" $tweet_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "media.fields" $media_fields "csv") (serialize-qp "poll.fields" $poll_fields "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "place.fields" $place_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/tweets/{id}/quote_tweets") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_results": $max_results, "pagination_token": $pagination_token, "exclude": $exclude, "tweet.fields": $tweet_fields, "expansions": $expansions, "media.fields": $media_fields, "poll.fields": $poll_fields, "user.fields": $user_fields, "place.fields": $place_fields} | compact), body: null}
}

# Returns User objects that have retweeted the provided Tweet ID
#
# GET /2/tweets/{id}/retweeted_by
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/retweets/api-reference/get-tweets-id-retweeted_by
# operationId: tweetsIdRetweetingUsers
export def "2-tweets-retweeted-by get-retweeting-users" [
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
  --accept: string@accept-completer # Response content type
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get the next 'page' of results.
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "tweet.fields" $tweet_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/tweets/{id}/retweeted_by") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_results": $max_results, "pagination_token": $pagination_token, "user.fields": $user_fields, "expansions": $expansions, "tweet.fields": $tweet_fields} | compact), body: null}
}

# Hide replies
#
# PUT /2/tweets/{tweet_id}/hidden
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/hide-replies/api-reference/put-tweets-id-hidden
# operationId: hideReplyById
export def "2-tweets-hidden update-hide-reply" [
  tweet_id: string
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
  --hidden: oneof<nothing, bool>
]: any -> record<data: record<hidden: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tweet_id | is-empty) { error make --unspanned { msg: "path parameter 'tweet_id' must be non-empty" } }
  let full_url = (build-url $base ({tweet_id: (encode-path-segment $tweet_id)} | format pattern "/2/tweets/{tweet_id}/hidden"))
  let req_body = {"hidden": $hidden} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# User lookup by IDs
#
# GET /2/users
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/lookup/api-reference/get-users
# operationId: findUsersById
export def "2-users list" [
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
  --ids: list # A list of User IDs, comma-separated. You can specify up to 100 IDs. (e.g. 2244994945,6253282,12)
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "tweet.fields" $tweet_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2/users" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "user.fields": $user_fields, "expansions": $expansions, "tweet.fields": $tweet_fields} | compact), body: null}
}

# User lookup by usernames
#
# GET /2/users/by
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/lookup/api-reference/get-users-by
# operationId: findUsersByUsername
export def "2-users-by find-username" [
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
  --usernames: list<string> # A list of usernames, comma-separated. (e.g. TwitterDev,TwitterAPI)
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "usernames" $usernames "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "tweet.fields" $tweet_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2/users/by" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"usernames": $usernames, "user.fields": $user_fields, "expansions": $expansions, "tweet.fields": $tweet_fields} | compact), body: null}
}

# User lookup by username
#
# GET /2/users/by/username/{username}
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/lookup/api-reference/get-users-by-username-username
# operationId: findUserByUsername
export def "2-users-by-username find" [
  username: string
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
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> record<data: record<created_at: string, description: string, entities: record<description: record, url: record>, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record<followers_count: int, following_count: int, listed_count: int, tweet_count: int>, url: string, username: string, verified: bool, verified_type: string, withheld: record<country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let qp = [(serialize-qp "user.fields" $user_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "tweet.fields" $tweet_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/2/users/by/username/{username}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"user.fields": $user_fields, "expansions": $expansions, "tweet.fields": $tweet_fields} | compact), body: null}
}

# Users Compliance stream
#
# GET /2/users/compliance/stream
# operationId: getUsersComplianceStream
export def "2-users-compliance-stream get" [
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
  --backfill-minutes: int # The number of minutes of backfill requested. (format: int32)
  --partition: int # The partition number. (format: int32)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The earliest UTC timestamp from which the User Compliance events will be provided. (format: date-time, e.g. 2021-02-01T18:40:40.000Z)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The latest UTC timestamp from which the User Compliance events will be provided. (format: date-time, e.g. 2021-02-01T18:40:40.000Z)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "backfill_minutes" $backfill_minutes "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2/users/compliance/stream" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"backfill_minutes": $backfill_minutes, "partition": $partition, "start_time": $start_time, "end_time": $end_time} | compact), body: null}
}

# User lookup me
#
# GET /2/users/me
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/lookup/api-reference/get-users-me
# operationId: findMyUser
export def "2-users-me find-my" [
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
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> record<data: record<created_at: string, description: string, entities: record<description: record, url: record>, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record<followers_count: int, following_count: int, listed_count: int, tweet_count: int>, url: string, username: string, verified: bool, verified_type: string, withheld: record<country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user.fields" $user_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "tweet.fields" $tweet_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2/users/me" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"user.fields": $user_fields, "expansions": $expansions, "tweet.fields": $tweet_fields} | compact), body: null}
}

# User lookup by ID
#
# GET /2/users/{id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/lookup/api-reference/get-users-id
# operationId: findUserById
export def "2-users find" [
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
  --accept: string@accept-completer # Response content type
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> record<data: record<created_at: string, description: string, entities: record<description: record, url: record>, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record<followers_count: int, following_count: int, listed_count: int, tweet_count: int>, url: string, username: string, verified: bool, verified_type: string, withheld: record<country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "user.fields" $user_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "tweet.fields" $tweet_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"user.fields": $user_fields, "expansions": $expansions, "tweet.fields": $tweet_fields} | compact), body: null}
}

# Returns User objects that are blocked by provided User ID
#
# GET /2/users/{id}/blocking
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/blocks/api-reference/get-users-blocking
# operationId: usersIdBlocking
export def "2-users-blocking get" [
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
  --accept: string@accept-completer # Response content type
  --max-results: int # The maximum number of results. (format: int32)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "tweet.fields" $tweet_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/blocking") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_results": $max_results, "pagination_token": $pagination_token, "user.fields": $user_fields, "expansions": $expansions, "tweet.fields": $tweet_fields} | compact), body: null}
}

# Block User by User ID
#
# POST /2/users/{id}/blocking
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/blocks/api-reference/post-users-user_id-blocking
# operationId: usersIdBlock
export def "2-users-blocking create-block" [
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
  --accept: string@accept-completer # Response content type
  target_user_id: string # Unique identifier of this User. This is returned as a string in order to avoid complications with languages and tools that cannot handle large integers. (e.g. 2244994945)
]: any -> record<data: record<blocking: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/blocking"))
  let req_body = {"target_user_id": $target_user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Bookmarks by User
#
# GET /2/users/{id}/bookmarks
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/bookmarks/api-reference/get-users-id-bookmarks
# operationId: getUsersIdBookmarks
export def "2-users-bookmarks get" [
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
  --accept: string@accept-completer # Response content type
  --max-results: int # The maximum number of results. (format: int32)
  --pagination-token: string # This parameter is used to get the next 'page' of results.
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "tweet.fields" $tweet_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "media.fields" $media_fields "csv") (serialize-qp "poll.fields" $poll_fields "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "place.fields" $place_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/bookmarks") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_results": $max_results, "pagination_token": $pagination_token, "tweet.fields": $tweet_fields, "expansions": $expansions, "media.fields": $media_fields, "poll.fields": $poll_fields, "user.fields": $user_fields, "place.fields": $place_fields} | compact), body: null}
}

# Add Tweet to Bookmarks
#
# POST /2/users/{id}/bookmarks
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/bookmarks/api-reference/post-users-id-bookmarks
# operationId: postUsersIdBookmarks
export def "2-users-bookmarks create" [
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
  --accept: string@accept-completer # Response content type
  tweet_id: string # Unique identifier of this Tweet. This is returned as a string in order to avoid complications with languages and tools that cannot handle large integers. (e.g. 1346889436626259968)
]: any -> record<data: record<bookmarked: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/bookmarks"))
  let req_body = {"tweet_id": $tweet_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove a bookmarked Tweet
#
# DELETE /2/users/{id}/bookmarks/{tweet_id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/bookmarks/api-reference/delete-users-id-bookmarks-tweet_id
# operationId: usersIdBookmarksDelete
export def "2-users-bookmarks delete" [
  id: string
  tweet_id: string
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
]: nothing -> record<data: record<bookmarked: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($tweet_id | is-empty) { error make --unspanned { msg: "path parameter 'tweet_id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), tweet_id: (encode-path-segment $tweet_id)} | format pattern "/2/users/{id}/bookmarks/{tweet_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get User's Followed Lists
#
# GET /2/users/{id}/followed_lists
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-follows/api-reference/get-users-id-followed_lists
# operationId: userFollowedLists
export def "2-users-followed-lists get" [
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
  --accept: string@accept-completer # Response content type
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --list-fields: list<string> # A comma separated list of List fields to display. (e.g. [created_at, description, follower_count, id, member_count, name, owner_id, private])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [owner_id])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
]: nothing -> record<data: table<created_at: string, description: string, follower_count: int, id: string, member_count: int, name: string, owner_id: string, private: bool>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "list.fields" $list_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "user.fields" $user_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/followed_lists") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_results": $max_results, "pagination_token": $pagination_token, "list.fields": $list_fields, "expansions": $expansions, "user.fields": $user_fields} | compact), body: null}
}

# Follow a List
#
# POST /2/users/{id}/followed_lists
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-follows/api-reference/post-users-id-followed-lists
# operationId: listUserFollow
export def "2-users-followed-lists list-follow" [
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
  --accept: string@accept-completer # Response content type
  list_id: string # The unique identifier of this List. (e.g. 1146654567674912769)
]: any -> record<data: record<following: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/followed_lists"))
  let req_body = {"list_id": $list_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Unfollow a List
#
# DELETE /2/users/{id}/followed_lists/{list_id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-follows/api-reference/delete-users-id-followed-lists-list_id
# operationId: listUserUnfollow
export def "2-users-followed-lists list-unfollow" [
  id: string
  list_id: string
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
]: nothing -> record<data: record<following: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'list_id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), list_id: (encode-path-segment $list_id)} | format pattern "/2/users/{id}/followed_lists/{list_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Followers by User ID
#
# GET /2/users/{id}/followers
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/follows/api-reference/get-users-id-followers
# operationId: usersIdFollowers
export def "2-users-followers get" [
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
  --accept: string@accept-completer # Response content type
  --max-results: int # The maximum number of results. (format: int32)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "tweet.fields" $tweet_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/followers") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_results": $max_results, "pagination_token": $pagination_token, "user.fields": $user_fields, "expansions": $expansions, "tweet.fields": $tweet_fields} | compact), body: null}
}

# Following by User ID
#
# GET /2/users/{id}/following
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/follows/api-reference/get-users-id-following
# operationId: usersIdFollowing
export def "2-users-following get" [
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
  --accept: string@accept-completer # Response content type
  --max-results: int # The maximum number of results. (format: int32)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "tweet.fields" $tweet_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/following") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_results": $max_results, "pagination_token": $pagination_token, "user.fields": $user_fields, "expansions": $expansions, "tweet.fields": $tweet_fields} | compact), body: null}
}

# Follow User
#
# POST /2/users/{id}/following
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/follows/api-reference/post-users-source_user_id-following
# operationId: usersIdFollow
export def "2-users-following create-follow" [
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
  --accept: string@accept-completer # Response content type
  target_user_id: string # Unique identifier of this User. This is returned as a string in order to avoid complications with languages and tools that cannot handle large integers. (e.g. 2244994945)
]: any -> record<data: record<following: bool, pending_follow: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/following"))
  let req_body = {"target_user_id": $target_user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns Tweet objects liked by the provided User ID
#
# GET /2/users/{id}/liked_tweets
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/likes/api-reference/get-users-id-liked_tweets
# operationId: usersIdLikedTweets
export def "2-users-liked-tweets get" [
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
  --accept: string@accept-completer # Response content type
  --max-results: int # The maximum number of results. (format: int32)
  --pagination-token: string # This parameter is used to get the next 'page' of results.
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "tweet.fields" $tweet_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "media.fields" $media_fields "csv") (serialize-qp "poll.fields" $poll_fields "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "place.fields" $place_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/liked_tweets") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_results": $max_results, "pagination_token": $pagination_token, "tweet.fields": $tweet_fields, "expansions": $expansions, "media.fields": $media_fields, "poll.fields": $poll_fields, "user.fields": $user_fields, "place.fields": $place_fields} | compact), body: null}
}

# Causes the User (in the path) to like the specified Tweet
#
# POST /2/users/{id}/likes
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/likes/api-reference/post-users-id-likes
# operationId: usersIdLike
export def "2-users-likes create" [
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
  --accept: string@accept-completer # Response content type
  tweet_id: string # Unique identifier of this Tweet. This is returned as a string in order to avoid complications with languages and tools that cannot handle large integers. (e.g. 1346889436626259968)
]: any -> record<data: record<liked: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/likes"))
  let req_body = {"tweet_id": $tweet_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Causes the User (in the path) to unlike the specified Tweet
#
# DELETE /2/users/{id}/likes/{tweet_id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/likes/api-reference/delete-users-id-likes-tweet_id
# operationId: usersIdUnlike
export def "2-users-likes delete-unlike" [
  id: string
  tweet_id: string
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
]: nothing -> record<data: record<liked: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($tweet_id | is-empty) { error make --unspanned { msg: "path parameter 'tweet_id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), tweet_id: (encode-path-segment $tweet_id)} | format pattern "/2/users/{id}/likes/{tweet_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a User's List Memberships
#
# GET /2/users/{id}/list_memberships
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-members/api-reference/get-users-id-list_memberships
# operationId: getUserListMemberships
export def "2-users-list-memberships get" [
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
  --accept: string@accept-completer # Response content type
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --list-fields: list<string> # A comma separated list of List fields to display. (e.g. [created_at, description, follower_count, id, member_count, name, owner_id, private])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [owner_id])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
]: nothing -> record<data: table<created_at: string, description: string, follower_count: int, id: string, member_count: int, name: string, owner_id: string, private: bool>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "list.fields" $list_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "user.fields" $user_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/list_memberships") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_results": $max_results, "pagination_token": $pagination_token, "list.fields": $list_fields, "expansions": $expansions, "user.fields": $user_fields} | compact), body: null}
}

# User mention timeline by User ID
#
# GET /2/users/{id}/mentions
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/timelines/api-reference/get-users-id-mentions
# operationId: usersIdMentions
export def "2-users-mentions get" [
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
  --accept: string@accept-completer # Response content type
  --since-id: string # The minimum Tweet ID to be included in the result set. This parameter takes precedence over start_time if both are specified. (e.g. 1346889436626259968)
  --until-id: string # The maximum Tweet ID to be included in the result set. This parameter takes precedence over end_time if both are specified. (e.g. 1346889436626259968)
  --max-results: int # The maximum number of results. (format: int32)
  --pagination-token: string # This parameter is used to get the next 'page' of results.
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The earliest UTC timestamp from which the Tweets will be provided. The since_id parameter takes precedence if it is also specified. (format: date-time, e.g. 2021-02-01T18:40:40.000Z)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The latest UTC timestamp to which the Tweets will be provided. The until_id parameter takes precedence if it is also specified. (format: date-time, e.g. 2021-02-14T18:40:40.000Z)
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<newest_id: string, next_token: string, oldest_id: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "since_id" $since_id "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "tweet.fields" $tweet_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "media.fields" $media_fields "csv") (serialize-qp "poll.fields" $poll_fields "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "place.fields" $place_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/mentions") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"since_id": $since_id, "until_id": $until_id, "max_results": $max_results, "pagination_token": $pagination_token, "start_time": $start_time, "end_time": $end_time, "tweet.fields": $tweet_fields, "expansions": $expansions, "media.fields": $media_fields, "poll.fields": $poll_fields, "user.fields": $user_fields, "place.fields": $place_fields} | compact), body: null}
}

# Returns User objects that are muted by the provided User ID
#
# GET /2/users/{id}/muting
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/mutes/api-reference/get-users-muting
# operationId: usersIdMuting
export def "2-users-muting get" [
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
  --accept: string@accept-completer # Response content type
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get the next 'page' of results.
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "tweet.fields" $tweet_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/muting") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_results": $max_results, "pagination_token": $pagination_token, "user.fields": $user_fields, "expansions": $expansions, "tweet.fields": $tweet_fields} | compact), body: null}
}

# Mute User by User ID.
#
# POST /2/users/{id}/muting
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/mutes/api-reference/post-users-user_id-muting
# operationId: usersIdMute
export def "2-users-muting create-mute" [
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
  --accept: string@accept-completer # Response content type
  target_user_id: string # Unique identifier of this User. This is returned as a string in order to avoid complications with languages and tools that cannot handle large integers. (e.g. 2244994945)
]: any -> record<data: record<muting: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/muting"))
  let req_body = {"target_user_id": $target_user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a User's Owned Lists.
#
# GET /2/users/{id}/owned_lists
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-lookup/api-reference/get-users-id-owned_lists
# operationId: listUserOwnedLists
export def "2-users-owned-lists list" [
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
  --accept: string@accept-completer # Response content type
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --list-fields: list<string> # A comma separated list of List fields to display. (e.g. [created_at, description, follower_count, id, member_count, name, owner_id, private])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [owner_id])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
]: nothing -> record<data: table<created_at: string, description: string, follower_count: int, id: string, member_count: int, name: string, owner_id: string, private: bool>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "list.fields" $list_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "user.fields" $user_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/owned_lists") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_results": $max_results, "pagination_token": $pagination_token, "list.fields": $list_fields, "expansions": $expansions, "user.fields": $user_fields} | compact), body: null}
}

# Get a User's Pinned Lists
#
# GET /2/users/{id}/pinned_lists
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/pinned-lists/api-reference/get-users-id-pinned_lists
# operationId: listUserPinnedLists
export def "2-users-pinned-lists list" [
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
  --accept: string@accept-completer # Response content type
  --list-fields: list<string> # A comma separated list of List fields to display. (e.g. [created_at, description, follower_count, id, member_count, name, owner_id, private])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [owner_id])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
]: nothing -> record<data: table<created_at: string, description: string, follower_count: int, id: string, member_count: int, name: string, owner_id: string, private: bool>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "list.fields" $list_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "user.fields" $user_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/pinned_lists") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"list.fields": $list_fields, "expansions": $expansions, "user.fields": $user_fields} | compact), body: null}
}

# Pin a List
#
# POST /2/users/{id}/pinned_lists
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/pinned-lists/api-reference/post-users-id-pinned-lists
# operationId: listUserPin
export def "2-users-pinned-lists list-pin" [
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
  --accept: string@accept-completer # Response content type
  list_id: string # The unique identifier of this List. (e.g. 1146654567674912769)
]: any -> record<data: record<pinned: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/pinned_lists"))
  let req_body = {"list_id": $list_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Unpin a List
#
# DELETE /2/users/{id}/pinned_lists/{list_id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/pinned-lists/api-reference/delete-users-id-pinned-lists-list_id
# operationId: listUserUnpin
export def "2-users-pinned-lists list-unpin" [
  id: string
  list_id: string
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
]: nothing -> record<data: record<pinned: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'list_id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), list_id: (encode-path-segment $list_id)} | format pattern "/2/users/{id}/pinned_lists/{list_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Causes the User (in the path) to retweet the specified Tweet.
#
# POST /2/users/{id}/retweets
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/retweets/api-reference/post-users-id-retweets
# operationId: usersIdRetweets
export def "2-users-retweets create" [
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
  --accept: string@accept-completer # Response content type
  tweet_id: string # Unique identifier of this Tweet. This is returned as a string in order to avoid complications with languages and tools that cannot handle large integers. (e.g. 1346889436626259968)
]: any -> record<data: record<retweeted: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/retweets"))
  let req_body = {"tweet_id": $tweet_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Causes the User (in the path) to unretweet the specified Tweet
#
# DELETE /2/users/{id}/retweets/{source_tweet_id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/retweets/api-reference/delete-users-id-retweets-tweet_id
# operationId: usersIdUnretweets
export def "2-users-retweets delete-unretweets" [
  id: string
  source_tweet_id: string
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
]: nothing -> record<data: record<retweeted: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($source_tweet_id | is-empty) { error make --unspanned { msg: "path parameter 'source_tweet_id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), source_tweet_id: (encode-path-segment $source_tweet_id)} | format pattern "/2/users/{id}/retweets/{source_tweet_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# User home timeline by User ID
#
# GET /2/users/{id}/timelines/reverse_chronological
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/timelines/api-reference/get-users-id-reverse-chronological
# operationId: usersIdTimeline
export def "2-users-timelines-reverse-chronological get" [
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
  --accept: string@accept-completer # Response content type
  --since-id: string # The minimum Tweet ID to be included in the result set. This parameter takes precedence over start_time if both are specified. (e.g. 1346889436626259968)
  --until-id: string # The maximum Tweet ID to be included in the result set. This parameter takes precedence over end_time if both are specified. (e.g. 1346889436626259968)
  --max-results: int # The maximum number of results. (format: int32)
  --pagination-token: string # This parameter is used to get the next 'page' of results.
  --exclude: list<string> # The set of entities to exclude (e.g. 'replies' or 'retweets'). (e.g. [replies, retweets])
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The earliest UTC timestamp from which the Tweets will be provided. The since_id parameter takes precedence if it is also specified. (format: date-time, e.g. 2021-02-01T18:40:40.000Z)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The latest UTC timestamp to which the Tweets will be provided. The until_id parameter takes precedence if it is also specified. (format: date-time, e.g. 2021-02-14T18:40:40.000Z)
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<newest_id: string, next_token: string, oldest_id: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "since_id" $since_id "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "exclude" $exclude "csv") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "tweet.fields" $tweet_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "media.fields" $media_fields "csv") (serialize-qp "poll.fields" $poll_fields "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "place.fields" $place_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/timelines/reverse_chronological") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"since_id": $since_id, "until_id": $until_id, "max_results": $max_results, "pagination_token": $pagination_token, "exclude": $exclude, "start_time": $start_time, "end_time": $end_time, "tweet.fields": $tweet_fields, "expansions": $expansions, "media.fields": $media_fields, "poll.fields": $poll_fields, "user.fields": $user_fields, "place.fields": $place_fields} | compact), body: null}
}

# User Tweets timeline by User ID
#
# GET /2/users/{id}/tweets
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/timelines/api-reference/get-users-id-tweets
# operationId: usersIdTweets
export def "2-users-tweets get" [
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
  --accept: string@accept-completer # Response content type
  --since-id: string # The minimum Tweet ID to be included in the result set. This parameter takes precedence over start_time if both are specified. (e.g. 1346889436626259968)
  --until-id: string # The maximum Tweet ID to be included in the result set. This parameter takes precedence over end_time if both are specified. (e.g. 1346889436626259968)
  --max-results: int # The maximum number of results. (format: int32)
  --pagination-token: string # This parameter is used to get the next 'page' of results.
  --exclude: list<string> # The set of entities to exclude (e.g. 'replies' or 'retweets'). (e.g. [replies, retweets])
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The earliest UTC timestamp from which the Tweets will be provided. The since_id parameter takes precedence if it is also specified. (format: date-time, e.g. 2021-02-01T18:40:40.000Z)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The latest UTC timestamp to which the Tweets will be provided. The until_id parameter takes precedence if it is also specified. (format: date-time, e.g. 2021-02-14T18:40:40.000Z)
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<newest_id: string, next_token: string, oldest_id: string, previous_token: string, result_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "since_id" $since_id "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "exclude" $exclude "csv") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "tweet.fields" $tweet_fields "csv") (serialize-qp "expansions" $expansions "csv") (serialize-qp "media.fields" $media_fields "csv") (serialize-qp "poll.fields" $poll_fields "csv") (serialize-qp "user.fields" $user_fields "csv") (serialize-qp "place.fields" $place_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2/users/{id}/tweets") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"since_id": $since_id, "until_id": $until_id, "max_results": $max_results, "pagination_token": $pagination_token, "exclude": $exclude, "start_time": $start_time, "end_time": $end_time, "tweet.fields": $tweet_fields, "expansions": $expansions, "media.fields": $media_fields, "poll.fields": $poll_fields, "user.fields": $user_fields, "place.fields": $place_fields} | compact), body: null}
}

# Unblock User by User ID
#
# DELETE /2/users/{source_user_id}/blocking/{target_user_id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/blocks/api-reference/delete-users-user_id-blocking
# operationId: usersIdUnblock
export def "2-users-blocking delete-unblock" [
  source_user_id: string
  target_user_id: string
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
]: nothing -> record<data: record<blocking: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_user_id | is-empty) { error make --unspanned { msg: "path parameter 'source_user_id' must be non-empty" } }
  if ($target_user_id | is-empty) { error make --unspanned { msg: "path parameter 'target_user_id' must be non-empty" } }
  let full_url = (build-url $base ({source_user_id: (encode-path-segment $source_user_id), target_user_id: (encode-path-segment $target_user_id)} | format pattern "/2/users/{source_user_id}/blocking/{target_user_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Unfollow User
#
# DELETE /2/users/{source_user_id}/following/{target_user_id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/follows/api-reference/delete-users-source_id-following
# operationId: usersIdUnfollow
export def "2-users-following delete-unfollow" [
  source_user_id: string
  target_user_id: string
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
]: nothing -> record<data: record<following: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_user_id | is-empty) { error make --unspanned { msg: "path parameter 'source_user_id' must be non-empty" } }
  if ($target_user_id | is-empty) { error make --unspanned { msg: "path parameter 'target_user_id' must be non-empty" } }
  let full_url = (build-url $base ({source_user_id: (encode-path-segment $source_user_id), target_user_id: (encode-path-segment $target_user_id)} | format pattern "/2/users/{source_user_id}/following/{target_user_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Unmute User by User ID
#
# DELETE /2/users/{source_user_id}/muting/{target_user_id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/mutes/api-reference/delete-users-user_id-muting
# operationId: usersIdUnmute
export def "2-users-muting delete-unmute" [
  source_user_id: string
  target_user_id: string
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
]: nothing -> record<data: record<muting: bool>, errors: table<detail: string, status: int, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_user_id | is-empty) { error make --unspanned { msg: "path parameter 'source_user_id' must be non-empty" } }
  if ($target_user_id | is-empty) { error make --unspanned { msg: "path parameter 'target_user_id' must be non-empty" } }
  let full_url = (build-url $base ({source_user_id: (encode-path-segment $source_user_id), target_user_id: (encode-path-segment $target_user_id)} | format pattern "/2/users/{source_user_id}/muting/{target_user_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
