# Auto-generated client for REST API Version 2 v2.9.235
# Source: https://api.apis.guru/v2/specs/circuitsandbox.net/2.9.235/openapi.json
# Auth: --token flag or $env.REST_API_VERSION_2_TOKEN

const BASE_URL = "https://circuitsandbox.net/rest/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o REST_API_VERSION_2_TOKEN | default "" }
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

def base-url-completer [] { ["https://circuitsandbox.net/rest/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def direction-completer [] { ["AFTER" "BEFORE"] }
def accept-completer [] { ["application/json" "application/xml"] }
def sort-completer [] { ["ALPHABETICALLY" "POPULARITY" "RECENT_ACTIVITY"] }
def order-completer [] { ["ASCENDING" "DESCENDING"] }
def scope-completer [] { ["ALL" "CONVERSATIONS" "FILES" "FILTER" "LABEL" "MEMBERS" "MESSAGES" "PEOPLE" "SENTBY"] }
def type-completer [] { ["BOT" "FORMER" "GUEST" "MODERATOR" "REGULAR"] }
def access-mode-type-completer [] { ["INTERNAL_EXTERNAL" "INTERNAL_ONLY"] }
def role-completer [] { ["AUTHOR" "MODERATOR" "PARTICIPANT" "READER"] }
def status-completer [] { ["DISABLED" "ENABLED"] }
def type-completer-1 [] { ["CLOSED" "OPEN" "SECRET"] }
def sort-by-completer [] { ["CREATION_DATE" "LAST_CONTENT" "NAME" "NUMBER_OF_USERS"] }
def sort-order-completer [] { ["ASCENDING" "DESCENDING"] }
def filter-completer [] { ["CLOSED" "JOINED" "NONE" "NOT_JOINED_REQUESTED" "OPEN" "REQUESTED"] }
def search-direction-completer [] { ["AFTER" "BEFORE"] }
def scope-completer-1 [] { ["ALL" "DATE" "FILES" "LABELS" "SPACES" "TAGS" "TOPICBY"] }
def access-mode-type-completer-1 [] { ["INTERNAL_EXTERNAL" "INTERNAL_ONLY" "NO_CHANGE"] }
def role-completer-1 [] { ["AUTHOR" "MODERATOR" "NO_CHANGE" "PARTICIPANT" "READER"] }
def type-completer-2 [] { ["CLOSED" "NO_CHANGE" "OPEN" "SECRET"] }
def role-completer-2 [] { ["AUTHOR" "DEFAULT" "MODERATOR" "PARTICIPANT" "READER"] }
def sort-by-completer-1 [] { ["DISPLAY_NAME" "FIRST_NAME" "NAME"] }
def filter-type-completer [] { ["ACCESS_TYPE" "NONE" "ROLE" "STATE"] }
def direction-completer-1 [] { ["AFTER" "BEFORE" "BOTH"] }
def journal-filter-completer [] { ["ALL" "DIALED" "DIVERTED" "MISSED" "RECEIVED" "UNHERAD_VOICEMAILS" "VOICEMAILS"] }
def locale-completer [] { ["CA_ES" "DE_DE" "EN_GB" "EN_US" "ES_ES" "FR_FR" "IT_IT" "NL_NL" "PT_BR" "RU_RU" "ZH_HANS_CN"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "conversations get" } } | get name | first)
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

# Gets a list of conversations
#
# GET /conversations
# operationId: getConversations
export def "conversations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --mod-time: string # The modification time of the conversation in UTC format. During the query the conversations before (<i>default</i>) or after this timestamp are returned. In case no timestamp is specified the current server time in UTC is used, i.e. the last 25 modified conversations are returned (format: date-time)
  --direction: string@direction-completer # The direction of the search based on the modification time. Valid values are either BEFORE (default) or AFTER (default: BEFORE)
  --results: float # The maximum number of returned results (default 25). The maximum allowed value is 100. (format: int32, default: 25)
]: nothing -> table<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modTime" $mod_time "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "results" $results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets conversations
#
# GET /conversations/byIds
# operationId: getConversationsById
export def "conversations-by-ids get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --conv-ids: list # The array of IDs of the conversations which should be retrieved
]: nothing -> table<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "convIds" $conv_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations/byIds" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of communities
#
# GET /conversations/community
# operationId: getCommunityConversations
export def "conversations-community get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-sort: string@sort-completer # Defines the type of sorting for the community conversations (default is alphabetical) (default: ALPHABETICALLY)
  --order: string@order-completer # Defines the ordering of the conversations (default is ascending) (default: ASCENDING)
  --include-own: oneof<nothing, bool> # If set to false only conversations are returned where the user is no member of, otherwise all community conversations are returned (default: false)
  --start-index: float # The index of the conversation that is the first one that has to be returned. E.g. if a request starts with startIndex 40 and results 20 the conversations 40 to 60 are returned (format: int32, default: 0)
  --results: float # The maximum number of returned results (default 25). The maximum allowed value is 100. (format: int32, default: 25)
]: nothing -> table<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "includeOwn" $include_own "scalar") (serialize-qp "startIndex" $start_index "scalar") (serialize-qp "results" $results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations/community" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a community conversation
#
# POST /conversations/community
# operationId: createCommunityConversation
export def "conversations-community create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # An optional description for the community conversation
  --participants: list # list of participants that will be part of this conversation, specified by the Circuit user ID or the unique email address. At least one participant needs to be added
  topic: string # An optional topic of the conversation. If not set the Circuit client will render the names of the participants as topic of the conversation (the first 4 names will be used)
]: any -> record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations/community")
  let body = {"description": $description, "participants": $participants, "topic": $topic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Updates the information of a community
#
# PUT /conversations/community/{convId}
# operationId: updateConversationCommunity
export def "conversations-community update" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # An optional description for the community conversation
  --topic: string # An optional topic of the conversation. If not set the Circuit client will render the names of the participants as topic of the conversation (the first 4 names will be used)
]: any -> record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/community/{conv_id}"))
  let body = {"description": $description, "topic": $topic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Adds the authenticated user to a community
#
# POST /conversations/community/{convId}/join
# operationId: joinCommunityConversation
export def "conversations-community-join joinCommunityConversation" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/community/{conv_id}/join"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes participants from a community
#
# DELETE /conversations/community/{convId}/participants
# operationId: removeParticipantCommunity
export def "conversations-community-participants delete" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --participants: list # The IDs or the unique email addresses of the Circuit users that have to be removed
]: nothing -> record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "participants" $participants "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/community/{conv_id}/participants") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds participants to a community
#
# POST /conversations/community/{convId}/participants
# operationId: addParticipantCommunity
export def "conversations-community-participants create" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  participants: list # The IDs or the unique email addresses of the Circuit users that should to be added.
]: any -> record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/community/{conv_id}/participants"))
  let body = {"participants": $participants} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Gets the conference details for multiple conversations
#
# GET /conversations/conversationdetails
# operationId: getJoinDetailsMultiple
export def "conversations-conversationdetails get-join-details-multiple" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --conv-ids: list # An array of IDs of the conversations for which the join details should be returned
]: nothing -> table<bridgeNumbers: list<record>, convId: string, conversationCreatorId: string, isModerationAllowed: bool, isRecordingAllowed: bool, link: string, pin: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "convIds" $conv_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations/conversationdetails" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks for a 1-to-1 conversation
#
# GET /conversations/direct
# operationId: getDirectConversation
export def "conversations-direct get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --participant: string # The participant that will be part of this conversation together with the creator, specified by the Circuit user ID or the unique email address
]: nothing -> record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "participant" $participant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations/direct" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a 1-to-1 conversation
#
# POST /conversations/direct
# operationId: createDirectConversation
export def "conversations-direct create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  participant: string # The participant that will be part of this conversation together with the creator, specified by the Circuit user ID or the unique email address
]: any -> record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations/direct")
  let body = {"participant": $participant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Gets favorite conversations
#
# GET /conversations/favorite
# operationId: getFavoriteConversations
export def "conversations-favorite get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations/favorite")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a group conversation
#
# POST /conversations/group
# operationId: createGroupConversation
export def "conversations-group create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  participants: list # A list of participants that will be part of this conversation, specified by the Circuit user ID or the unique email address. At least one participant needs to be added
  --topic: string # An optional topic of the conversation. If not set the Circuit client will render the names of the participants as topic of the conversation (the first 4 names will be used)
]: any -> record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations/group")
  let body = {"participants": $participants, "topic": $topic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Updates the information of a group conversation
#
# PUT /conversations/group/{convId}
# operationId: updateConversationGroup
export def "conversations-group update" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --topic: string # An optional topic of the conversation. If not set the Circuit client will render the names of the participants as topic of the conversation (the first 4 names will be used)
]: any -> record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/group/{conv_id}"))
  let body = {"topic": $topic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Removes participants from a group conversation
#
# DELETE /conversations/group/{convId}/participants
# operationId: removeParticipantGroup
export def "conversations-group-participants delete" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --participants: list # The IDs or the unique email addresses of the Circuit users that have to be removed
]: nothing -> record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "participants" $participants "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/group/{conv_id}/participants") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds participants to a group conversation
#
# POST /conversations/group/{convId}/participants
# operationId: addParticipantGroup
export def "conversations-group-participants create" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  participants: list # The IDs or the unique email addresses of the Circuit users that should to be added.
]: any -> record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/group/{conv_id}/participants"))
  let body = {"participants": $participants} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Returns conversations with a certain label
#
# GET /conversations/label/{labelId}
# operationId: getConversationsByLabel
export def "conversations-label get" [
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --next-page-pointer: string # Pointer to the next page of conversations if there are any
  --page-size: float # Numbers of max conversations per page (format: int32, default: 25)
]: nothing -> record<conversationList: table<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list, topic: string, topicPlaceholder: string, type: string>, hasMore: any, nextPagePointer: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextPagePointer" $next_page_pointer "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({label_id: $label_id} | format pattern "/conversations/label/{label_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of the flagged messages
#
# GET /conversations/messages/flag
# operationId: getFlagItemConv
export def "conversations-messages-flag get-flag-item-conv" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations/messages/flag")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a text item
#
# GET /conversations/messages/{itemId}
# operationId: getSingleConversationtem
export def "conversations-messages get-single-conversationtem" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attachments: table<creationTime: float, creatorId: string, deleteUrl: string, fileId: string, fileName: string, itemId: string, mimeType: string, modificationTime: float, size: float, url: string>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record<duration: float, maxNumberOfAttendees: float, pickFromParticipant: string>, missed: string, moved: record<conversationId: string, direction: string>, rtcParticipants: list<record>, type: string>, system: record<affectedParticipants: list<string>, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list<string>, parentId: string, preview: record<imageURI: string, srcURL: string, title: string, type: string>, state: string, subject: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({item_id: $item_id} | format pattern "/conversations/messages/{item_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set conversation moderated
#
# POST /conversations/moderate/{convId}
# operationId: moderateConversation
export def "conversations-moderate moderateConversation" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/moderate/{conv_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resolves an invite token to a conversation
#
# GET /conversations/resolveinvitetoken
# operationId: resolveInvitationToken
export def "conversations-resolveinvitetoken resolveInvitationToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-token: string # The invite token to resolve
]: nothing -> record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations/resolveinvitetoken" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Performs a conversation search
#
# GET /conversations/search
# operationId: searchConversations
export def "conversations-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --term: string # The search term
  --include-item-ids: oneof<nothing, bool> # Optional parameter to specify if a deep or normal search is executed. In a deep search all matching item IDs inside every conversation are returned (up to a maximum of 100). For a normal search only the conversation IDs are returned. Default is a normal search (without item IDs). (default: false)
  --scope: string@scope-completer # The search scope, FILES||PEOPLE||MEMBERS||MESSAGES||SENTBY||ALL||CONVERSATIONS||LABEL||FILTER (default: ALL)
]: nothing -> record<matchingConversations: table<convId: string, itemIds: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "term" $term "scalar") (serialize-qp "includeItemIds" $include_item_ids "scalar") (serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set conversation unmoderated
#
# POST /conversations/unmoderate/{convId}
# operationId: unmoderateConversation
export def "conversations-unmoderate unmoderateConversation" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/unmoderate/{conv_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a conversation
#
# GET /conversations/{convId}
# operationId: getConversationbyId
export def "conversations get-conversationby" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/{conv_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unmute conversation
#
# DELETE /conversations/{convId}/archive
# operationId: undoArchiveConversation
export def "conversations-archive undoArchiveConversation" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/{conv_id}/archive"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archives conversation
#
# POST /conversations/{convId}/archive
# operationId: archiveConversation
export def "conversations-archive archive" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/{conv_id}/archive"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the conference details of a conversation
#
# GET /conversations/{convId}/conversationdetails
# operationId: getJoinDetails
export def "conversations-conversationdetails get-join-details" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<bridgeNumbers: table<bridgeNumber: string, country: string, isMostUsed: bool, locale: string, name: string, type: string>, convId: string, conversationCreatorId: string, isModerationAllowed: bool, isRecordingAllowed: bool, link: string, pin: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/{conv_id}/conversationdetails"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a conversation from favorites
#
# DELETE /conversations/{convId}/favorite
# operationId: deleteFavorite
export def "conversations-favorite delete" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/{conv_id}/favorite"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a conversation to the favorites
#
# POST /conversations/{convId}/favorite
# operationId: addFavorite
export def "conversations-favorite create" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/{conv_id}/favorite"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of conversation items
#
# GET /conversations/{convId}/items
# operationId: getConversationItems
export def "conversations-items get" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --mod-time: string # The modification time of the item in UTC format. During the query the items before (default) or after this timestamps are returned. In case no timestamp is specified the current server time in UTC is used, i.e. the last 25 modified items are returned (format: date-time)
  --direction: string@direction-completer # The direction of the search based on the modification time. Valid values are either BEFORE (default) or AFTER (default: BEFORE)
  --results: float # The maximum number of returned results (default 25). The maximum allowed value is 100. (format: int32, default: 25)
]: nothing -> table<attachments: list<record>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record, missed: string, moved: record, rtcParticipants: list, type: string>, system: record<affectedParticipants: list, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list, parentId: string, preview: record, state: string, subject: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modTime" $mod_time "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "results" $results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/{conv_id}/items") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a label to a conversation
#
# POST /conversations/{convId}/label
# operationId: assignLabel
export def "conversations-label assignLabel" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  label: string # The actual label 
]: any -> record<labelId: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/{conv_id}/label"))
  let body = {"label": $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Removes a label from a conversation
#
# DELETE /conversations/{convId}/label/{labelId}
# operationId: unassignLabel
export def "conversations-label unassignLabel" [
  conv_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<labelId: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id, label_id: $label_id} | format pattern "/conversations/{conv_id}/label/{label_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a message to a conversation
#
# POST /conversations/{convId}/messages
# operationId: addTextItem
export def "conversations-messages create-text-item" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --attachments: list # A comma separated list of attachment IDs from the file API.
  --content: string # The actual content of the item, is mandatory unless an attachment is added
  --form-meta-data: string # The form meta data of the new text item
  --subject: string # The subject (headline) of the new text item
]: any -> record<attachments: table<creationTime: float, creatorId: string, deleteUrl: string, fileId: string, fileName: string, itemId: string, mimeType: string, modificationTime: float, size: float, url: string>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record<duration: float, maxNumberOfAttendees: float, pickFromParticipant: string>, missed: string, moved: record<conversationId: string, direction: string>, rtcParticipants: list<record>, type: string>, system: record<affectedParticipants: list<string>, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list<string>, parentId: string, preview: record<imageURI: string, srcURL: string, title: string, type: string>, state: string, subject: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/{conv_id}/messages"))
  let body = {"attachments": $attachments, "content": $content, "formMetaData": $form_meta_data, "subject": $subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Gets a list of the flagged messages of a conversation
#
# GET /conversations/{convId}/messages/flag
# operationId: getFlagItem
export def "conversations-messages-flag get-flag-item" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attachments: list<record>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record, missed: string, moved: record, rtcParticipants: list, type: string>, system: record<affectedParticipants: list, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list, parentId: string, preview: record, state: string, subject: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/{conv_id}/messages/flag"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a message from a conversation
#
# DELETE /conversations/{convId}/messages/{itemId}
# operationId: deleteTextItem
export def "conversations-messages delete-text-item" [
  conv_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attachments: table<creationTime: float, creatorId: string, deleteUrl: string, fileId: string, fileName: string, itemId: string, mimeType: string, modificationTime: float, size: float, url: string>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record<duration: float, maxNumberOfAttendees: float, pickFromParticipant: string>, missed: string, moved: record<conversationId: string, direction: string>, rtcParticipants: list<record>, type: string>, system: record<affectedParticipants: list<string>, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list<string>, parentId: string, preview: record<imageURI: string, srcURL: string, title: string, type: string>, state: string, subject: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id, item_id: $item_id} | format pattern "/conversations/{conv_id}/messages/{item_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a message to an item
#
# POST /conversations/{convId}/messages/{itemId}
# operationId: addTextItemWithParent
export def "conversations-messages create-text-item-with-parent" [
  conv_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --attachments: list # A comma separated list of attachment IDs from the file API.
  --content: string # The actual content of the item
  --form-meta-data: string # The form meta data of the new text item
  --subject: string # The subject (headline) of the new text item
]: any -> record<attachments: table<creationTime: float, creatorId: string, deleteUrl: string, fileId: string, fileName: string, itemId: string, mimeType: string, modificationTime: float, size: float, url: string>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record<duration: float, maxNumberOfAttendees: float, pickFromParticipant: string>, missed: string, moved: record<conversationId: string, direction: string>, rtcParticipants: list<record>, type: string>, system: record<affectedParticipants: list<string>, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list<string>, parentId: string, preview: record<imageURI: string, srcURL: string, title: string, type: string>, state: string, subject: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id, item_id: $item_id} | format pattern "/conversations/{conv_id}/messages/{item_id}"))
  let body = {"attachments": $attachments, "content": $content, "formMetaData": $form_meta_data, "subject": $subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Updates a message
#
# PUT /conversations/{convId}/messages/{itemId}
# operationId: updateTextItem
export def "conversations-messages update-text-item" [
  conv_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --attachments: list # A comma separated list of attachment IDs from the file API.
  --content: string # The actual content of the item
  --form-meta-data: string # The form meta data of the new text item
  --subject: string # The subject (headline) of the new text item
]: any -> record<attachments: table<creationTime: float, creatorId: string, deleteUrl: string, fileId: string, fileName: string, itemId: string, mimeType: string, modificationTime: float, size: float, url: string>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record<duration: float, maxNumberOfAttendees: float, pickFromParticipant: string>, missed: string, moved: record<conversationId: string, direction: string>, rtcParticipants: list<record>, type: string>, system: record<affectedParticipants: list<string>, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list<string>, parentId: string, preview: record<imageURI: string, srcURL: string, title: string, type: string>, state: string, subject: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id, item_id: $item_id} | format pattern "/conversations/{conv_id}/messages/{item_id}"))
  let body = {"attachments": $attachments, "content": $content, "formMetaData": $form_meta_data, "subject": $subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Removes the flag from a message
#
# DELETE /conversations/{convId}/messages/{itemId}/flag
# operationId: unFlagItem
export def "conversations-messages-flag unFlagItem" [
  conv_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id, item_id: $item_id} | format pattern "/conversations/{conv_id}/messages/{item_id}/flag"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a flag to a message in a conversation
#
# POST /conversations/{convId}/messages/{itemId}/flag
# operationId: flagItem
export def "conversations-messages-flag flagItem" [
  conv_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --item-creation-time: string # The time when the item was created
  --parent-id: string # The ID of the item's parent
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id, item_id: $item_id} | format pattern "/conversations/{conv_id}/messages/{item_id}/flag"))
  let body = {"itemCreationTime": $item_creation_time, "parentId": $parent_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Removes a "like" from a message
#
# DELETE /conversations/{convId}/messages/{itemId}/like
# operationId: unlikeItem
export def "conversations-messages-like unlikeItem" [
  conv_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id, item_id: $item_id} | format pattern "/conversations/{conv_id}/messages/{item_id}/like"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a "like" to a message
#
# POST /conversations/{convId}/messages/{itemId}/like
# operationId: likeItem
export def "conversations-messages-like likeItem" [
  conv_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id, item_id: $item_id} | format pattern "/conversations/{conv_id}/messages/{item_id}/like"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove moderators
#
# DELETE /conversations/{convId}/moderators
# operationId: removeModerators
export def "conversations-moderators delete" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  moderators: list # The list of moderator ids to remove
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/{conv_id}/moderators"))
  let body = {"moderators": $moderators} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add moderators
#
# POST /conversations/{convId}/moderators
# operationId: addModerators
export def "conversations-moderators create" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  moderators: list # The list of moderator ids to add 
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/{conv_id}/moderators"))
  let body = {"moderators": $moderators} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Performs a list of participants
#
# GET /conversations/{convId}/participants
# operationId: getParticipantsByConvId
export def "conversations-participants get" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: float # The page size of the hit list (format: int32)
  --name: string # Part of name to filter the results
  --type: string@type-completer # Type of participant to filter the results (default: REGULAR)
  --search-pointer: string # Pointer for paged output. Add to consecutive request to get next page
]: nothing -> table<hasMore: bool, participantList: list<record>, searchPointer: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "searchPointer" $search_pointer "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/{conv_id}/participants") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns pinned topics of a conversation
#
# GET /conversations/{convId}/pins
# operationId: getPinnedConversations
export def "conversations-pins get-pinned" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<conversationId: string, conversationItemId: string, pinnedTime: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id} | format pattern "/conversations/{conv_id}/pins"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unpins a topic of a conversation
#
# DELETE /conversations/{convId}/pins/{itemId}
# operationId: unPinAConversation
export def "conversations-pins unPinAConversation" [
  conv_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id, item_id: $item_id} | format pattern "/conversations/{conv_id}/pins/{item_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pins a topic of a conversation
#
# POST /conversations/{convId}/pins/{itemId}
# operationId: pinAConversation
export def "conversations-pins pinAConversation" [
  conv_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({conv_id: $conv_id, item_id: $item_id} | format pattern "/conversations/{conv_id}/pins/{item_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of active sessions
#
# GET /rtc/sessions
# operationId: getActiveSessions
export def "rtc-sessions get-active" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rtc/sessions")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the spaces
#
# GET /spaces
# operationId: getSpaces
export def "spaces get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --timestamp: string # a beautiful timestamp (format: date-time)
  --number-of-results: float # the number of results you want (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "numberOfResults" $number_of_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/spaces" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a space
#
# POST /spaces/create
# operationId: createSpace
export def "spaces-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  access_mode_type: string@access-mode-type-completer # Access mode (default: INTERNAL_ONLY)
  --description: string # description of the space
  --large-picture-base64: string # large picture
  name: string # name of the space
  role: string@role-completer # role (default: AUTHOR)
  --small-picture-base64: string # small picture
  status: string@status-completer # status (default: ENABLED)
  --tags: list # tags of the space
  type: string@type-completer-1 # type (default: SECRET)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/spaces/create")
  let body = {"accessModeType": $access_mode_type, "description": $description, "largePictureBase64": $large_picture_base64, "name": $name, "role": $role, "smallPictureBase64": $small_picture_base64, "status": $status, "tags": $tags, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get the directory
#
# GET /spaces/directory
# operationId: getDirectory
export def "spaces-directory get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --sort-by: string@sort-by-completer # sort the spaces by LAST_CONTENT, NAME, NUMBER_OF_USERS or CREATION_DATE (default: LAST_CONTENT)
  --sort-order: string@sort-order-completer # ascending or descending (default: ASCENDING)
  --filter: string@filter-completer # filter for spaces (JOINED, REQUESTED, OPEN, CLOSED or NOT_JOINED_REQUESTED) (default: NONE)
  --query: string # some sort of query
  --page-pointer: string # page pointer, start with nothing and for next query use returned pointer
  --number-of-results: float # number of results to return, 25 by default. (format: int32, default: 25)
]: nothing -> record<hasMore: bool, searchPointer: string, spaces: table<accessModeType: string, creationTime: float, creatorId: string, defaultRole: string, description: string, largePictureBase64: string, largePictureContentType: string, largePictureId: string, lastContentCreationTime: float, lastContentCreatorId: string, modificationTime: float, name: string, numberOfExternalParticipants: float, numberOfParticipants: float, numberOfPinnedTopics: float, numberOfReplies: float, numberOfTopics: float, ownerId: string, smallPictureBase64: string, smallPictureContentType: string, smallPictureId: string, spaceId: string, status: string, tags: list, tenantId: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "sortOrder" $sort_order "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "pagePointer" $page_pointer "scalar") (serialize-qp "numberOfResults" $number_of_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/spaces/directory" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Space name exists
#
# GET /spaces/exists/{name}
# operationId: existsSpaceName
export def "spaces-exists existsSpaceName" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: $name} | format pattern "/spaces/exists/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# flag a space item
#
# PUT /spaces/flag/{itemId}
# operationId: flagSpaceItem
export def "spaces-flag flagSpaceItem" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({item_id: $item_id} | format pattern "/spaces/flag/{item_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get flagged items
#
# GET /spaces/flagged
# operationId: getFlaggedItems
export def "spaces-flagged get-flagged-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-direction: string@search-direction-completer # before or after the time stamp (default: BEFORE)
  --timestamp: string # The timestamp according to which you want to retrieve the flagged items (format: date-time)
  --search-pointer: string # The searchpointer for the search (initially not set).
  --number-of-results: float # The number of results you want to retrieve. (format: int32, default: 25)
]: nothing -> record<flaggedItems: table<item: record, parentItem: record>, hasMore: bool, searchPointer: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchDirection" $search_direction "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "searchPointer" $search_pointer "scalar") (serialize-qp "numberOfResults" $number_of_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/spaces/flagged" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the spaces by their ids
#
# GET /spaces/ids
# operationId: getSpacesByIds
export def "spaces-ids get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ids: list # an array of ids
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/spaces/ids" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# deletes a space item
#
# DELETE /spaces/item/{itemId}
# operationId: deleteSpaceItem
export def "spaces-item delete" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({item_id: $item_id} | format pattern "/spaces/item/{item_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Like a space item
#
# PUT /spaces/like/{itemId}
# operationId: likeSpaceItem
export def "spaces-like likeSpaceItem" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({item_id: $item_id} | format pattern "/spaces/like/{item_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the likes of an item
#
# GET /spaces/likes/{itemId}
# operationId: getLikes
export def "spaces-likes get" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-pointer: string # The searchpointer for the search (initially not set).
  --number-of-results: float # The number of results you want to retrieve. (format: int32, default: 25)
]: nothing -> record<hasMore: bool, participants: table<firstName: string, largeImageUri: string, lastName: string, smallImageUri: string, userId: string>, searchPointer: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchPointer" $search_pointer "scalar") (serialize-qp "numberOfResults" $number_of_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item_id: $item_id} | format pattern "/spaces/likes/{item_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add recent search 
#
# PUT /spaces/search/add/recent
# operationId: addRecentSpaceSearch
export def "spaces-search-add-recent create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-time: string # The end time. (format: date-time)
  scope: string@scope-completer-1 # The scope of the search.
  search_term: string # The term to search for.
  --start-time: string # The start time. (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/spaces/search/add/recent")
  let body = {"endTime": $end_time, "scope": $scope, "searchTerm": $search_term, "startTime": $start_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Cancels a space search of a client.
#
# PUT /spaces/search/cancel/{searchId}
# operationId: cancelSpaceSearch
export def "spaces-search-cancel cancel" [
  search_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({search_id: $search_id} | format pattern "/spaces/search/cancel/{search_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve recent space searches
#
# GET /spaces/search/recent
# operationId: getRecentSearches
export def "spaces-search-recent get-recent-searches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/spaces/search/recent")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# starts a basic search in spaces
#
# GET /spaces/search/startBasic
# operationId: startBasicSpacesSearch
export def "spaces-search-start-basic start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --scope: string@scope-completer-1 # the scope of the search
  --search-term: string # the term to search for
  --start-time: string # the starttime (format: date-time)
  --end-time: string # the end time (format: date-time)
  --priority-spaces: list # list of prioritized spaces
]: nothing -> record<spaces: table<accessModeType: string, creationTime: float, creatorId: string, defaultRole: string, description: string, largePictureBase64: string, largePictureContentType: string, largePictureId: string, lastContentCreationTime: float, lastContentCreatorId: string, modificationTime: float, name: string, numberOfExternalParticipants: float, numberOfParticipants: float, numberOfPinnedTopics: float, numberOfReplies: float, numberOfTopics: float, ownerId: string, smallPictureBase64: string, smallPictureContentType: string, smallPictureId: string, spaceId: string, status: string, tags: list, tenantId: string, type: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "searchTerm" $search_term "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar") (serialize-qp "prioritySpaces" $priority_spaces "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/spaces/search/startBasic" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# starts a detailed search in a space
#
# GET /spaces/search/startDetailed
# operationId: startDetailedSpaceSearch
export def "spaces-search-start-detailed start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --scope: string@scope-completer-1 # the scope of the search
  --search-term: string # the term to search for
  --start-time: string # the starttime (format: date-time)
  --end-time: string # the end time (format: date-time)
  --space-id: string # missing documentation
  --search-id: string # missing documentation
]: nothing -> table<resList: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "searchTerm" $search_term "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar") (serialize-qp "spaceId" $space_id "scalar") (serialize-qp "searchId" $search_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/spaces/search/startDetailed" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update tags
#
# PUT /spaces/topic/{topicId}/updateTags
# operationId: updateTopicTags
export def "spaces-topic-update-tags update" [
  topic_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  tags: list # The tags to update
]: any -> record<lastContentCreationTime: float, lastContentCreatorId: string, numberOfReplies: float, pinned: bool, spaceItem: record<Status: string, attachments: list<record>, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list<record>, formMetaData: string, itemId: string, mentionedUsers: list<string>, modificationTime: float, numberOfLikes: float, previews: list<record>, sharedItems: list<record>, spaceId: string, tenantId: string>, subject: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({topic_id: $topic_id} | format pattern "/spaces/topic/{topic_id}/updateTags"))
  let body = {"tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Unflag a space item
#
# PUT /spaces/unflag/{itemId}
# operationId: unflagSpaceItem
export def "spaces-unflag unflagSpaceItem" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({item_id: $item_id} | format pattern "/spaces/unflag/{item_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unlike a space item
#
# PUT /spaces/unlike/{itemId}
# operationId: unlikeSpaceItem
export def "spaces-unlike unlikeSpaceItem" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({item_id: $item_id} | format pattern "/spaces/unlike/{item_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a space
#
# DELETE /spaces/{id}
# operationId: deleteSpace
export def "spaces delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/spaces/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a space
#
# PUT /spaces/{id}
# operationId: updateSpace
export def "spaces update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --access-mode-type: string@access-mode-type-completer-1 # Access mode (default: NO_CHANGE)
  --description: string # description of the space
  --large-picture-base64: string # large picture
  --name: string # name of the space
  --owner-id: string # ownerid of the space
  --role: string@role-completer-1 # role (default: NO_CHANGE)
  --small-picture-base64: string # small picture
  --status: string@status-completer # status (default: ENABLED)
  --tags: list # tags of the space
  --type: string@type-completer-2 # type (default: NO_CHANGE)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/spaces/{id}"))
  let body = {"accessModeType": $access_mode_type, "description": $description, "largePictureBase64": $large_picture_base64, "name": $name, "ownerId": $owner_id, "role": $role, "smallPictureBase64": $small_picture_base64, "status": $status, "tags": $tags, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Join a space
#
# POST /spaces/{id}/join
# operationId: joinSpace
export def "spaces-join joinSpace" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/spaces/{id}/join"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign labels
#
# POST /spaces/{id}/labels/assign
# operationId: assignLabels
export def "spaces-labels-assign assignLabels" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  labels: list # The labels to assign to the space
]: any -> table<labelIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/spaces/{id}/labels/assign"))
  let body = {"labels": $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Unassign labels
#
# DELETE /spaces/{id}/labels/unassign
# operationId: unassignLabels
export def "spaces-labels-unassign unassignLabels" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  label_ids: list # missing documentation
]: any -> table<labelIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/spaces/{id}/labels/unassign"))
  let body = {"labelIds": $label_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Leave a space
#
# POST /spaces/{id}/leave
# operationId: leaveSpace
export def "spaces-leave leaveSpace" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/spaces/{id}/leave"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Participant to Space
#
# POST /spaces/{id}/participant
# operationId: addParticipantsToSpace
export def "spaces-participant create-participants-to" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  role: string@role-completer-2 # The name of the role of the participant (default: DEFAULT)
  user_id: list # The user id of the participant
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/spaces/{id}/participant"))
  let body = {"role": $role, "userId": $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Removes participants from a space
#
# POST /spaces/{id}/participant/remove
# operationId: v2RemoveParticipantsFromSpace
export def "spaces-participant-remove v2RemoveParticipantsFromSpace" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_ids: list # The ids of the participants to remove 
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/spaces/{id}/participant/remove"))
  let body = {"userIds": $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get the participants of a space
#
# GET /spaces/{id}/participants
# operationId: getSpaceParticipants
export def "spaces-participants get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --sort-by: string@sort-by-completer-1 # sort the spaces by LAST_CONTENT, NAME, NUMBER_OF_USERS or CREATION_DATE (default: NAME)
  --sort-order: string@sort-order-completer # ascending or descending (default: ASCENDING)
  --filter-type: string@filter-type-completer # filtertype for participants (ACCESS_TYPE, ROLE or STATE)
  --filter-value: string # value for the filter
  --query: string # some sort of query
  --search-pointer: string # The search pointer (leave empty initially).
  --number-of-results: float # number of results to return, 25 by default. (format: int32, default: 25)
]: nothing -> record<hasMore: bool, participants: table<creationTime: float, firstName: string, lastName: string, modificationTime: float, numberOfReplies: float, numberOfTopics: float, role: string, smallImageUri: string, state: string, tenantId: string, userId: string>, searchPointer: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "sortOrder" $sort_order "scalar") (serialize-qp "filterType" $filter_type "scalar") (serialize-qp "filterValue" $filter_value "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "searchPointer" $search_pointer "scalar") (serialize-qp "numberOfResults" $number_of_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/spaces/{id}/participants") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the pending participants of a space
#
# GET /spaces/{id}/participants/pending
# operationId: getPendingParticipants
export def "spaces-participants-pending get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-pointer: string # The search pointer (leave empty initially).
  --number-of-results: float # number of results to return, 25 by default. (format: int32, default: 25)
]: nothing -> record<hasMore: bool, participants: table<creationTime: float, firstName: string, lastName: string, modificationTime: float, numberOfReplies: float, numberOfTopics: float, role: string, smallImageUri: string, state: string, tenantId: string, userId: string>, searchPointer: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchPointer" $search_pointer "scalar") (serialize-qp "numberOfResults" $number_of_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/spaces/{id}/participants/pending") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve pinned topics
#
# GET /spaces/{id}/pinnedTopics
# operationId: getPinnedTopics
export def "spaces-pinned-topics get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<position: float, subject: string, topicId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/spaces/{id}/pinnedTopics"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Finds participants to add to add to a space 
#
# GET /spaces/{id}/searchParticipantsToAdd
# operationId: searchParticipantsToAdd
export def "spaces-search-participants-to-add list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # The query 
]: nothing -> table<department: string, firstName: string, isMember: bool, jobTitle: string, lastName: string, smallImageUri: string, tenantId: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/spaces/{id}/searchParticipantsToAdd") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the participants of a space
#
# GET /spaces/{id}/searchSpaceParticipants
# operationId: searchSpaceParticipants
export def "spaces-search-space-participants list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # The query to search with. If searchpointer/hasMotre is returned, refine query.
]: nothing -> table<hasMore: bool, participants: list<record>, searchPointer: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/spaces/{id}/searchSpaceParticipants") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update read timestamp
#
# PUT /spaces/{id}/updateTimestamp
# operationId: updateReadTimestamp
export def "spaces-update-timestamp update-read" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  timestamp: string # The new timestamp (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/spaces/{id}/updateTimestamp"))
  let body = {"timestamp": $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update participant
#
# PUT /spaces/{spaceId}/participant
# operationId: updateParticipantInSpace
export def "spaces-participant update-participant-in" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  role: string@role-completer # updated role of participant
  user_id: string # The id of the participant to update
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: $space_id} | format pattern "/spaces/{space_id}/participant"))
  let body = {"role": $role, "userId": $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# missing documentation
#
# GET /spaces/{spaceId}/participant/import/
# operationId: getParticipantsImportData
export def "spaces-participant-import get-participants-import-data" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<actualNumberOfImportedParticipants: float, estimatedImportDuration: float, importEndDate: float, importFileId: string, importFileName: string, importProgress: float, importStartDate: float, importStatus: string, plannedNumberOfImportedParticipants: float, resultFileId: string, resultFileName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: $space_id} | format pattern "/spaces/{space_id}/participant/import/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# request access for a space
#
# POST /spaces/{spaceId}/participant/request
# operationId: requestSpaceAcces
export def "spaces-participant-request request-space-acces" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason why the Access has been requested
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: $space_id} | format pattern "/spaces/{space_id}/participant/request"))
  let body = {"reason": $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Deny access for a space
#
# POST /spaces/{spaceId}/participant/{participantId}/deny
# operationId: denySpaceAcces
export def "spaces-participant-deny denySpaceAcces" [
  space_id: string
  participant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason why the request has been denied
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: $space_id, participant_id: $participant_id} | format pattern "/spaces/{space_id}/participant/{participant_id}/deny"))
  let body = {"reason": $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# grant access for a space
#
# POST /spaces/{spaceId}/participant/{participantId}/grant
# operationId: grantSpaceAcces
export def "spaces-participant-grant grantSpaceAcces" [
  space_id: string
  participant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: $space_id, participant_id: $participant_id} | format pattern "/spaces/{space_id}/participant/{participant_id}/grant"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# creates a new space topic
#
# POST /spaces/{spaceId}/topic
# operationId: createSpaceTopic
export def "spaces-topic create" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --attachments: list # the attached files
  --complex: oneof<nothing, bool> # complex or not
  --content: string # The content of this topic
  --content-tags: list # the content tags
  --form-meta-data: string # The formMetaData
  --mentioned-user: string # A list of mentioned users
  subject: string # The subject of the topic
  --tags: list # the tags
]: any -> record<lastContentCreationTime: float, lastContentCreatorId: string, numberOfReplies: float, pinned: bool, spaceItem: record<Status: string, attachments: list<record>, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list<record>, formMetaData: string, itemId: string, mentionedUsers: list<string>, modificationTime: float, numberOfLikes: float, previews: list<record>, sharedItems: list<record>, spaceId: string, tenantId: string>, subject: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: $space_id} | format pattern "/spaces/{space_id}/topic"))
  let body = {"attachments": $attachments, "complex": $complex, "content": $content, "contentTags": $content_tags, "formMetaData": $form_meta_data, "mentionedUser": $mentioned_user, "subject": $subject, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Gets space replies and a topic
#
# GET /spaces/{spaceId}/topic/{topicId}
# operationId: v2GetTopicWithReplies
export def "spaces-topic v2GetTopicWithReplies" [
  space_id: string
  topic_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --number-of-replies: float # The number of replies (format: int32, default: 25)
]: nothing -> record<replies: table<parentTopicId: string, spaceItem: record>, topic: record<lastContentCreationTime: float, lastContentCreatorId: string, numberOfReplies: float, pinned: bool, spaceItem: record<Status: string, attachments: list, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list, formMetaData: string, itemId: string, mentionedUsers: list, modificationTime: float, numberOfLikes: float, previews: list, sharedItems: list, spaceId: string, tenantId: string>, subject: string, tags: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "numberOfReplies" $number_of_replies "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: $space_id, topic_id: $topic_id} | format pattern "/spaces/{space_id}/topic/{topic_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a topic
#
# PUT /spaces/{spaceId}/topic/{topicId}
# operationId: updateSpaceTopic
export def "spaces-topic update" [
  space_id: string
  topic_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --attachments: list # the attached files
  --complex: oneof<nothing, bool> # complex or not
  --content: string # content of the topic
  --content-tags: list # the content tags
  --form-meta-data: string # formMetaData to update
  --mentioned-users: list # the updated mentioned users
  --subject: string # the subject of the topic
  --tags: list # the tags
]: any -> record<lastContentCreationTime: float, lastContentCreatorId: string, numberOfReplies: float, pinned: bool, spaceItem: record<Status: string, attachments: list<record>, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list<record>, formMetaData: string, itemId: string, mentionedUsers: list<string>, modificationTime: float, numberOfLikes: float, previews: list<record>, sharedItems: list<record>, spaceId: string, tenantId: string>, subject: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: $space_id, topic_id: $topic_id} | format pattern "/spaces/{space_id}/topic/{topic_id}"))
  let body = {"attachments": $attachments, "complex": $complex, "content": $content, "contentTags": $content_tags, "formMetaData": $form_meta_data, "mentionedUsers": $mentioned_users, "subject": $subject, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Gets space replies
#
# GET /spaces/{spaceId}/topic/{topicId}/reply
# operationId: getSpaceReplies
export def "spaces-topic-reply get-space-replies" [
  space_id: string
  topic_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-direction: string@search-direction-completer # Search before or after a certain timestamp (default: BEFORE)
  --timestamp: string # Timestamp to start the search from (format: date-time)
  --number-of-results: float # The number of results that should be returned (format: int32, default: 25)
]: nothing -> record<parentTopicId: string, spaceItem: record<Status: string, attachments: list<record>, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list<record>, formMetaData: string, itemId: string, mentionedUsers: list<string>, modificationTime: float, numberOfLikes: float, previews: list<record>, sharedItems: list<record>, spaceId: string, tenantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchDirection" $search_direction "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "numberOfResults" $number_of_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: $space_id, topic_id: $topic_id} | format pattern "/spaces/{space_id}/topic/{topic_id}/reply") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# creates a reply to a topic
#
# POST /spaces/{spaceId}/topic/{topicId}/reply
# operationId: createReply
export def "spaces-topic-reply create" [
  space_id: string
  topic_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --attachments: list # the attached files
  --complex: oneof<nothing, bool> # complex or not
  --content: string # Content of the reply
  --form-meta-data: string # formMetaData used in the reply
  --mentioned-user: string # the user mentioned in the reply
]: any -> record<parentTopicId: string, spaceItem: record<Status: string, attachments: list<record>, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list<record>, formMetaData: string, itemId: string, mentionedUsers: list<string>, modificationTime: float, numberOfLikes: float, previews: list<record>, sharedItems: list<record>, spaceId: string, tenantId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: $space_id, topic_id: $topic_id} | format pattern "/spaces/{space_id}/topic/{topic_id}/reply"))
  let body = {"attachments": $attachments, "complex": $complex, "content": $content, "formMetaData": $form_meta_data, "mentionedUser": $mentioned_user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Updates a space reply
#
# PUT /spaces/{spaceId}/topic/{topicId}/reply/{replyId}
# operationId: updateSpaceReply
export def "spaces-topic-reply update" [
  space_id: string
  topic_id: string
  reply_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --attachments: list # the attached files
  --complex: oneof<nothing, bool> # complex or not
  --content: string # the content of the reply
  --form-meta-data: string # formMetaData of the reply
  --mentioned-users: list # the mentioned users in the reply
]: any -> record<parentTopicId: string, spaceItem: record<Status: string, attachments: list<record>, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list<record>, formMetaData: string, itemId: string, mentionedUsers: list<string>, modificationTime: float, numberOfLikes: float, previews: list<record>, sharedItems: list<record>, spaceId: string, tenantId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: $space_id, topic_id: $topic_id, reply_id: $reply_id} | format pattern "/spaces/{space_id}/topic/{topic_id}/reply/{reply_id}"))
  let body = {"attachments": $attachments, "complex": $complex, "content": $content, "formMetaData": $form_meta_data, "mentionedUsers": $mentioned_users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Gets space topics
#
# GET /spaces/{spaceId}/topics
# operationId: getSpaceTopics
export def "spaces-topics get" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-direction: string@search-direction-completer # Search before or after a certain timestamp (default: BEFORE)
  --timestamp: string # Timestamp to start the search from (format: date-time)
  --number-of-results: float # The number of results that should be returned (format: int32, default: 25)
]: nothing -> table<lastContentCreationTime: float, lastContentCreatorId: string, numberOfReplies: float, pinned: bool, spaceItem: record<Status: string, attachments: list, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list, formMetaData: string, itemId: string, mentionedUsers: list, modificationTime: float, numberOfLikes: float, previews: list, sharedItems: list, spaceId: string, tenantId: string>, subject: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchDirection" $search_direction "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "numberOfResults" $number_of_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: $space_id} | format pattern "/spaces/{space_id}/topics") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update content of welcome box
#
# PUT /spaces/{spaceId}/welcomebox/{content}
# operationId: v2UpdateWelcomeBoxContent
export def "spaces-welcomebox v2UpdateWelcomeBoxContent" [
  space_id: string
  content: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-welcome-box: oneof<nothing, bool> # True, false, default:false (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: $space_id, content: $content} | format pattern "/spaces/{space_id}/welcomebox/{content}"))
  let body = {"displayWelcomeBox": $display_welcome_box} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Pin a topic
#
# PUT /spaces/{topicId}/pin
# operationId: pinTopic
export def "spaces-pin pinTopic" [
  topic_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  position: float # The position to pin to (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({topic_id: $topic_id} | format pattern "/spaces/{topic_id}/pin"))
  let body = {"position": $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Unpin a topic
#
# PUT /spaces/{topicId}/unpin
# operationId: unpinTopic
export def "spaces-unpin unpinTopic" [
  topic_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({topic_id: $topic_id} | format pattern "/spaces/{topic_id}/unpin"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get devices infos
#
# GET /telephony/deviceInfos
# operationId: v2GetDeviceInfos
export def "telephony-device-infos v2GetDeviceInfos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/telephony/deviceInfos")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get telephony conversation id
#
# GET /telephony/telephonyConversationId
# operationId: v2GetTelephonyConversationId
export def "telephony-telephony-conversation-id v2GetTelephonyConversationId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/telephony/telephonyConversationId")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get journal
#
# GET /telephony/{telephonyConversationId}/journal
# operationId: getJournalEntries
export def "telephony-journal get-journal-entries" [
  telephony_conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --timestamp: float # A timestamp, default = 0 (format: int64, default: 0)
  --number-of-entries: float # The number of entries, between 1 and 100, default = 25 (format: int32, default: 25)
  --direction: string@direction-completer-1 # The direction (BEFORE||AFTER||BOTH), default = AFTER (default: AFTER)
  --journal-filter: string@journal-filter-completer # The filter, ALL||MISSED||DIALED||RECEIVED||DIVERTED||VOICEMAILS||UNHERAD_VOICEMAILS. default = ALL (default: ALL)
]: nothing -> table<attachments: list<record>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record, missed: string, moved: record, rtcParticipants: list, type: string>, system: record<affectedParticipants: list, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list, parentId: string, preview: record, state: string, subject: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "numberOfEntries" $number_of_entries "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "journalFilter" $journal_filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({telephony_conversation_id: $telephony_conversation_id} | format pattern "/telephony/{telephony_conversation_id}/journal") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for users
#
# GET /users
# operationId: searchUser
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # Search for a user by name
]: nothing -> table<avatar: string, avatarLarge: string, company: string, department: string, displayName: string, emailAddress: string, emailAddresses: list<record>, firstName: string, jobTitle: string, lastName: string, locale: string, phoneNumber: string, phoneNumbers: list<record>, primaryTenantId: string, secondaryEmailAddress: string, secondaryTenantId: string, userId: string, userState: string, userType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all user labels
#
# GET /users/labels
# operationId: getLabel
export def "users-labels get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/labels")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a user label
#
# POST /users/labels
# operationId: addLabel
export def "users-labels create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  label: string # The label value to add
]: any -> record<labelId: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/labels")
  let body = {"label": $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a user label
#
# DELETE /users/labels/{labelId}
# operationId: removeLabel
export def "users-labels delete" [
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<labelId: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({label_id: $label_id} | format pattern "/users/labels/{label_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search multiple users.
#
# GET /users/list
# operationId: searchUsersList
export def "users-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: list # Multiple email addresses or UUIDs.
  --return-full-user-info: oneof<nothing, bool> # Boolean, return full user info? (default: false)
  --secondary-lookup: oneof<nothing, bool> # Boolean, lookup secondary email? (default: false)
]: nothing -> table<avatar: string, avatarLarge: string, company: string, department: string, displayName: string, emailAddress: string, emailAddresses: list<record>, firstName: string, jobTitle: string, lastName: string, locale: string, phoneNumber: string, phoneNumbers: list<record>, primaryTenantId: string, secondaryEmailAddress: string, secondaryTenantId: string, userId: string, userState: string, userType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "multi") (serialize-qp "returnFullUserInfo" $return_full_user_info "scalar") (serialize-qp "secondaryLookup" $secondary_lookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/list" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the presence status
#
# GET /users/presence
# operationId: getPresence
export def "users-presence list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --user-ids: list # A list of unique user IDs or email addresses of the users you want to query the presence state for
]: nothing -> table<dndUntil: float, isOptedOut: bool, latitude: float, locationText: string, longitude: float, mobile: bool, poor: bool, state: string, statusMessage: string, timeZoneOffset: float, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userIds" $user_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/users/presence" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the presence status
#
# PUT /users/presence
# operationId: setUserPresence
export def "users-presence setUserPresence" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --clear-dnd: oneof<nothing, bool> # Clear the DND of the user. (default: false)
  --dnd-until: string # Timestamp until the DND state of the user is active. This field is mandatory when the state is set to DND. (format: date-time)
  state: string # The user's presence.
  --status-message: string # An optional status message that is displayed instead of the location
]: any -> record<dndUntil: float, isOptedOut: bool, latitude: float, locationText: string, longitude: float, mobile: bool, poor: bool, state: string, statusMessage: string, timeZoneOffset: float, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/presence")
  let body = {"clearDND": $clear_dnd, "dndUntil": $dnd_until, "state": $state, "statusMessage": $status_message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Gets the authenticated user's profile information
#
# GET /users/profile
# operationId: getProfile
export def "users-profile get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/profile")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the user profile
#
# PUT /users/profile
# operationId: updateProfile
export def "users-profile update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --firstname: string # The new firstname of the user
  --job-title: string # The new job title of the user
  --lastname: string # The new lastname of the user
  --locale: string@locale-completer # The new locale of the user. One of EN_US, DE_DE, EN_GB, ES_ES, FR_FR, IT_IT, RU_RU, ZH_HANS_CN.
]: any -> record<avatar: string, avatarLarge: string, company: string, department: string, displayName: string, emailAddress: string, emailAddresses: table<address: string, type: string>, firstName: string, jobTitle: string, lastName: string, locale: string, phoneNumber: string, phoneNumbers: table<phoneNumber: string, type: string>, primaryTenantId: string, secondaryEmailAddress: string, secondaryTenantId: string, userId: string, userState: string, userType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/profile")
  let body = {"firstname": $firstname, "jobTitle": $job_title, "lastname": $lastname, "locale": $locale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Gets the support information
#
# GET /users/supportinfo
# operationId: getSupportInfo
export def "users-supportinfo get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/supportinfo")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user by email
#
# GET /users/{emailAddress}/getUserByEmail
# operationId: getUserByEmailAddress
export def "users-get-user-by-email get" [
  email_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --secondary-lookup: oneof<nothing, bool> # secondaryLookup enabled (default = false)
]: nothing -> record<avatar: string, avatarLarge: string, company: string, department: string, displayName: string, emailAddress: string, emailAddresses: table<address: string, type: string>, firstName: string, jobTitle: string, lastName: string, locale: string, phoneNumber: string, phoneNumbers: table<phoneNumber: string, type: string>, primaryTenantId: string, secondaryEmailAddress: string, secondaryTenantId: string, userId: string, userState: string, userType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "secondaryLookup" $secondary_lookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({email_address: $email_address} | format pattern "/users/{email_address}/getUserByEmail") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the user's profile information
#
# GET /users/{id}
# operationId: getUserById
export def "users get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<avatar: string, avatarLarge: string, company: string, department: string, displayName: string, emailAddress: string, emailAddresses: table<address: string, type: string>, firstName: string, jobTitle: string, lastName: string, locale: string, phoneNumber: string, phoneNumbers: table<phoneNumber: string, type: string>, primaryTenantId: string, secondaryEmailAddress: string, secondaryTenantId: string, userId: string, userState: string, userType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/users/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the presence status
#
# GET /users/{id}/presence
# operationId: getUserPresence
export def "users-presence get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<dndUntil: float, isOptedOut: bool, latitude: float, locationText: string, longitude: float, mobile: bool, poor: bool, state: string, statusMessage: string, timeZoneOffset: float, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/users/{id}/presence"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes all webHooks
#
# DELETE /webhooks
# operationId: removeWebHooks
export def "webhooks delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of webHooks
#
# GET /webhooks
# operationId: getWebHook
export def "webhooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Registers a WebHook
#
# POST /webhooks
# operationId: addWebHook
export def "webhooks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  filter: list # A filter for WebHooks that checks for a list of configured events. This filter will use a regular expression to determine if it is interested in the events or not. The event itself is converted into a string of format AREA.EVENT. Examples: CONVERSATION.CREATE / USER.UPDATE
  --body-url: string # WebHook callback URL
]: any -> record<creationTime: float, filter: list<string>, id: string, subscriptionIds: list<string>, type: string, url: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let body = {"filter": $filter, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a new webhook for existing conversation.
#
# POST /webhooks/incoming/create/{conversationId}
# operationId: createIncomingWebhook
export def "webhooks-incoming-create create" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # The name of the webhook
  --user-id: string # The id of the user of the webhook
  --description: string # A short description of the webhook
]: nothing -> record<conversationId: string, creationTime: float, creatorId: string, description: string, modificationTime: float, name: string, status: string, tenantId: string, url: string, userId: string, webhookId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "userId" $user_id "scalar") (serialize-qp "description" $description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({conversation_id: $conversation_id} | format pattern "/webhooks/incoming/create/{conversation_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all webhooks of a special user.
#
# GET /webhooks/incoming/user/{userId}
# operationId: getIncomingWebhookByUser
export def "webhooks-incoming-user get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pagesize: float # Max number of hooks per request. Default is 25 (format: int32, default: 25)
  --searchpointer: string # Start of search if consequtive call.
]: nothing -> table<conversationId: string, creationTime: float, creatorId: string, description: string, modificationTime: float, name: string, status: string, tenantId: string, url: string, userId: string, webhookId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagesize" $pagesize "scalar") (serialize-qp "searchpointer" $searchpointer "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/webhooks/incoming/user/{user_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing webhook
#
# DELETE /webhooks/incoming/{webhookId}
# operationId: deleteIncomingWebhook
export def "webhooks-incoming delete" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({webhook_id: $webhook_id} | format pattern "/webhooks/incoming/{webhook_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post text item for conversation via webhook.
#
# POST /webhooks/incoming/{webhookId}
# operationId: postWebhookAsSlackMessage
export def "webhooks-incoming create-webhook-as-slack-message" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-url: string # missing documentation
  --filename: string # missing documentation
  --markdown: oneof<nothing, bool> # missing documentation
  --subject: string # missing documentation
  --text: string # The text which will occur in the conversation. May contain formats like *bold* or _italic_
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({webhook_id: $webhook_id} | format pattern "/webhooks/incoming/{webhook_id}"))
  let body = {"fileURL": $file_url, "filename": $filename, "markdown": $markdown, "subject": $subject, "text": $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Registers Presence WebHook registration
#
# POST /webhooks/presence
# operationId: addPresenceWebHook
export def "webhooks-presence create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body-url: string # WebHook callback URL
  user_ids: list # The IDs of the users to subscribe for their presence
]: any -> record<creationTime: float, filter: list<string>, id: string, subscriptionIds: list<string>, type: string, url: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks/presence")
  let body = {"url": $body_url, "userIds": $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Updates a Presence WebHook registration
#
# PUT /webhooks/presence/{id}
# operationId: updatePresenceWebHook
export def "webhooks-presence update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body-url: string # WebHook callback URL
  --user-ids: list # The IDs of the users to subscribe for their presence
]: any -> record<creationTime: float, filter: list<string>, id: string, subscriptionIds: list<string>, type: string, url: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/webhooks/presence/{id}"))
  let body = {"url": $body_url, "userIds": $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Removes a registered webHook
#
# DELETE /webhooks/{id}
# operationId: removeWebHook
export def "webhooks delete-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/webhooks/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a webHook
#
# GET /webhooks/{id}
# operationId: getWebHookById
export def "webhooks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<creationTime: float, filter: list<string>, id: string, subscriptionIds: list<string>, type: string, url: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/webhooks/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a WebHook registration
#
# PUT /webhooks/{id}
# operationId: updateWebHook
export def "webhooks update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: list # A filter for WebHooks that checks for a list of configured events. This filter will use a regular expression to determine if it is interested in the events or not. The event itself is converted into a string of format AREA.EVENT. Examples: CONVERSATION.CREATE / USER.UPDATE
  --body-url: string # WebHook callback URL
]: any -> record<creationTime: float, filter: list<string>, id: string, subscriptionIds: list<string>, type: string, url: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/webhooks/{id}"))
  let body = {"filter": $filter, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}
