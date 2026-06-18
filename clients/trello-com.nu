# Auto-generated client for Trello v1.0
# Source: https://api.apis.guru/v2/specs/trello.com/1.0/openapi.json
# Auth: --token flag or $env.TRELLO_TOKEN

const BASE_URL = "https://trello.com/1"
const DEFAULT_AUTH = "query-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TRELLO_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-key" => { {headers: {}, query: $"(encode-path-segment "key")=(encode-path-segment $token_val)"} }
    "query-token" => { {headers: {}, query: $"(encode-path-segment "token")=(encode-path-segment $token_val)"} }
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

def base-url-completer [] { ["https://trello.com/1"] }
def auth-scheme-completer [] { ["query-key" "query-token"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "actions delete" } } | get name | first)
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

# deleteActionsByIdAction()
#
# DELETE /actions/{idAction}
# operationId: deleteActionsByIdAction
export def "actions delete" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: (encode-path-segment $id_action)} | format pattern "/actions/{id_action}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getActionsByIdAction()
#
# GET /actions/{idAction}
# operationId: getActionsByIdAction
export def "actions get" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display: string # true or false
  --entities: string # true or false
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --member-creator: string # true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "display" $display "scalar") (serialize-qp "entities" $entities "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "memberCreator" $member_creator "scalar") (serialize-qp "memberCreator_fields" $member_creator_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: (encode-path-segment $id_action)} | format pattern "/actions/{id_action}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateActionsByIdAction()
#
# PUT /actions/{idAction}
# operationId: updateActionsByIdAction
export def "actions update" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --text: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: (encode-path-segment $id_action)} | format pattern "/actions/{id_action}") $qp)
  let req_body = {"text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getActionsBoardByIdAction()
#
# GET /actions/{idAction}/board
# operationId: getActionsBoardByIdAction
export def "actions-board get" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: (encode-path-segment $id_action)} | format pattern "/actions/{id_action}/board") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getActionsBoardByIdActionByField()
#
# GET /actions/{idAction}/board/{field}
# operationId: getActionsBoardByIdActionByField
export def "actions-board get-by" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: (encode-path-segment $id_action), field: (encode-path-segment $field)} | format pattern "/actions/{id_action}/board/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getActionsCardByIdAction()
#
# GET /actions/{idAction}/card
# operationId: getActionsCardByIdAction
export def "actions-card get" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: (encode-path-segment $id_action)} | format pattern "/actions/{id_action}/card") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getActionsCardByIdActionByField()
#
# GET /actions/{idAction}/card/{field}
# operationId: getActionsCardByIdActionByField
export def "actions-card get-by" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: (encode-path-segment $id_action), field: (encode-path-segment $field)} | format pattern "/actions/{id_action}/card/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getActionsDisplayByIdAction()
#
# GET /actions/{idAction}/display
# operationId: getActionsDisplayByIdAction
export def "actions-display get" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: (encode-path-segment $id_action)} | format pattern "/actions/{id_action}/display") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getActionsEntitiesByIdAction()
#
# GET /actions/{idAction}/entities
# operationId: getActionsEntitiesByIdAction
export def "actions-entities get" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: (encode-path-segment $id_action)} | format pattern "/actions/{id_action}/entities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getActionsListByIdAction()
#
# GET /actions/{idAction}/list
# operationId: getActionsListByIdAction
export def "actions-list get" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: (encode-path-segment $id_action)} | format pattern "/actions/{id_action}/list") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getActionsListByIdActionByField()
#
# GET /actions/{idAction}/list/{field}
# operationId: getActionsListByIdActionByField
export def "actions-list get-by" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: (encode-path-segment $id_action), field: (encode-path-segment $field)} | format pattern "/actions/{id_action}/list/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getActionsMemberByIdAction()
#
# GET /actions/{idAction}/member
# operationId: getActionsMemberByIdAction
export def "actions-member get" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: (encode-path-segment $id_action)} | format pattern "/actions/{id_action}/member") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getActionsMemberByIdActionByField()
#
# GET /actions/{idAction}/member/{field}
# operationId: getActionsMemberByIdActionByField
export def "actions-member get-by" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: (encode-path-segment $id_action), field: (encode-path-segment $field)} | format pattern "/actions/{id_action}/member/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getActionsMemberCreatorByIdAction()
#
# GET /actions/{idAction}/memberCreator
# operationId: getActionsMemberCreatorByIdAction
export def "actions-member-creator get" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: (encode-path-segment $id_action)} | format pattern "/actions/{id_action}/memberCreator") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getActionsMemberCreatorByIdActionByField()
#
# GET /actions/{idAction}/memberCreator/{field}
# operationId: getActionsMemberCreatorByIdActionByField
export def "actions-member-creator get-by" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: (encode-path-segment $id_action), field: (encode-path-segment $field)} | format pattern "/actions/{id_action}/memberCreator/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getActionsOrganizationByIdAction()
#
# GET /actions/{idAction}/organization
# operationId: getActionsOrganizationByIdAction
export def "actions-organization get" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: (encode-path-segment $id_action)} | format pattern "/actions/{id_action}/organization") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getActionsOrganizationByIdActionByField()
#
# GET /actions/{idAction}/organization/{field}
# operationId: getActionsOrganizationByIdActionByField
export def "actions-organization get-by" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: (encode-path-segment $id_action), field: (encode-path-segment $field)} | format pattern "/actions/{id_action}/organization/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateActionsTextByIdAction()
#
# PUT /actions/{idAction}/text
# operationId: updateActionsTextByIdAction
export def "actions-text update" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: (encode-path-segment $id_action)} | format pattern "/actions/{id_action}/text") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getActionsByIdActionByField()
#
# GET /actions/{idAction}/{field}
# operationId: getActionsByIdActionByField
export def "actions get-by" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: (encode-path-segment $id_action), field: (encode-path-segment $field)} | format pattern "/actions/{id_action}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getBatch()
#
# GET /batch
# operationId: getBatch
export def "batch get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --urls: string # list of API v1 GET routes, not including the version prefix
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "urls" $urls "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/batch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addBoards()
#
# POST /boards
# operationId: addBoards
export def "boards create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --closed: string # true or false
  --desc: string # a string with a length from 0 to 16384
  --id-board-source: string # The id of the board to copy into the new board
  --id-organization: string # The id or name of the organization to add the board to.
  --keep-from-source: string # Components of the source board to copy.
  --label-names-blue: string # a string with a length from 0 to 16384
  --label-names-green: string # a string with a length from 0 to 16384
  --label-names-orange: string # a string with a length from 0 to 16384
  --label-names-purple: string # a string with a length from 0 to 16384
  --label-names-red: string # a string with a length from 0 to 16384
  --label-names-yellow: string # a string with a length from 0 to 16384
  --name: string # a string with a length from 1 to 16384
  --power-ups: string # all or a comma-separated list of: calendar, cardAging, recap or voting
  --prefs-background: string # A standard background name, or the id of a custom background
  --prefs-calendar-feed-enabled: string # true or false
  --prefs-card-aging: string # One of: pirate or regular
  --prefs-card-covers: string # true or false
  --prefs-comments: string # One of: disabled, members, observers, org or public
  --prefs-invitations: string # One of: admins or members
  --prefs-permission-level: string # One of: org, private or public
  --prefs-self-join: string # true or false
  --prefs-voting: string # One of: disabled, members, observers, org or public
  --prefs-background: string # a string with a length from 0 to 16384
  --prefs-card-aging: string # One of: pirate or regular
  --prefs-card-covers: string # true or false
  --prefs-comments: string # One of: disabled, members, observers, org or public
  --prefs-invitations: string # One of: admins or members
  --prefs-permission-level: string # One of: org, private or public
  --prefs-self-join: string # true or false
  --prefs-voting: string # One of: disabled, members, observers, org or public
  --subscribed: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boards" $qp)
  let req_body = {"closed": $closed, "desc": $desc, "idBoardSource": $id_board_source, "idOrganization": $id_organization, "keepFromSource": $keep_from_source, "labelNames/blue": $label_names_blue, "labelNames/green": $label_names_green, "labelNames/orange": $label_names_orange, "labelNames/purple": $label_names_purple, "labelNames/red": $label_names_red, "labelNames/yellow": $label_names_yellow, "name": $name, "powerUps": $power_ups, "prefs/background": $prefs_background, "prefs/calendarFeedEnabled": $prefs_calendar_feed_enabled, "prefs/cardAging": $prefs_card_aging, "prefs/cardCovers": $prefs_card_covers, "prefs/comments": $prefs_comments, "prefs/invitations": $prefs_invitations, "prefs/permissionLevel": $prefs_permission_level, "prefs/selfJoin": $prefs_self_join, "prefs/voting": $prefs_voting, "prefs_background": $prefs_background, "prefs_cardAging": $prefs_card_aging, "prefs_cardCovers": $prefs_card_covers, "prefs_comments": $prefs_comments, "prefs_invitations": $prefs_invitations, "prefs_permissionLevel": $prefs_permission_level, "prefs_selfJoin": $prefs_self_join, "prefs_voting": $prefs_voting, "subscribed": $subscribed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getBoardsByIdBoard()
#
# GET /boards/{idBoard}
# operationId: getBoardsByIdBoard
export def "boards get" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string # true or false
  --actions-display: string # true or false
  --actions-format: string # One of: count, list or minimal (default: list)
  --actions-since: string # A date, null or lastView
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --action-member: string # true or false
  --action-member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --action-member-creator: string # true or false
  --action-member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --cards: string # One of: all, closed, none, open or visible (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --card-attachments: string # A boolean value or "cover" for only card cover attachments
  --card-attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --card-checklists: string # One of: all or none (default: none)
  --card-stickers: string # true or false
  --board-stars: string # One of: mine or none (default: none)
  --labels: string # One of: all or none (default: none)
  --label-fields: string # all or a comma-separated list of: color, idBoard, name or uses (default: all)
  --labels-limit: string # a number from 0 to 1000 (default: 50)
  --lists: string # One of: all, closed, none or open (default: none)
  --list-fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --memberships: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: none)
  --memberships-member: string # true or false
  --memberships-member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --members: string # One of: admins, all, none, normal or owners (default: none)
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, initials, fullName, username and confirmed)
  --members-invited: string # One of: admins, all, none, normal or owners (default: none)
  --members-invited-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, initials, fullName and username)
  --checklists: string # One of: all or none (default: none)
  --checklist-fields: string # all or a comma-separated list of: idBoard, idCard, name or pos (default: all)
  --organization: string # true or false
  --organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: name and displayName)
  --organization-memberships: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: none)
  --my-prefs: string # true or false
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, desc, descData, closed, idOrganization, pinned, url, shortUrl, prefs and labelNames)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "actions_entities" $actions_entities "scalar") (serialize-qp "actions_display" $actions_display "scalar") (serialize-qp "actions_format" $actions_format "scalar") (serialize-qp "actions_since" $actions_since "scalar") (serialize-qp "actions_limit" $actions_limit "scalar") (serialize-qp "action_fields" $action_fields "scalar") (serialize-qp "action_member" $action_member "scalar") (serialize-qp "action_member_fields" $action_member_fields "scalar") (serialize-qp "action_memberCreator" $action_member_creator "scalar") (serialize-qp "action_memberCreator_fields" $action_member_creator_fields "scalar") (serialize-qp "cards" $cards "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "card_attachments" $card_attachments "scalar") (serialize-qp "card_attachment_fields" $card_attachment_fields "scalar") (serialize-qp "card_checklists" $card_checklists "scalar") (serialize-qp "card_stickers" $card_stickers "scalar") (serialize-qp "boardStars" $board_stars "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "label_fields" $label_fields "scalar") (serialize-qp "labels_limit" $labels_limit "scalar") (serialize-qp "lists" $lists "scalar") (serialize-qp "list_fields" $list_fields "scalar") (serialize-qp "memberships" $memberships "scalar") (serialize-qp "memberships_member" $memberships_member "scalar") (serialize-qp "memberships_member_fields" $memberships_member_fields "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "membersInvited" $members_invited "scalar") (serialize-qp "membersInvited_fields" $members_invited_fields "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "checklist_fields" $checklist_fields "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "organization_fields" $organization_fields "scalar") (serialize-qp "organization_memberships" $organization_memberships "scalar") (serialize-qp "myPrefs" $my_prefs "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateBoardsByIdBoard()
#
# PUT /boards/{idBoard}
# operationId: updateBoardsByIdBoard
export def "boards update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --closed: string # true or false
  --desc: string # a string with a length from 0 to 16384
  --id-board-source: string # The id of the board to copy into the new board
  --id-organization: string # The id or name of the organization to add the board to.
  --keep-from-source: string # Components of the source board to copy.
  --label-names-blue: string # a string with a length from 0 to 16384
  --label-names-green: string # a string with a length from 0 to 16384
  --label-names-orange: string # a string with a length from 0 to 16384
  --label-names-purple: string # a string with a length from 0 to 16384
  --label-names-red: string # a string with a length from 0 to 16384
  --label-names-yellow: string # a string with a length from 0 to 16384
  --name: string # a string with a length from 1 to 16384
  --power-ups: string # all or a comma-separated list of: calendar, cardAging, recap or voting
  --prefs-background: string # A standard background name, or the id of a custom background
  --prefs-calendar-feed-enabled: string # true or false
  --prefs-card-aging: string # One of: pirate or regular
  --prefs-card-covers: string # true or false
  --prefs-comments: string # One of: disabled, members, observers, org or public
  --prefs-invitations: string # One of: admins or members
  --prefs-permission-level: string # One of: org, private or public
  --prefs-self-join: string # true or false
  --prefs-voting: string # One of: disabled, members, observers, org or public
  --prefs-background: string # a string with a length from 0 to 16384
  --prefs-card-aging: string # One of: pirate or regular
  --prefs-card-covers: string # true or false
  --prefs-comments: string # One of: disabled, members, observers, org or public
  --prefs-invitations: string # One of: admins or members
  --prefs-permission-level: string # One of: org, private or public
  --prefs-self-join: string # true or false
  --prefs-voting: string # One of: disabled, members, observers, org or public
  --subscribed: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}") $qp)
  let req_body = {"closed": $closed, "desc": $desc, "idBoardSource": $id_board_source, "idOrganization": $id_organization, "keepFromSource": $keep_from_source, "labelNames/blue": $label_names_blue, "labelNames/green": $label_names_green, "labelNames/orange": $label_names_orange, "labelNames/purple": $label_names_purple, "labelNames/red": $label_names_red, "labelNames/yellow": $label_names_yellow, "name": $name, "powerUps": $power_ups, "prefs/background": $prefs_background, "prefs/calendarFeedEnabled": $prefs_calendar_feed_enabled, "prefs/cardAging": $prefs_card_aging, "prefs/cardCovers": $prefs_card_covers, "prefs/comments": $prefs_comments, "prefs/invitations": $prefs_invitations, "prefs/permissionLevel": $prefs_permission_level, "prefs/selfJoin": $prefs_self_join, "prefs/voting": $prefs_voting, "prefs_background": $prefs_background, "prefs_cardAging": $prefs_card_aging, "prefs_cardCovers": $prefs_card_covers, "prefs_comments": $prefs_comments, "prefs_invitations": $prefs_invitations, "prefs_permissionLevel": $prefs_permission_level, "prefs_selfJoin": $prefs_self_join, "prefs_voting": $prefs_voting, "subscribed": $subscribed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getBoardsActionsByIdBoard()
#
# GET /boards/{idBoard}/actions
# operationId: getBoardsActionsByIdBoard
export def "boards-actions get" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: string # true or false
  --display: string # true or false
  --filter: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization (default: all)
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --limit: string # a number from 0 to 1000 (default: 50)
  --format: string # One of: count, list or minimal (default: list)
  --since: string # A date, null or lastView
  --before: string # A date, or null
  --page: string # Page * limit must be less than 1000 (default: 0)
  --id-models: string # Only return actions related to these model ids
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --member-creator: string # true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entities" $entities "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "idModels" $id_models "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "memberCreator" $member_creator "scalar") (serialize-qp "memberCreator_fields" $member_creator_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/actions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getBoardsBoardStarsByIdBoard()
#
# GET /boards/{idBoard}/boardStars
# operationId: getBoardsBoardStarsByIdBoard
export def "boards-board-stars get" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: mine or none (default: mine)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/boardStars") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addBoardsCalendarKeyGenerateByIdBoard()
#
# POST /boards/{idBoard}/calendarKey/generate
# operationId: addBoardsCalendarKeyGenerateByIdBoard
export def "boards-calendar-key-generate create" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/calendarKey/generate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getBoardsCardsByIdBoard()
#
# GET /boards/{idBoard}/cards
# operationId: getBoardsCardsByIdBoard
export def "boards-cards get" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --attachments: string # A boolean value or "cover" for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --stickers: string # true or false
  --members: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string # true or false
  --checklists: string # One of: all or none (default: none)
  --limit: string # a number from 1 to 1000
  --since: string # A date, or null
  --before: string # A date, or null
  --filter: string # One of: all, closed, none, open or visible (default: visible)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "attachments" $attachments "scalar") (serialize-qp "attachment_fields" $attachment_fields "scalar") (serialize-qp "stickers" $stickers "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "checkItemStates" $check_item_states "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/cards") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getBoardsCardsByIdBoardByFilter()
#
# GET /boards/{idBoard}/cards/{filter}
# operationId: getBoardsCardsByIdBoardByFilter
export def "boards-cards get-by-by-idBoard-filter" [
  id_board: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board), filter: (encode-path-segment $filter)} | format pattern "/boards/{id_board}/cards/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getBoardsCardsByIdBoardByIdCard()
#
# GET /boards/{idBoard}/cards/{idCard}
# operationId: getBoardsCardsByIdBoardByIdCard
export def "boards-cards get-by-by-idBoard-idCard" [
  id_board: string
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachments: string # A boolean value or "cover" for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string # true or false
  --actions-display: string # true or false
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --action-member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --members: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, initials, fullName and username)
  --check-item-states: string # true or false
  --check-item-state-fields: string # all or a comma-separated list of: idCheckItem or state (default: all)
  --labels: string # true or false
  --checklists: string # One of: all or none (default: none)
  --checklist-fields: string # all or a comma-separated list of: idBoard, idCard, name or pos (default: all)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attachments" $attachments "scalar") (serialize-qp "attachment_fields" $attachment_fields "scalar") (serialize-qp "actions" $actions "scalar") (serialize-qp "actions_entities" $actions_entities "scalar") (serialize-qp "actions_display" $actions_display "scalar") (serialize-qp "actions_limit" $actions_limit "scalar") (serialize-qp "action_fields" $action_fields "scalar") (serialize-qp "action_memberCreator_fields" $action_member_creator_fields "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "checkItemStates" $check_item_states "scalar") (serialize-qp "checkItemState_fields" $check_item_state_fields "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "checklist_fields" $checklist_fields "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board), id_card: (encode-path-segment $id_card)} | format pattern "/boards/{id_board}/cards/{id_card}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getBoardsChecklistsByIdBoard()
#
# GET /boards/{idBoard}/checklists
# operationId: getBoardsChecklistsByIdBoard
export def "boards-checklists get" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cards: string # One of: all, closed, none, open or visible (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --check-items: string # One of: all or none (default: all)
  --check-item-fields: string # all or a comma-separated list of: name, nameData, pos, state or type (default: name, nameData, pos and state)
  --filter: string # One of: all or none (default: all)
  --fields: string # all or a comma-separated list of: idBoard, idCard, name or pos (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cards" $cards "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "checkItems" $check_items "scalar") (serialize-qp "checkItem_fields" $check_item_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/checklists") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addBoardsChecklistsByIdBoard()
#
# POST /boards/{idBoard}/checklists
# operationId: addBoardsChecklistsByIdBoard
export def "boards-checklists create" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --name: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/checklists") $qp)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsClosedByIdBoard()
#
# PUT /boards/{idBoard}/closed
# operationId: updateBoardsClosedByIdBoard
export def "boards-closed update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/closed") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getBoardsDeltasByIdBoard()
#
# GET /boards/{idBoard}/deltas
# operationId: getBoardsDeltasByIdBoard
export def "boards-deltas get" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: string # A valid tag for subscribing
  --ix-last-update: string # a number from -1 to Infinity
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tags" $tags "scalar") (serialize-qp "ixLastUpdate" $ix_last_update "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/deltas") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateBoardsDescByIdBoard()
#
# PUT /boards/{idBoard}/desc
# operationId: updateBoardsDescByIdBoard
export def "boards-desc update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/desc") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# addBoardsEmailKeyGenerateByIdBoard()
#
# POST /boards/{idBoard}/emailKey/generate
# operationId: addBoardsEmailKeyGenerateByIdBoard
export def "boards-email-key-generate create" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/emailKey/generate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateBoardsIdOrganizationByIdBoard()
#
# PUT /boards/{idBoard}/idOrganization
# operationId: updateBoardsIdOrganizationByIdBoard
export def "boards-id-organization update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/idOrganization") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsLabelNamesBlueByIdBoard()
#
# PUT /boards/{idBoard}/labelNames/blue
# operationId: updateBoardsLabelNamesBlueByIdBoard
export def "boards-label-names-blue update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/labelNames/blue") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsLabelNamesGreenByIdBoard()
#
# PUT /boards/{idBoard}/labelNames/green
# operationId: updateBoardsLabelNamesGreenByIdBoard
export def "boards-label-names-green update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/labelNames/green") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsLabelNamesOrangeByIdBoard()
#
# PUT /boards/{idBoard}/labelNames/orange
# operationId: updateBoardsLabelNamesOrangeByIdBoard
export def "boards-label-names-orange update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/labelNames/orange") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsLabelNamesPurpleByIdBoard()
#
# PUT /boards/{idBoard}/labelNames/purple
# operationId: updateBoardsLabelNamesPurpleByIdBoard
export def "boards-label-names-purple update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/labelNames/purple") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsLabelNamesRedByIdBoard()
#
# PUT /boards/{idBoard}/labelNames/red
# operationId: updateBoardsLabelNamesRedByIdBoard
export def "boards-label-names-red update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/labelNames/red") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsLabelNamesYellowByIdBoard()
#
# PUT /boards/{idBoard}/labelNames/yellow
# operationId: updateBoardsLabelNamesYellowByIdBoard
export def "boards-label-names-yellow update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/labelNames/yellow") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getBoardsLabelsByIdBoard()
#
# GET /boards/{idBoard}/labels
# operationId: getBoardsLabelsByIdBoard
export def "boards-labels get" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: color, idBoard, name or uses (default: all)
  --limit: string # a number from 0 to 1000 (default: 50)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/labels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addBoardsLabelsByIdBoard()
#
# POST /boards/{idBoard}/labels
# operationId: addBoardsLabelsByIdBoard
export def "boards-labels create" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --color: string # A valid label color or null
  --name: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/labels") $qp)
  let req_body = {"color": $color, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getBoardsLabelsByIdBoardByIdLabel()
#
# GET /boards/{idBoard}/labels/{idLabel}
# operationId: getBoardsLabelsByIdBoardByIdLabel
export def "boards-labels get-by" [
  id_board: string
  id_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: color, idBoard, name or uses (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board), id_label: (encode-path-segment $id_label)} | format pattern "/boards/{id_board}/labels/{id_label}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getBoardsListsByIdBoard()
#
# GET /boards/{idBoard}/lists
# operationId: getBoardsListsByIdBoard
export def "boards-lists get" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cards: string # One of: all, closed, none, open or visible (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --filter: string # One of: all, closed, none or open (default: open)
  --fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cards" $cards "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/lists") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addBoardsListsByIdBoard()
#
# POST /boards/{idBoard}/lists
# operationId: addBoardsListsByIdBoard
export def "boards-lists create" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --name: string # a string with a length from 1 to 16384
  --pos: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/lists") $qp)
  let req_body = {"name": $name, "pos": $pos} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getBoardsListsByIdBoardByFilter()
#
# GET /boards/{idBoard}/lists/{filter}
# operationId: getBoardsListsByIdBoardByFilter
export def "boards-lists get-by" [
  id_board: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board), filter: (encode-path-segment $filter)} | format pattern "/boards/{id_board}/lists/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addBoardsMarkAsViewedByIdBoard()
#
# POST /boards/{idBoard}/markAsViewed
# operationId: addBoardsMarkAsViewedByIdBoard
export def "boards-mark-as-viewed create" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/markAsViewed") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getBoardsMembersByIdBoard()
#
# GET /boards/{idBoard}/members
# operationId: getBoardsMembersByIdBoard
export def "boards-members get" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: admins, all, none, normal or owners (default: all)
  --fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --activity: string # true or false ; works for premium organizations only.
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "activity" $activity "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateBoardsMembersByIdBoard()
#
# PUT /boards/{idBoard}/members
# operationId: updateBoardsMembersByIdBoard
export def "boards-members update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --email: string # An email address
  --full-name: string # A string with a length of at least 1. Cannot begin or end with a space.
  --type: string # One of: admin, normal or observer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/members") $qp)
  let req_body = {"email": $email, "fullName": $full_name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getBoardsMembersByIdBoardByFilter()
#
# GET /boards/{idBoard}/members/{filter}
# operationId: getBoardsMembersByIdBoardByFilter
export def "boards-members get-by" [
  id_board: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board), filter: (encode-path-segment $filter)} | format pattern "/boards/{id_board}/members/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# deleteBoardsMembersByIdBoardByIdMember()
#
# DELETE /boards/{idBoard}/members/{idMember}
# operationId: deleteBoardsMembersByIdBoardByIdMember
export def "boards-members delete-by" [
  id_board: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board), id_member: (encode-path-segment $id_member)} | format pattern "/boards/{id_board}/members/{id_member}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateBoardsMembersByIdBoardByIdMember()
#
# PUT /boards/{idBoard}/members/{idMember}
# operationId: updateBoardsMembersByIdBoardByIdMember
export def "boards-members update-by" [
  id_board: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --email: string # An email address
  --full-name: string # A string with a length of at least 1. Cannot begin or end with a space.
  --type: string # One of: admin, normal or observer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board), id_member: (encode-path-segment $id_member)} | format pattern "/boards/{id_board}/members/{id_member}") $qp)
  let req_body = {"email": $email, "fullName": $full_name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getBoardsMembersCardsByIdBoardByIdMember()
#
# GET /boards/{idBoard}/members/{idMember}/cards
# operationId: getBoardsMembersCardsByIdBoardByIdMember
export def "boards-members-cards get-by" [
  id_board: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --attachments: string # A boolean value or "cover" for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --members: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string # true or false
  --checklists: string # One of: all or none (default: none)
  --board: string # true or false
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, desc, closed, idOrganization, pinned, url and prefs)
  --list: string # true or false
  --list-fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --filter: string # One of: all, closed, none, open or visible (default: visible)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "attachments" $attachments "scalar") (serialize-qp "attachment_fields" $attachment_fields "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "checkItemStates" $check_item_states "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "board" $board "scalar") (serialize-qp "board_fields" $board_fields "scalar") (serialize-qp "list" $list "scalar") (serialize-qp "list_fields" $list_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board), id_member: (encode-path-segment $id_member)} | format pattern "/boards/{id_board}/members/{id_member}/cards") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getBoardsMembersInvitedByIdBoard()
#
# GET /boards/{idBoard}/membersInvited
# operationId: getBoardsMembersInvitedByIdBoard
export def "boards-members-invited get" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/membersInvited") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getBoardsMembersInvitedByIdBoardByField()
#
# GET /boards/{idBoard}/membersInvited/{field}
# operationId: getBoardsMembersInvitedByIdBoardByField
export def "boards-members-invited get-by" [
  id_board: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board), field: (encode-path-segment $field)} | format pattern "/boards/{id_board}/membersInvited/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getBoardsMembershipsByIdBoard()
#
# GET /boards/{idBoard}/memberships
# operationId: getBoardsMembershipsByIdBoard
export def "boards-memberships get" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: all)
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/memberships") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getBoardsMembershipsByIdBoardByIdMembership()
#
# GET /boards/{idBoard}/memberships/{idMembership}
# operationId: getBoardsMembershipsByIdBoardByIdMembership
export def "boards-memberships get-by" [
  id_board: string
  id_membership: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board), id_membership: (encode-path-segment $id_membership)} | format pattern "/boards/{id_board}/memberships/{id_membership}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateBoardsMembershipsByIdBoardByIdMembership()
#
# PUT /boards/{idBoard}/memberships/{idMembership}
# operationId: updateBoardsMembershipsByIdBoardByIdMembership
export def "boards-memberships update-by" [
  id_board: string
  id_membership: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username
  --type: string # One of: admin, normal or observer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board), id_membership: (encode-path-segment $id_membership)} | format pattern "/boards/{id_board}/memberships/{id_membership}") $qp)
  let req_body = {"member_fields": $member_fields, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getBoardsMyPrefsByIdBoard()
#
# GET /boards/{idBoard}/myPrefs
# operationId: getBoardsMyPrefsByIdBoard
export def "boards-my-prefs get" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/myPrefs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateBoardsMyPrefsEmailPositionByIdBoard()
#
# PUT /boards/{idBoard}/myPrefs/emailPosition
# operationId: updateBoardsMyPrefsEmailPositionByIdBoard
export def "boards-my-prefs-email-position update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # One of: bottom or top
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/myPrefs/emailPosition") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsMyPrefsIdEmailListByIdBoard()
#
# PUT /boards/{idBoard}/myPrefs/idEmailList
# operationId: updateBoardsMyPrefsIdEmailListByIdBoard
export def "boards-my-prefs-id-email-list update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # An id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/myPrefs/idEmailList") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsMyPrefsShowListGuideByIdBoard()
#
# PUT /boards/{idBoard}/myPrefs/showListGuide
# operationId: updateBoardsMyPrefsShowListGuideByIdBoard
export def "boards-my-prefs-show-list-guide update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/myPrefs/showListGuide") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsMyPrefsShowSidebarByIdBoard()
#
# PUT /boards/{idBoard}/myPrefs/showSidebar
# operationId: updateBoardsMyPrefsShowSidebarByIdBoard
export def "boards-my-prefs-show-sidebar update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/myPrefs/showSidebar") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsMyPrefsShowSidebarActivityByIdBoard()
#
# PUT /boards/{idBoard}/myPrefs/showSidebarActivity
# operationId: updateBoardsMyPrefsShowSidebarActivityByIdBoard
export def "boards-my-prefs-show-sidebar-activity update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/myPrefs/showSidebarActivity") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsMyPrefsShowSidebarBoardActionsByIdBoard()
#
# PUT /boards/{idBoard}/myPrefs/showSidebarBoardActions
# operationId: updateBoardsMyPrefsShowSidebarBoardActionsByIdBoard
export def "boards-my-prefs-show-sidebar-board-actions update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/myPrefs/showSidebarBoardActions") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsMyPrefsShowSidebarMembersByIdBoard()
#
# PUT /boards/{idBoard}/myPrefs/showSidebarMembers
# operationId: updateBoardsMyPrefsShowSidebarMembersByIdBoard
export def "boards-my-prefs-show-sidebar-members update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/myPrefs/showSidebarMembers") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsNameByIdBoard()
#
# PUT /boards/{idBoard}/name
# operationId: updateBoardsNameByIdBoard
export def "boards-name update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/name") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getBoardsOrganizationByIdBoard()
#
# GET /boards/{idBoard}/organization
# operationId: getBoardsOrganizationByIdBoard
export def "boards-organization get" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/organization") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getBoardsOrganizationByIdBoardByField()
#
# GET /boards/{idBoard}/organization/{field}
# operationId: getBoardsOrganizationByIdBoardByField
export def "boards-organization get-by" [
  id_board: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board), field: (encode-path-segment $field)} | format pattern "/boards/{id_board}/organization/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addBoardsPowerUpsByIdBoard()
#
# POST /boards/{idBoard}/powerUps
# operationId: addBoardsPowerUpsByIdBoard
export def "boards-power-ups create" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # One of: calendar, cardAging, recap or voting
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/powerUps") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteBoardsPowerUpsByIdBoardByPowerUp()
#
# DELETE /boards/{idBoard}/powerUps/{powerUp}
# operationId: deleteBoardsPowerUpsByIdBoardByPowerUp
export def "boards-power-ups delete-by" [
  id_board: string
  power_up: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board), power_up: (encode-path-segment $power_up)} | format pattern "/boards/{id_board}/powerUps/{power_up}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateBoardsPrefsBackgroundByIdBoard()
#
# PUT /boards/{idBoard}/prefs/background
# operationId: updateBoardsPrefsBackgroundByIdBoard
export def "boards-prefs-background update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # A standard background name, or the id of a custom background
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/prefs/background") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsPrefsCalendarFeedEnabledByIdBoard()
#
# PUT /boards/{idBoard}/prefs/calendarFeedEnabled
# operationId: updateBoardsPrefsCalendarFeedEnabledByIdBoard
export def "boards-prefs-calendar-feed-enabled update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/prefs/calendarFeedEnabled") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsPrefsCardAgingByIdBoard()
#
# PUT /boards/{idBoard}/prefs/cardAging
# operationId: updateBoardsPrefsCardAgingByIdBoard
export def "boards-prefs-card-aging update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # One of: pirate or regular
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/prefs/cardAging") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsPrefsCardCoversByIdBoard()
#
# PUT /boards/{idBoard}/prefs/cardCovers
# operationId: updateBoardsPrefsCardCoversByIdBoard
export def "boards-prefs-card-covers update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/prefs/cardCovers") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsPrefsCommentsByIdBoard()
#
# PUT /boards/{idBoard}/prefs/comments
# operationId: updateBoardsPrefsCommentsByIdBoard
export def "boards-prefs-comments update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # One of: disabled, members, observers, org or public
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/prefs/comments") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsPrefsInvitationsByIdBoard()
#
# PUT /boards/{idBoard}/prefs/invitations
# operationId: updateBoardsPrefsInvitationsByIdBoard
export def "boards-prefs-invitations update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # One of: admins or members
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/prefs/invitations") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsPrefsPermissionLevelByIdBoard()
#
# PUT /boards/{idBoard}/prefs/permissionLevel
# operationId: updateBoardsPrefsPermissionLevelByIdBoard
export def "boards-prefs-permission-level update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # One of: private or public
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/prefs/permissionLevel") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsPrefsSelfJoinByIdBoard()
#
# PUT /boards/{idBoard}/prefs/selfJoin
# operationId: updateBoardsPrefsSelfJoinByIdBoard
export def "boards-prefs-self-join update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/prefs/selfJoin") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsPrefsVotingByIdBoard()
#
# PUT /boards/{idBoard}/prefs/voting
# operationId: updateBoardsPrefsVotingByIdBoard
export def "boards-prefs-voting update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # One of: disabled, members, observers, org or public
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/prefs/voting") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateBoardsSubscribedByIdBoard()
#
# PUT /boards/{idBoard}/subscribed
# operationId: updateBoardsSubscribedByIdBoard
export def "boards-subscribed update" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board)} | format pattern "/boards/{id_board}/subscribed") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getBoardsByIdBoardByField()
#
# GET /boards/{idBoard}/{field}
# operationId: getBoardsByIdBoardByField
export def "boards get-by" [
  id_board: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: (encode-path-segment $id_board), field: (encode-path-segment $field)} | format pattern "/boards/{id_board}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addCards()
#
# POST /cards
# operationId: addCards
export def "cards create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --closed: string # true or false
  --desc: string # a string with a length from 0 to 16384
  --due: string # A date, or null
  --file-source: string # A file
  --id-attachment-cover: string # Id of the image attachment of this card to use as its cover, or null for no cover
  --id-board: string # id of the board the card should be moved to
  --id-card-source: string # The id of the card to copy into a new card.
  --id-labels: string # A comma-separated list of objectIds, 24-character hex strings
  --id-list: string # id of the list that the card should be added to
  --id-members: string # A comma-separated list of objectIds, 24-character hex strings
  --keep-from-source: string # Properties of the card to copy over from the source.
  --labels: string # all or a comma-separated list of: blue, green, orange, purple, red or yellow
  --name: string # The name of the new card. It isn't required if the name is being copied from provided by a URL, file or card that is being copied.
  --pos: string # A position. top , bottom , or a positive number.
  --subscribed: string # true or false
  --url-source: string # A URL starting with http:// or https:// or null
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cards" $qp)
  let req_body = {"closed": $closed, "desc": $desc, "due": $due, "fileSource": $file_source, "idAttachmentCover": $id_attachment_cover, "idBoard": $id_board, "idCardSource": $id_card_source, "idLabels": $id_labels, "idList": $id_list, "idMembers": $id_members, "keepFromSource": $keep_from_source, "labels": $labels, "name": $name, "pos": $pos, "subscribed": $subscribed, "urlSource": $url_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteCardsByIdCard()
#
# DELETE /cards/{idCard}
# operationId: deleteCardsByIdCard
export def "cards delete" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getCardsByIdCard()
#
# GET /cards/{idCard}
# operationId: getCardsByIdCard
export def "cards get" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string # true or false
  --actions-display: string # true or false
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --action-member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --attachments: string # A boolean value or "cover" for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --members: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --members-voted: string # true or false
  --member-voted-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string # true or false
  --check-item-state-fields: string # all or a comma-separated list of: idCheckItem or state (default: all)
  --checklists: string # One of: all or none (default: none)
  --checklist-fields: string # all or a comma-separated list of: idBoard, idCard, name or pos (default: all)
  --board: string # true or false
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, desc, descData, closed, idOrganization, pinned, url and prefs)
  --list: string # true or false
  --list-fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --stickers: string # true or false
  --sticker-fields: string # all or a comma-separated list of: image, imageScaled, imageUrl, left, rotate, top or zIndex (default: all)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idBoard, idChecklists, idLabels, idList, idMembers, idShort, idAttachmentCover, manualCoverAttachment, labels, name, pos, shortUrl and url)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "actions_entities" $actions_entities "scalar") (serialize-qp "actions_display" $actions_display "scalar") (serialize-qp "actions_limit" $actions_limit "scalar") (serialize-qp "action_fields" $action_fields "scalar") (serialize-qp "action_memberCreator_fields" $action_member_creator_fields "scalar") (serialize-qp "attachments" $attachments "scalar") (serialize-qp "attachment_fields" $attachment_fields "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "membersVoted" $members_voted "scalar") (serialize-qp "memberVoted_fields" $member_voted_fields "scalar") (serialize-qp "checkItemStates" $check_item_states "scalar") (serialize-qp "checkItemState_fields" $check_item_state_fields "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "checklist_fields" $checklist_fields "scalar") (serialize-qp "board" $board "scalar") (serialize-qp "board_fields" $board_fields "scalar") (serialize-qp "list" $list "scalar") (serialize-qp "list_fields" $list_fields "scalar") (serialize-qp "stickers" $stickers "scalar") (serialize-qp "sticker_fields" $sticker_fields "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateCardsByIdCard()
#
# PUT /cards/{idCard}
# operationId: updateCardsByIdCard
export def "cards update" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --closed: string # true or false
  --desc: string # a string with a length from 0 to 16384
  --due: string # A date, or null
  --file-source: string # A file
  --id-attachment-cover: string # Id of the image attachment of this card to use as its cover, or null for no cover
  --id-board: string # id of the board the card should be moved to
  --id-card-source: string # The id of the card to copy into a new card.
  --id-labels: string # A comma-separated list of objectIds, 24-character hex strings
  --id-list: string # id of the list that the card should be added to
  --id-members: string # A comma-separated list of objectIds, 24-character hex strings
  --keep-from-source: string # Properties of the card to copy over from the source.
  --labels: string # all or a comma-separated list of: blue, green, orange, purple, red or yellow
  --name: string # The name of the new card. It isn't required if the name is being copied from provided by a URL, file or card that is being copied.
  --pos: string # A position. top , bottom , or a positive number.
  --subscribed: string # true or false
  --url-source: string # A URL starting with http:// or https:// or null
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}") $qp)
  let req_body = {"closed": $closed, "desc": $desc, "due": $due, "fileSource": $file_source, "idAttachmentCover": $id_attachment_cover, "idBoard": $id_board, "idCardSource": $id_card_source, "idLabels": $id_labels, "idList": $id_list, "idMembers": $id_members, "keepFromSource": $keep_from_source, "labels": $labels, "name": $name, "pos": $pos, "subscribed": $subscribed, "urlSource": $url_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getCardsActionsByIdCard()
#
# GET /cards/{idCard}/actions
# operationId: getCardsActionsByIdCard
export def "cards-actions get" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: string # true or false
  --display: string # true or false
  --filter: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization (default: commentCard and updateCard:idList)
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --limit: string # a number from 0 to 1000 (default: 50)
  --format: string # One of: count, list or minimal (default: list)
  --since: string # A date, null or lastView
  --before: string # A date, or null
  --page: string # Page * limit must be less than 1000 (default: 0)
  --id-models: string # Only return actions related to these model ids
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --member-creator: string # true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entities" $entities "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "idModels" $id_models "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "memberCreator" $member_creator "scalar") (serialize-qp "memberCreator_fields" $member_creator_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/actions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addCardsActionsCommentsByIdCard()
#
# POST /cards/{idCard}/actions/comments
# operationId: addCardsActionsCommentsByIdCard
export def "cards-actions-comments create" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --text: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/actions/comments") $qp)
  let req_body = {"text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteCardsActionsCommentsByIdCardByIdAction()
#
# DELETE /cards/{idCard}/actions/{idAction}/comments
# operationId: deleteCardsActionsCommentsByIdCardByIdAction
export def "cards-actions-comments delete-by" [
  id_card: string
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), id_action: (encode-path-segment $id_action)} | format pattern "/cards/{id_card}/actions/{id_action}/comments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateCardsActionsCommentsByIdCardByIdAction()
#
# PUT /cards/{idCard}/actions/{idAction}/comments
# operationId: updateCardsActionsCommentsByIdCardByIdAction
export def "cards-actions-comments update-by" [
  id_card: string
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --text: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), id_action: (encode-path-segment $id_action)} | format pattern "/cards/{id_card}/actions/{id_action}/comments") $qp)
  let req_body = {"text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getCardsAttachmentsByIdCard()
#
# GET /cards/{idCard}/attachments
# operationId: getCardsAttachmentsByIdCard
export def "cards-attachments get" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --filter: string # A boolean value or "cover" for only card cover attachments
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/attachments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addCardsAttachmentsByIdCard()
#
# POST /cards/{idCard}/attachments
# operationId: addCardsAttachmentsByIdCard
export def "cards-attachments create" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --file: string # A file
  --mime-type: string # a string with a length from 0 to 256
  --name: string # a string with a length from 0 to 256
  --url: string # A URL starting with http:// or https:// or null
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/attachments") $qp)
  let req_body = {"file": $file, "mimeType": $mime_type, "name": $name, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteCardsAttachmentsByIdCardByIdAttachment()
#
# DELETE /cards/{idCard}/attachments/{idAttachment}
# operationId: deleteCardsAttachmentsByIdCardByIdAttachment
export def "cards-attachments delete-by" [
  id_card: string
  id_attachment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), id_attachment: (encode-path-segment $id_attachment)} | format pattern "/cards/{id_card}/attachments/{id_attachment}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getCardsAttachmentsByIdCardByIdAttachment()
#
# GET /cards/{idCard}/attachments/{idAttachment}
# operationId: getCardsAttachmentsByIdCardByIdAttachment
export def "cards-attachments get-by" [
  id_card: string
  id_attachment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), id_attachment: (encode-path-segment $id_attachment)} | format pattern "/cards/{id_card}/attachments/{id_attachment}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getCardsBoardByIdCard()
#
# GET /cards/{idCard}/board
# operationId: getCardsBoardByIdCard
export def "cards-board get" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/board") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getCardsBoardByIdCardByField()
#
# GET /cards/{idCard}/board/{field}
# operationId: getCardsBoardByIdCardByField
export def "cards-board get-by" [
  id_card: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), field: (encode-path-segment $field)} | format pattern "/cards/{id_card}/board/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getCardsCheckItemStatesByIdCard()
#
# GET /cards/{idCard}/checkItemStates
# operationId: getCardsCheckItemStatesByIdCard
export def "cards-check-item-states get" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: idCheckItem or state (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/checkItemStates") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateCardsChecklistCheckItemByIdCardByIdChecklistCurrentByIdCheckItem()
#
# PUT /cards/{idCard}/checklist/{idChecklistCurrent}/checkItem/{idCheckItem}
# operationId: updateCardsChecklistCheckItemByIdCardByIdChecklistCurrentByIdCheckItem
export def "cards-checklist-check-item update-by-by-get" [
  id_card: string
  id_checklist_current: string
  id_check_item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --id-checklist: string # An id, or null
  --name: string # a string with a length from 1 to 16384
  --pos: string # A position. top , bottom , or a positive number.
  --state: string # One of: complete, false, incomplete or true
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), id_checklist_current: (encode-path-segment $id_checklist_current), id_check_item: (encode-path-segment $id_check_item)} | format pattern "/cards/{id_card}/checklist/{id_checklist_current}/checkItem/{id_check_item}") $qp)
  let req_body = {"idChecklist": $id_checklist, "name": $name, "pos": $pos, "state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# addCardsChecklistCheckItemByIdCardByIdChecklist()
#
# POST /cards/{idCard}/checklist/{idChecklist}/checkItem
# operationId: addCardsChecklistCheckItemByIdCardByIdChecklist
export def "cards-checklist-check-item create-by" [
  id_card: string
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --name: string # a string with a length from 1 to 16384
  --pos: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), id_checklist: (encode-path-segment $id_checklist)} | format pattern "/cards/{id_card}/checklist/{id_checklist}/checkItem") $qp)
  let req_body = {"name": $name, "pos": $pos} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteCardsChecklistCheckItemByIdCardByIdChecklistByIdCheckItem()
#
# DELETE /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}
# operationId: deleteCardsChecklistCheckItemByIdCardByIdChecklistByIdCheckItem
export def "cards-checklist-check-item delete-by-by" [
  id_card: string
  id_checklist: string
  id_check_item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), id_checklist: (encode-path-segment $id_checklist), id_check_item: (encode-path-segment $id_check_item)} | format pattern "/cards/{id_card}/checklist/{id_checklist}/checkItem/{id_check_item}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addCardsChecklistCheckItemConvertToCardByIdCardByIdChecklistByIdCheckItem()
#
# POST /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}/convertToCard
# operationId: addCardsChecklistCheckItemConvertToCardByIdCardByIdChecklistByIdCheckItem
export def "cards-checklist-check-item-convert-to-card create-by-by" [
  id_card: string
  id_checklist: string
  id_check_item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), id_checklist: (encode-path-segment $id_checklist), id_check_item: (encode-path-segment $id_check_item)} | format pattern "/cards/{id_card}/checklist/{id_checklist}/checkItem/{id_check_item}/convertToCard") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateCardsChecklistCheckItemNameByIdCardByIdChecklistByIdCheckItem()
#
# PUT /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}/name
# operationId: updateCardsChecklistCheckItemNameByIdCardByIdChecklistByIdCheckItem
export def "cards-checklist-check-item-name update-by-by" [
  id_card: string
  id_checklist: string
  id_check_item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), id_checklist: (encode-path-segment $id_checklist), id_check_item: (encode-path-segment $id_check_item)} | format pattern "/cards/{id_card}/checklist/{id_checklist}/checkItem/{id_check_item}/name") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateCardsChecklistCheckItemPosByIdCardByIdChecklistByIdCheckItem()
#
# PUT /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}/pos
# operationId: updateCardsChecklistCheckItemPosByIdCardByIdChecklistByIdCheckItem
export def "cards-checklist-check-item-pos update-by-by" [
  id_card: string
  id_checklist: string
  id_check_item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), id_checklist: (encode-path-segment $id_checklist), id_check_item: (encode-path-segment $id_check_item)} | format pattern "/cards/{id_card}/checklist/{id_checklist}/checkItem/{id_check_item}/pos") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateCardsChecklistCheckItemStateByIdCardByIdChecklistByIdCheckItem()
#
# PUT /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}/state
# operationId: updateCardsChecklistCheckItemStateByIdCardByIdChecklistByIdCheckItem
export def "cards-checklist-check-item-state update-by-by" [
  id_card: string
  id_checklist: string
  id_check_item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # One of: complete, false, incomplete or true
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), id_checklist: (encode-path-segment $id_checklist), id_check_item: (encode-path-segment $id_check_item)} | format pattern "/cards/{id_card}/checklist/{id_checklist}/checkItem/{id_check_item}/state") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getCardsChecklistsByIdCard()
#
# GET /cards/{idCard}/checklists
# operationId: getCardsChecklistsByIdCard
export def "cards-checklists get" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cards: string # One of: all, closed, none, open or visible (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --check-items: string # One of: all or none (default: all)
  --check-item-fields: string # all or a comma-separated list of: name, nameData, pos, state or type (default: name, nameData, pos and state)
  --filter: string # One of: all or none (default: all)
  --fields: string # all or a comma-separated list of: idBoard, idCard, name or pos (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cards" $cards "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "checkItems" $check_items "scalar") (serialize-qp "checkItem_fields" $check_item_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/checklists") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addCardsChecklistsByIdCard()
#
# POST /cards/{idCard}/checklists
# operationId: addCardsChecklistsByIdCard
export def "cards-checklists create" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --id-checklist-source: string # The id of the source checklist to copy into a new checklist.
  --name: string # a string with a length from 0 to 16384
  --value: string # The id of the checklist to add to the card, or null to create a new one.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/checklists") $qp)
  let req_body = {"idChecklistSource": $id_checklist_source, "name": $name, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteCardsChecklistsByIdCardByIdChecklist()
#
# DELETE /cards/{idCard}/checklists/{idChecklist}
# operationId: deleteCardsChecklistsByIdCardByIdChecklist
export def "cards-checklists delete-by" [
  id_card: string
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), id_checklist: (encode-path-segment $id_checklist)} | format pattern "/cards/{id_card}/checklists/{id_checklist}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateCardsClosedByIdCard()
#
# PUT /cards/{idCard}/closed
# operationId: updateCardsClosedByIdCard
export def "cards-closed update" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/closed") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateCardsDescByIdCard()
#
# PUT /cards/{idCard}/desc
# operationId: updateCardsDescByIdCard
export def "cards-desc update" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/desc") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateCardsDueByIdCard()
#
# PUT /cards/{idCard}/due
# operationId: updateCardsDueByIdCard
export def "cards-due update" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # A date, or null
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/due") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateCardsIdAttachmentCoverByIdCard()
#
# PUT /cards/{idCard}/idAttachmentCover
# operationId: updateCardsIdAttachmentCoverByIdCard
export def "cards-id-attachment-cover update" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # Id of the image attachment of this card to use as its cover, or null for no cover
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/idAttachmentCover") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateCardsIdBoardByIdCard()
#
# PUT /cards/{idCard}/idBoard
# operationId: updateCardsIdBoardByIdCard
export def "cards-id-board update" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --id-list: string # id of the list that the card should be moved to on the new board
  --value: string # id of the board the card should be moved to
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/idBoard") $qp)
  let req_body = {"idList": $id_list, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# addCardsIdLabelsByIdCard()
#
# POST /cards/{idCard}/idLabels
# operationId: addCardsIdLabelsByIdCard
export def "cards-id-labels create" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # The id of the label to add
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/idLabels") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteCardsIdLabelsByIdCardByIdLabel()
#
# DELETE /cards/{idCard}/idLabels/{idLabel}
# operationId: deleteCardsIdLabelsByIdCardByIdLabel
export def "cards-id-labels delete-by" [
  id_card: string
  id_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), id_label: (encode-path-segment $id_label)} | format pattern "/cards/{id_card}/idLabels/{id_label}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateCardsIdListByIdCard()
#
# PUT /cards/{idCard}/idList
# operationId: updateCardsIdListByIdCard
export def "cards-id-list update" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # id of the list the card should be moved to
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/idList") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# addCardsIdMembersByIdCard()
#
# POST /cards/{idCard}/idMembers
# operationId: addCardsIdMembersByIdCard
export def "cards-id-members create" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # The id of the member to add to the card
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/idMembers") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateCardsIdMembersByIdCard()
#
# PUT /cards/{idCard}/idMembers
# operationId: updateCardsIdMembersByIdCard
export def "cards-id-members update" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # The id of the member to add to the card
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/idMembers") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteCardsIdMembersByIdCardByIdMember()
#
# DELETE /cards/{idCard}/idMembers/{idMember}
# operationId: deleteCardsIdMembersByIdCardByIdMember
export def "cards-id-members delete-by" [
  id_card: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), id_member: (encode-path-segment $id_member)} | format pattern "/cards/{id_card}/idMembers/{id_member}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addCardsLabelsByIdCard()
#
# POST /cards/{idCard}/labels
# operationId: addCardsLabelsByIdCard
export def "cards-labels create" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --color: string # A valid label color or null
  --name: string # a string with a length from 0 to 16384
  --value: string # all or a comma-separated list of: blue, green, orange, purple, red or yellow
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/labels") $qp)
  let req_body = {"color": $color, "name": $name, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateCardsLabelsByIdCard()
#
# PUT /cards/{idCard}/labels
# operationId: updateCardsLabelsByIdCard
export def "cards-labels update" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --color: string # A valid label color or null
  --name: string # a string with a length from 0 to 16384
  --value: string # all or a comma-separated list of: blue, green, orange, purple, red or yellow
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/labels") $qp)
  let req_body = {"color": $color, "name": $name, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteCardsLabelsByIdCardByColor()
#
# DELETE /cards/{idCard}/labels/{color}
# operationId: deleteCardsLabelsByIdCardByColor
export def "cards-labels delete-by" [
  id_card: string
  color: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), color: (encode-path-segment $color)} | format pattern "/cards/{id_card}/labels/{color}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getCardsListByIdCard()
#
# GET /cards/{idCard}/list
# operationId: getCardsListByIdCard
export def "cards-list get" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/list") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getCardsListByIdCardByField()
#
# GET /cards/{idCard}/list/{field}
# operationId: getCardsListByIdCardByField
export def "cards-list get-by" [
  id_card: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), field: (encode-path-segment $field)} | format pattern "/cards/{id_card}/list/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addCardsMarkAssociatedNotificationsReadByIdCard()
#
# POST /cards/{idCard}/markAssociatedNotificationsRead
# operationId: addCardsMarkAssociatedNotificationsReadByIdCard
export def "cards-mark-associated-notifications-read create" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/markAssociatedNotificationsRead") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getCardsMembersByIdCard()
#
# GET /cards/{idCard}/members
# operationId: getCardsMembersByIdCard
export def "cards-members get" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getCardsMembersVotedByIdCard()
#
# GET /cards/{idCard}/membersVoted
# operationId: getCardsMembersVotedByIdCard
export def "cards-members-voted get" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/membersVoted") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addCardsMembersVotedByIdCard()
#
# POST /cards/{idCard}/membersVoted
# operationId: addCardsMembersVotedByIdCard
export def "cards-members-voted create" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # The id of the member to vote 'yes' on the card
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/membersVoted") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteCardsMembersVotedByIdCardByIdMember()
#
# DELETE /cards/{idCard}/membersVoted/{idMember}
# operationId: deleteCardsMembersVotedByIdCardByIdMember
export def "cards-members-voted delete-by" [
  id_card: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), id_member: (encode-path-segment $id_member)} | format pattern "/cards/{id_card}/membersVoted/{id_member}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateCardsNameByIdCard()
#
# PUT /cards/{idCard}/name
# operationId: updateCardsNameByIdCard
export def "cards-name update" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/name") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateCardsPosByIdCard()
#
# PUT /cards/{idCard}/pos
# operationId: updateCardsPosByIdCard
export def "cards-pos update" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/pos") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getCardsStickersByIdCard()
#
# GET /cards/{idCard}/stickers
# operationId: getCardsStickersByIdCard
export def "cards-stickers get" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: image, imageScaled, imageUrl, left, rotate, top or zIndex (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/stickers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addCardsStickersByIdCard()
#
# POST /cards/{idCard}/stickers
# operationId: addCardsStickersByIdCard
export def "cards-stickers create" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --image: string # a string with a length from 0 to 16384
  --left: string # undefined
  --rotate: string # undefined
  --top: string # undefined
  --z-index: string # Valid Z values for stickers, must be an integer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/stickers") $qp)
  let req_body = {"image": $image, "left": $left, "rotate": $rotate, "top": $top, "zIndex": $z_index} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteCardsStickersByIdCardByIdSticker()
#
# DELETE /cards/{idCard}/stickers/{idSticker}
# operationId: deleteCardsStickersByIdCardByIdSticker
export def "cards-stickers delete-by" [
  id_card: string
  id_sticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), id_sticker: (encode-path-segment $id_sticker)} | format pattern "/cards/{id_card}/stickers/{id_sticker}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getCardsStickersByIdCardByIdSticker()
#
# GET /cards/{idCard}/stickers/{idSticker}
# operationId: getCardsStickersByIdCardByIdSticker
export def "cards-stickers get-by" [
  id_card: string
  id_sticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: image, imageScaled, imageUrl, left, rotate, top or zIndex (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), id_sticker: (encode-path-segment $id_sticker)} | format pattern "/cards/{id_card}/stickers/{id_sticker}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateCardsStickersByIdCardByIdSticker()
#
# PUT /cards/{idCard}/stickers/{idSticker}
# operationId: updateCardsStickersByIdCardByIdSticker
export def "cards-stickers update-by" [
  id_card: string
  id_sticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --image: string # a string with a length from 0 to 16384
  --left: string # undefined
  --rotate: string # undefined
  --top: string # undefined
  --z-index: string # Valid Z values for stickers, must be an integer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), id_sticker: (encode-path-segment $id_sticker)} | format pattern "/cards/{id_card}/stickers/{id_sticker}") $qp)
  let req_body = {"image": $image, "left": $left, "rotate": $rotate, "top": $top, "zIndex": $z_index} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateCardsSubscribedByIdCard()
#
# PUT /cards/{idCard}/subscribed
# operationId: updateCardsSubscribedByIdCard
export def "cards-subscribed update" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card)} | format pattern "/cards/{id_card}/subscribed") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getCardsByIdCardByField()
#
# GET /cards/{idCard}/{field}
# operationId: getCardsByIdCardByField
export def "cards get-by" [
  id_card: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: (encode-path-segment $id_card), field: (encode-path-segment $field)} | format pattern "/cards/{id_card}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addChecklists()
#
# POST /checklists
# operationId: addChecklists
export def "checklists create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --id-board: string # id of the board that the checklist should be added to
  --id-card: string # id of the card that the checklist should be added to
  --id-checklist-source: string # The id of the source checklist to copy into a new checklist.
  --name: string # a string with a length from 0 to 16384
  --pos: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/checklists" $qp)
  let req_body = {"idBoard": $id_board, "idCard": $id_card, "idChecklistSource": $id_checklist_source, "name": $name, "pos": $pos} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteChecklistsByIdChecklist()
#
# DELETE /checklists/{idChecklist}
# operationId: deleteChecklistsByIdChecklist
export def "checklists delete" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: (encode-path-segment $id_checklist)} | format pattern "/checklists/{id_checklist}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getChecklistsByIdChecklist()
#
# GET /checklists/{idChecklist}
# operationId: getChecklistsByIdChecklist
export def "checklists get" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cards: string # One of: all, closed, none, open or visible (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --check-items: string # One of: all or none (default: all)
  --check-item-fields: string # all or a comma-separated list of: name, nameData, pos, state or type (default: name, nameData, pos and state)
  --fields: string # all or a comma-separated list of: idBoard, idCard, name or pos (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cards" $cards "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "checkItems" $check_items "scalar") (serialize-qp "checkItem_fields" $check_item_fields "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: (encode-path-segment $id_checklist)} | format pattern "/checklists/{id_checklist}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateChecklistsByIdChecklist()
#
# PUT /checklists/{idChecklist}
# operationId: updateChecklistsByIdChecklist
export def "checklists update" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --id-board: string # id of the board that the checklist should be added to
  --id-card: string # id of the card that the checklist should be added to
  --id-checklist-source: string # The id of the source checklist to copy into a new checklist.
  --name: string # a string with a length from 0 to 16384
  --pos: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: (encode-path-segment $id_checklist)} | format pattern "/checklists/{id_checklist}") $qp)
  let req_body = {"idBoard": $id_board, "idCard": $id_card, "idChecklistSource": $id_checklist_source, "name": $name, "pos": $pos} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getChecklistsBoardByIdChecklist()
#
# GET /checklists/{idChecklist}/board
# operationId: getChecklistsBoardByIdChecklist
export def "checklists-board get" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: (encode-path-segment $id_checklist)} | format pattern "/checklists/{id_checklist}/board") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getChecklistsBoardByIdChecklistByField()
#
# GET /checklists/{idChecklist}/board/{field}
# operationId: getChecklistsBoardByIdChecklistByField
export def "checklists-board get-by" [
  id_checklist: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: (encode-path-segment $id_checklist), field: (encode-path-segment $field)} | format pattern "/checklists/{id_checklist}/board/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getChecklistsCardsByIdChecklist()
#
# GET /checklists/{idChecklist}/cards
# operationId: getChecklistsCardsByIdChecklist
export def "checklists-cards get" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --attachments: string # A boolean value or "cover" for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --stickers: string # true or false
  --members: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string # true or false
  --checklists: string # One of: all or none (default: none)
  --limit: string # a number from 1 to 1000
  --since: string # A date, or null
  --before: string # A date, or null
  --filter: string # One of: all, closed, none or open (default: open)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "attachments" $attachments "scalar") (serialize-qp "attachment_fields" $attachment_fields "scalar") (serialize-qp "stickers" $stickers "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "checkItemStates" $check_item_states "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: (encode-path-segment $id_checklist)} | format pattern "/checklists/{id_checklist}/cards") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getChecklistsCardsByIdChecklistByFilter()
#
# GET /checklists/{idChecklist}/cards/{filter}
# operationId: getChecklistsCardsByIdChecklistByFilter
export def "checklists-cards get-by" [
  id_checklist: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: (encode-path-segment $id_checklist), filter: (encode-path-segment $filter)} | format pattern "/checklists/{id_checklist}/cards/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getChecklistsCheckItemsByIdChecklist()
#
# GET /checklists/{idChecklist}/checkItems
# operationId: getChecklistsCheckItemsByIdChecklist
export def "checklists-check-items get" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all or none (default: all)
  --fields: string # all or a comma-separated list of: name, nameData, pos, state or type (default: name, nameData, pos and state)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: (encode-path-segment $id_checklist)} | format pattern "/checklists/{id_checklist}/checkItems") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addChecklistsCheckItemsByIdChecklist()
#
# POST /checklists/{idChecklist}/checkItems
# operationId: addChecklistsCheckItemsByIdChecklist
export def "checklists-check-items create" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --checked: string # true or false
  --name: string # a string with a length from 1 to 16384
  --pos: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: (encode-path-segment $id_checklist)} | format pattern "/checklists/{id_checklist}/checkItems") $qp)
  let req_body = {"checked": $checked, "name": $name, "pos": $pos} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteChecklistsCheckItemsByIdChecklistByIdCheckItem()
#
# DELETE /checklists/{idChecklist}/checkItems/{idCheckItem}
# operationId: deleteChecklistsCheckItemsByIdChecklistByIdCheckItem
export def "checklists-check-items delete-by" [
  id_checklist: string
  id_check_item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: (encode-path-segment $id_checklist), id_check_item: (encode-path-segment $id_check_item)} | format pattern "/checklists/{id_checklist}/checkItems/{id_check_item}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getChecklistsCheckItemsByIdChecklistByIdCheckItem()
#
# GET /checklists/{idChecklist}/checkItems/{idCheckItem}
# operationId: getChecklistsCheckItemsByIdChecklistByIdCheckItem
export def "checklists-check-items get-by" [
  id_checklist: string
  id_check_item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: name, nameData, pos, state or type (default: name, nameData, pos and state)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: (encode-path-segment $id_checklist), id_check_item: (encode-path-segment $id_check_item)} | format pattern "/checklists/{id_checklist}/checkItems/{id_check_item}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateChecklistsIdCardByIdChecklist()
#
# PUT /checklists/{idChecklist}/idCard
# operationId: updateChecklistsIdCardByIdChecklist
export def "checklists-id-card update" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # The id of the card that the checklist is on
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: (encode-path-segment $id_checklist)} | format pattern "/checklists/{id_checklist}/idCard") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateChecklistsNameByIdChecklist()
#
# PUT /checklists/{idChecklist}/name
# operationId: updateChecklistsNameByIdChecklist
export def "checklists-name update" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: (encode-path-segment $id_checklist)} | format pattern "/checklists/{id_checklist}/name") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateChecklistsPosByIdChecklist()
#
# PUT /checklists/{idChecklist}/pos
# operationId: updateChecklistsPosByIdChecklist
export def "checklists-pos update" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: (encode-path-segment $id_checklist)} | format pattern "/checklists/{id_checklist}/pos") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getChecklistsByIdChecklistByField()
#
# GET /checklists/{idChecklist}/{field}
# operationId: getChecklistsByIdChecklistByField
export def "checklists get-by" [
  id_checklist: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: (encode-path-segment $id_checklist), field: (encode-path-segment $field)} | format pattern "/checklists/{id_checklist}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addLabels()
#
# POST /labels
# operationId: addLabels
export def "labels create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --color: string # A valid label color or null
  --id-board: string # An id
  --name: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/labels" $qp)
  let req_body = {"color": $color, "idBoard": $id_board, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteLabelsByIdLabel()
#
# DELETE /labels/{idLabel}
# operationId: deleteLabelsByIdLabel
export def "labels delete" [
  id_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_label: (encode-path-segment $id_label)} | format pattern "/labels/{id_label}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getLabelsByIdLabel()
#
# GET /labels/{idLabel}
# operationId: getLabelsByIdLabel
export def "labels get" [
  id_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: color, idBoard, name or uses (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_label: (encode-path-segment $id_label)} | format pattern "/labels/{id_label}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateLabelsByIdLabel()
#
# PUT /labels/{idLabel}
# operationId: updateLabelsByIdLabel
export def "labels update" [
  id_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --color: string # A valid label color or null
  --id-board: string # An id
  --name: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_label: (encode-path-segment $id_label)} | format pattern "/labels/{id_label}") $qp)
  let req_body = {"color": $color, "idBoard": $id_board, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getLabelsBoardByIdLabel()
#
# GET /labels/{idLabel}/board
# operationId: getLabelsBoardByIdLabel
export def "labels-board get" [
  id_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_label: (encode-path-segment $id_label)} | format pattern "/labels/{id_label}/board") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getLabelsBoardByIdLabelByField()
#
# GET /labels/{idLabel}/board/{field}
# operationId: getLabelsBoardByIdLabelByField
export def "labels-board get-by" [
  id_label: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_label: (encode-path-segment $id_label), field: (encode-path-segment $field)} | format pattern "/labels/{id_label}/board/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateLabelsColorByIdLabel()
#
# PUT /labels/{idLabel}/color
# operationId: updateLabelsColorByIdLabel
export def "labels-color update" [
  id_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # A valid label color or null
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_label: (encode-path-segment $id_label)} | format pattern "/labels/{id_label}/color") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateLabelsNameByIdLabel()
#
# PUT /labels/{idLabel}/name
# operationId: updateLabelsNameByIdLabel
export def "labels-name update" [
  id_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_label: (encode-path-segment $id_label)} | format pattern "/labels/{id_label}/name") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# addLists()
#
# POST /lists
# operationId: addLists
export def "lists create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --closed: string # true or false
  --id-board: string # id of the board that the list should be added to
  --id-list-source: string # The id of the list to copy into a new list.
  --name: string # a string with a length from 1 to 16384
  --pos: string # A position. top , bottom , or a positive number.
  --subscribed: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists" $qp)
  let req_body = {"closed": $closed, "idBoard": $id_board, "idListSource": $id_list_source, "name": $name, "pos": $pos, "subscribed": $subscribed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getListsByIdList()
#
# GET /lists/{idList}
# operationId: getListsByIdList
export def "lists get" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cards: string # One of: all, closed, none or open (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --board: string # true or false
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, desc, descData, closed, idOrganization, pinned, url and prefs)
  --fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: name, closed, idBoard and pos)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cards" $cards "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "board" $board "scalar") (serialize-qp "board_fields" $board_fields "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: (encode-path-segment $id_list)} | format pattern "/lists/{id_list}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateListsByIdList()
#
# PUT /lists/{idList}
# operationId: updateListsByIdList
export def "lists update" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --closed: string # true or false
  --id-board: string # id of the board that the list should be added to
  --id-list-source: string # The id of the list to copy into a new list.
  --name: string # a string with a length from 1 to 16384
  --pos: string # A position. top , bottom , or a positive number.
  --subscribed: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: (encode-path-segment $id_list)} | format pattern "/lists/{id_list}") $qp)
  let req_body = {"closed": $closed, "idBoard": $id_board, "idListSource": $id_list_source, "name": $name, "pos": $pos, "subscribed": $subscribed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getListsActionsByIdList()
#
# GET /lists/{idList}/actions
# operationId: getListsActionsByIdList
export def "lists-actions get" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: string # true or false
  --display: string # true or false
  --filter: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization (default: all)
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --limit: string # a number from 0 to 1000 (default: 50)
  --format: string # One of: count, list or minimal (default: list)
  --since: string # A date, null or lastView
  --before: string # A date, or null
  --page: string # Page * limit must be less than 1000 (default: 0)
  --id-models: string # Only return actions related to these model ids
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --member-creator: string # true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entities" $entities "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "idModels" $id_models "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "memberCreator" $member_creator "scalar") (serialize-qp "memberCreator_fields" $member_creator_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: (encode-path-segment $id_list)} | format pattern "/lists/{id_list}/actions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addListsArchiveAllCardsByIdList()
#
# POST /lists/{idList}/archiveAllCards
# operationId: addListsArchiveAllCardsByIdList
export def "lists-archive-all-cards create" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: (encode-path-segment $id_list)} | format pattern "/lists/{id_list}/archiveAllCards") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getListsBoardByIdList()
#
# GET /lists/{idList}/board
# operationId: getListsBoardByIdList
export def "lists-board get" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: (encode-path-segment $id_list)} | format pattern "/lists/{id_list}/board") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getListsBoardByIdListByField()
#
# GET /lists/{idList}/board/{field}
# operationId: getListsBoardByIdListByField
export def "lists-board get-by" [
  id_list: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: (encode-path-segment $id_list), field: (encode-path-segment $field)} | format pattern "/lists/{id_list}/board/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getListsCardsByIdList()
#
# GET /lists/{idList}/cards
# operationId: getListsCardsByIdList
export def "lists-cards get" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --attachments: string # A boolean value or "cover" for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --stickers: string # true or false
  --members: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string # true or false
  --checklists: string # One of: all or none (default: none)
  --limit: string # a number from 1 to 1000
  --since: string # A date, or null
  --before: string # A date, or null
  --filter: string # One of: all, closed, none or open (default: open)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "attachments" $attachments "scalar") (serialize-qp "attachment_fields" $attachment_fields "scalar") (serialize-qp "stickers" $stickers "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "checkItemStates" $check_item_states "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: (encode-path-segment $id_list)} | format pattern "/lists/{id_list}/cards") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addListsCardsByIdList()
#
# POST /lists/{idList}/cards
# operationId: addListsCardsByIdList
export def "lists-cards create" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --desc: string # a string with a length from 0 to 16384
  --due: string # A date, or null
  --id-members: string # A comma-separated list of objectIds, 24-character hex strings
  --labels: string # all or a comma-separated list of: blue, green, orange, purple, red or yellow
  --name: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: (encode-path-segment $id_list)} | format pattern "/lists/{id_list}/cards") $qp)
  let req_body = {"desc": $desc, "due": $due, "idMembers": $id_members, "labels": $labels, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getListsCardsByIdListByFilter()
#
# GET /lists/{idList}/cards/{filter}
# operationId: getListsCardsByIdListByFilter
export def "lists-cards get-by" [
  id_list: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: (encode-path-segment $id_list), filter: (encode-path-segment $filter)} | format pattern "/lists/{id_list}/cards/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateListsClosedByIdList()
#
# PUT /lists/{idList}/closed
# operationId: updateListsClosedByIdList
export def "lists-closed update" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: (encode-path-segment $id_list)} | format pattern "/lists/{id_list}/closed") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateListsIdBoardByIdList()
#
# PUT /lists/{idList}/idBoard
# operationId: updateListsIdBoardByIdList
export def "lists-id-board update" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --pos: string # position of the list on the new board
  --value: string # id of the board the list should be moved to
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: (encode-path-segment $id_list)} | format pattern "/lists/{id_list}/idBoard") $qp)
  let req_body = {"pos": $pos, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# addListsMoveAllCardsByIdList()
#
# POST /lists/{idList}/moveAllCards
# operationId: addListsMoveAllCardsByIdList
export def "lists-move-all-cards create" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --id-board: string # id of the board that the cards should be moved to
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: (encode-path-segment $id_list)} | format pattern "/lists/{id_list}/moveAllCards") $qp)
  let req_body = {"idBoard": $id_board} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateListsNameByIdList()
#
# PUT /lists/{idList}/name
# operationId: updateListsNameByIdList
export def "lists-name update" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: (encode-path-segment $id_list)} | format pattern "/lists/{id_list}/name") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateListsPosByIdList()
#
# PUT /lists/{idList}/pos
# operationId: updateListsPosByIdList
export def "lists-pos update" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: (encode-path-segment $id_list)} | format pattern "/lists/{id_list}/pos") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateListsSubscribedByIdList()
#
# PUT /lists/{idList}/subscribed
# operationId: updateListsSubscribedByIdList
export def "lists-subscribed update" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: (encode-path-segment $id_list)} | format pattern "/lists/{id_list}/subscribed") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getListsByIdListByField()
#
# GET /lists/{idList}/{field}
# operationId: getListsByIdListByField
export def "lists get-by" [
  id_list: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: (encode-path-segment $id_list), field: (encode-path-segment $field)} | format pattern "/lists/{id_list}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getMembersByIdMember()
#
# GET /members/{idMember}
# operationId: getMembersByIdMember
export def "members get" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string # true or false
  --actions-display: string # true or false
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --action-since: string # A date, null or lastView
  --action-before: string # A date, or null
  --cards: string # One of: all, closed, none, open or visible (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --card-members: string # true or false
  --card-member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --card-attachments: string # A boolean value or "cover" for only card cover attachments
  --card-attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: url and previews)
  --card-stickers: string # true or false
  --boards: string # all or a comma-separated list of: closed, members, open, organization, pinned, public, starred or unpinned
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, closed, idOrganization and pinned)
  --board-actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --board-actions-entities: string # true or false
  --board-actions-display: string # true or false
  --board-actions-format: string # One of: count, list or minimal (default: list)
  --board-actions-since: string # A date, null or lastView
  --board-actions-limit: string # a number from 0 to 1000 (default: 50)
  --board-action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --board-lists: string # One of: all, closed, none or open (default: none)
  --board-memberships: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: none)
  --board-organization: string # true or false
  --board-organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: name and displayName)
  --boards-invited: string # all or a comma-separated list of: closed, members, open, organization, pinned, public, starred or unpinned
  --boards-invited-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, closed, idOrganization and pinned)
  --board-stars: string # true or false
  --saved-searches: string # true or false
  --organizations: string # One of: all, members, none or public (default: none)
  --organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --organization-paid-account: string # true or false
  --organizations-invited: string # One of: all, members, none or public (default: none)
  --organizations-invited-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --notifications: string # all or a comma-separated list of: addAdminToBoard, addAdminToOrganization, addedAttachmentToCard, addedMemberToCard, addedToBoard, addedToCard, addedToOrganization, cardDueSoon, changeCard, closeBoard, commentCard, createdCard, declinedInvitationToBoard, declinedInvitationToOrganization, invitedToBoard, invitedToOrganization, makeAdminOfBoard, makeAdminOfOrganization, memberJoinedTrello, mentionedOnCard, removedFromBoard, removedFromCard, removedFromOrganization, removedMemberFromCard, unconfirmedInvitedToBoard, unconfirmedInvitedToOrganization or updateCheckItemStateOnCard
  --notifications-entities: string # true or false
  --notifications-display: string # true or false
  --notifications-limit: string # a number from 1 to 1000 (default: 50)
  --notification-fields: string # all or a comma-separated list of: data, date, idMemberCreator, type or unread (default: all)
  --notification-member-creator: string # true or false
  --notification-member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --notification-before: string # An id, or null
  --notification-since: string # An id, or null
  --tokens: string # One of: all or none (default: none)
  --paid-account: string # true or false
  --board-backgrounds: string # One of: all, custom, default, none or premium (default: none)
  --custom-board-backgrounds: string # One of: all or none (default: none)
  --custom-stickers: string # One of: all or none (default: none)
  --custom-emoji: string # One of: all or none (default: none)
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "actions_entities" $actions_entities "scalar") (serialize-qp "actions_display" $actions_display "scalar") (serialize-qp "actions_limit" $actions_limit "scalar") (serialize-qp "action_fields" $action_fields "scalar") (serialize-qp "action_since" $action_since "scalar") (serialize-qp "action_before" $action_before "scalar") (serialize-qp "cards" $cards "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "card_members" $card_members "scalar") (serialize-qp "card_member_fields" $card_member_fields "scalar") (serialize-qp "card_attachments" $card_attachments "scalar") (serialize-qp "card_attachment_fields" $card_attachment_fields "scalar") (serialize-qp "card_stickers" $card_stickers "scalar") (serialize-qp "boards" $boards "scalar") (serialize-qp "board_fields" $board_fields "scalar") (serialize-qp "board_actions" $board_actions "scalar") (serialize-qp "board_actions_entities" $board_actions_entities "scalar") (serialize-qp "board_actions_display" $board_actions_display "scalar") (serialize-qp "board_actions_format" $board_actions_format "scalar") (serialize-qp "board_actions_since" $board_actions_since "scalar") (serialize-qp "board_actions_limit" $board_actions_limit "scalar") (serialize-qp "board_action_fields" $board_action_fields "scalar") (serialize-qp "board_lists" $board_lists "scalar") (serialize-qp "board_memberships" $board_memberships "scalar") (serialize-qp "board_organization" $board_organization "scalar") (serialize-qp "board_organization_fields" $board_organization_fields "scalar") (serialize-qp "boardsInvited" $boards_invited "scalar") (serialize-qp "boardsInvited_fields" $boards_invited_fields "scalar") (serialize-qp "boardStars" $board_stars "scalar") (serialize-qp "savedSearches" $saved_searches "scalar") (serialize-qp "organizations" $organizations "scalar") (serialize-qp "organization_fields" $organization_fields "scalar") (serialize-qp "organization_paid_account" $organization_paid_account "scalar") (serialize-qp "organizationsInvited" $organizations_invited "scalar") (serialize-qp "organizationsInvited_fields" $organizations_invited_fields "scalar") (serialize-qp "notifications" $notifications "scalar") (serialize-qp "notifications_entities" $notifications_entities "scalar") (serialize-qp "notifications_display" $notifications_display "scalar") (serialize-qp "notifications_limit" $notifications_limit "scalar") (serialize-qp "notification_fields" $notification_fields "scalar") (serialize-qp "notification_memberCreator" $notification_member_creator "scalar") (serialize-qp "notification_memberCreator_fields" $notification_member_creator_fields "scalar") (serialize-qp "notification_before" $notification_before "scalar") (serialize-qp "notification_since" $notification_since "scalar") (serialize-qp "tokens" $tokens "scalar") (serialize-qp "paid_account" $paid_account "scalar") (serialize-qp "boardBackgrounds" $board_backgrounds "scalar") (serialize-qp "customBoardBackgrounds" $custom_board_backgrounds "scalar") (serialize-qp "customStickers" $custom_stickers "scalar") (serialize-qp "customEmoji" $custom_emoji "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateMembersByIdMember()
#
# PUT /members/{idMember}
# operationId: updateMembersByIdMember
export def "members update" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --avatar-source: string # One of: gravatar, none or upload
  --bio: string # a string with a length from 0 to 16384
  --full-name: string # A string with a length of at least 1. Cannot begin or end with a space.
  --initials: string # A string with a length from 1 to 4. Cannot begin or end with a space
  --prefs-color-blind: string # true or false
  --prefs-locale: string # a string with a length from 0 to 255
  --prefs-minutes-between-summaries: string # -1 (disabled), 1 or 60
  --username: string # A string with a length of at least 3. Only lowercase letters, underscores, and numbers are allowed. Must be unique.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}") $qp)
  let req_body = {"avatarSource": $avatar_source, "bio": $bio, "fullName": $full_name, "initials": $initials, "prefs/colorBlind": $prefs_color_blind, "prefs/locale": $prefs_locale, "prefs/minutesBetweenSummaries": $prefs_minutes_between_summaries, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getMembersActionsByIdMember()
#
# GET /members/{idMember}/actions
# operationId: getMembersActionsByIdMember
export def "members-actions get" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: string # true or false
  --display: string # true or false
  --filter: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization (default: all)
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --limit: string # a number from 0 to 1000 (default: 50)
  --format: string # One of: count, list or minimal (default: list)
  --since: string # A date, null or lastView
  --before: string # A date, or null
  --page: string # Page * limit must be less than 1000 (default: 0)
  --id-models: string # Only return actions related to these model ids
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --member-creator: string # true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entities" $entities "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "idModels" $id_models "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "memberCreator" $member_creator "scalar") (serialize-qp "memberCreator_fields" $member_creator_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/actions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addMembersAvatarByIdMember()
#
# POST /members/{idMember}/avatar
# operationId: addMembersAvatarByIdMember
export def "members-avatar create" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --file: string # A file
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/avatar") $qp)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateMembersAvatarSourceByIdMember()
#
# PUT /members/{idMember}/avatarSource
# operationId: updateMembersAvatarSourceByIdMember
export def "members-avatar-source update" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # One of: gravatar, none or upload
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/avatarSource") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateMembersBioByIdMember()
#
# PUT /members/{idMember}/bio
# operationId: updateMembersBioByIdMember
export def "members-bio update" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/bio") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getMembersBoardBackgroundsByIdMember()
#
# GET /members/{idMember}/boardBackgrounds
# operationId: getMembersBoardBackgroundsByIdMember
export def "members-board-backgrounds get" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all, custom, default, none or premium (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/boardBackgrounds") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addMembersBoardBackgroundsByIdMember()
#
# POST /members/{idMember}/boardBackgrounds
# operationId: addMembersBoardBackgroundsByIdMember
export def "members-board-backgrounds create" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --brightness: string # One of: dark, light or unknown
  --file: string # A file
  --tile: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/boardBackgrounds") $qp)
  let req_body = {"brightness": $brightness, "file": $file, "tile": $tile} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteMembersBoardBackgroundsByIdMemberByIdBoardBackground()
#
# DELETE /members/{idMember}/boardBackgrounds/{idBoardBackground}
# operationId: deleteMembersBoardBackgroundsByIdMemberByIdBoardBackground
export def "members-board-backgrounds delete-by" [
  id_member: string
  id_board_background: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_board_background: (encode-path-segment $id_board_background)} | format pattern "/members/{id_member}/boardBackgrounds/{id_board_background}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getMembersBoardBackgroundsByIdMemberByIdBoardBackground()
#
# GET /members/{idMember}/boardBackgrounds/{idBoardBackground}
# operationId: getMembersBoardBackgroundsByIdMemberByIdBoardBackground
export def "members-board-backgrounds get-by" [
  id_member: string
  id_board_background: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: brightness, fullSizeUrl, scaled or tile (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_board_background: (encode-path-segment $id_board_background)} | format pattern "/members/{id_member}/boardBackgrounds/{id_board_background}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateMembersBoardBackgroundsByIdMemberByIdBoardBackground()
#
# PUT /members/{idMember}/boardBackgrounds/{idBoardBackground}
# operationId: updateMembersBoardBackgroundsByIdMemberByIdBoardBackground
export def "members-board-backgrounds update-by" [
  id_member: string
  id_board_background: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --brightness: string # One of: dark, light or unknown
  --file: string # A file
  --tile: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_board_background: (encode-path-segment $id_board_background)} | format pattern "/members/{id_member}/boardBackgrounds/{id_board_background}") $qp)
  let req_body = {"brightness": $brightness, "file": $file, "tile": $tile} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getMembersBoardStarsByIdMember()
#
# GET /members/{idMember}/boardStars
# operationId: getMembersBoardStarsByIdMember
export def "members-board-stars get" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/boardStars") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addMembersBoardStarsByIdMember()
#
# POST /members/{idMember}/boardStars
# operationId: addMembersBoardStarsByIdMember
export def "members-board-stars create" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --id-board: string # The id of the board to star
  --pos: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/boardStars") $qp)
  let req_body = {"idBoard": $id_board, "pos": $pos} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteMembersBoardStarsByIdMemberByIdBoardStar()
#
# DELETE /members/{idMember}/boardStars/{idBoardStar}
# operationId: deleteMembersBoardStarsByIdMemberByIdBoardStar
export def "members-board-stars delete-by" [
  id_member: string
  id_board_star: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_board_star: (encode-path-segment $id_board_star)} | format pattern "/members/{id_member}/boardStars/{id_board_star}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getMembersBoardStarsByIdMemberByIdBoardStar()
#
# GET /members/{idMember}/boardStars/{idBoardStar}
# operationId: getMembersBoardStarsByIdMemberByIdBoardStar
export def "members-board-stars get-by" [
  id_member: string
  id_board_star: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_board_star: (encode-path-segment $id_board_star)} | format pattern "/members/{id_member}/boardStars/{id_board_star}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateMembersBoardStarsByIdMemberByIdBoardStar()
#
# PUT /members/{idMember}/boardStars/{idBoardStar}
# operationId: updateMembersBoardStarsByIdMemberByIdBoardStar
export def "members-board-stars update-by" [
  id_member: string
  id_board_star: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --id-board: string # The id of the board to star
  --pos: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_board_star: (encode-path-segment $id_board_star)} | format pattern "/members/{id_member}/boardStars/{id_board_star}") $qp)
  let req_body = {"idBoard": $id_board, "pos": $pos} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateMembersBoardStarsIdBoardByIdMemberByIdBoardStar()
#
# PUT /members/{idMember}/boardStars/{idBoardStar}/idBoard
# operationId: updateMembersBoardStarsIdBoardByIdMemberByIdBoardStar
export def "members-board-stars-id-board update-by" [
  id_member: string
  id_board_star: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # An id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_board_star: (encode-path-segment $id_board_star)} | format pattern "/members/{id_member}/boardStars/{id_board_star}/idBoard") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateMembersBoardStarsPosByIdMemberByIdBoardStar()
#
# PUT /members/{idMember}/boardStars/{idBoardStar}/pos
# operationId: updateMembersBoardStarsPosByIdMemberByIdBoardStar
export def "members-board-stars-pos update-by" [
  id_member: string
  id_board_star: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_board_star: (encode-path-segment $id_board_star)} | format pattern "/members/{id_member}/boardStars/{id_board_star}/pos") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getMembersBoardsByIdMember()
#
# GET /members/{idMember}/boards
# operationId: getMembersBoardsByIdMember
export def "members-boards get" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # all or a comma-separated list of: closed, members, open, organization, pinned, public, starred or unpinned (default: all)
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string # true or false
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --actions-format: string # One of: count, list or minimal (default: list)
  --actions-since: string # A date, null or lastView
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --memberships: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: none)
  --organization: string # true or false
  --organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: name and displayName)
  --lists: string # One of: all, closed, none or open (default: none)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "actions" $actions "scalar") (serialize-qp "actions_entities" $actions_entities "scalar") (serialize-qp "actions_limit" $actions_limit "scalar") (serialize-qp "actions_format" $actions_format "scalar") (serialize-qp "actions_since" $actions_since "scalar") (serialize-qp "action_fields" $action_fields "scalar") (serialize-qp "memberships" $memberships "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "organization_fields" $organization_fields "scalar") (serialize-qp "lists" $lists "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/boards") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getMembersBoardsByIdMemberByFilter()
#
# GET /members/{idMember}/boards/{filter}
# operationId: getMembersBoardsByIdMemberByFilter
export def "members-boards get-by" [
  id_member: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), filter: (encode-path-segment $filter)} | format pattern "/members/{id_member}/boards/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getMembersBoardsInvitedByIdMember()
#
# GET /members/{idMember}/boardsInvited
# operationId: getMembersBoardsInvitedByIdMember
export def "members-boards-invited get" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/boardsInvited") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getMembersBoardsInvitedByIdMemberByField()
#
# GET /members/{idMember}/boardsInvited/{field}
# operationId: getMembersBoardsInvitedByIdMemberByField
export def "members-boards-invited get-by" [
  id_member: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), field: (encode-path-segment $field)} | format pattern "/members/{id_member}/boardsInvited/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getMembersCardsByIdMember()
#
# GET /members/{idMember}/cards
# operationId: getMembersCardsByIdMember
export def "members-cards get" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --attachments: string # A boolean value or "cover" for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --stickers: string # true or false
  --members: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string # true or false
  --checklists: string # One of: all or none (default: none)
  --limit: string # a number from 1 to 1000
  --since: string # A date, or null
  --before: string # A date, or null
  --filter: string # One of: all, closed, none, open or visible (default: visible)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "attachments" $attachments "scalar") (serialize-qp "attachment_fields" $attachment_fields "scalar") (serialize-qp "stickers" $stickers "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "checkItemStates" $check_item_states "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/cards") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getMembersCardsByIdMemberByFilter()
#
# GET /members/{idMember}/cards/{filter}
# operationId: getMembersCardsByIdMemberByFilter
export def "members-cards get-by" [
  id_member: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), filter: (encode-path-segment $filter)} | format pattern "/members/{id_member}/cards/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getMembersCustomBoardBackgroundsByIdMember()
#
# GET /members/{idMember}/customBoardBackgrounds
# operationId: getMembersCustomBoardBackgroundsByIdMember
export def "members-custom-board-backgrounds get" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all or none (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/customBoardBackgrounds") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addMembersCustomBoardBackgroundsByIdMember()
#
# POST /members/{idMember}/customBoardBackgrounds
# operationId: addMembersCustomBoardBackgroundsByIdMember
export def "members-custom-board-backgrounds create" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --brightness: string # One of: dark, light or unknown
  --file: string # A file
  --tile: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/customBoardBackgrounds") $qp)
  let req_body = {"brightness": $brightness, "file": $file, "tile": $tile} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteMembersCustomBoardBackgroundsByIdMemberByIdBoardBackground()
#
# DELETE /members/{idMember}/customBoardBackgrounds/{idBoardBackground}
# operationId: deleteMembersCustomBoardBackgroundsByIdMemberByIdBoardBackground
export def "members-custom-board-backgrounds delete-by" [
  id_member: string
  id_board_background: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_board_background: (encode-path-segment $id_board_background)} | format pattern "/members/{id_member}/customBoardBackgrounds/{id_board_background}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getMembersCustomBoardBackgroundsByIdMemberByIdBoardBackground()
#
# GET /members/{idMember}/customBoardBackgrounds/{idBoardBackground}
# operationId: getMembersCustomBoardBackgroundsByIdMemberByIdBoardBackground
export def "members-custom-board-backgrounds get-by" [
  id_member: string
  id_board_background: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: brightness, fullSizeUrl, scaled or tile (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_board_background: (encode-path-segment $id_board_background)} | format pattern "/members/{id_member}/customBoardBackgrounds/{id_board_background}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateMembersCustomBoardBackgroundsByIdMemberByIdBoardBackground()
#
# PUT /members/{idMember}/customBoardBackgrounds/{idBoardBackground}
# operationId: updateMembersCustomBoardBackgroundsByIdMemberByIdBoardBackground
export def "members-custom-board-backgrounds update-by" [
  id_member: string
  id_board_background: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --brightness: string # One of: dark, light or unknown
  --file: string # A file
  --tile: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_board_background: (encode-path-segment $id_board_background)} | format pattern "/members/{id_member}/customBoardBackgrounds/{id_board_background}") $qp)
  let req_body = {"brightness": $brightness, "file": $file, "tile": $tile} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getMembersCustomEmojiByIdMember()
#
# GET /members/{idMember}/customEmoji
# operationId: getMembersCustomEmojiByIdMember
export def "members-custom-emoji get" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all or none (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/customEmoji") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addMembersCustomEmojiByIdMember()
#
# POST /members/{idMember}/customEmoji
# operationId: addMembersCustomEmojiByIdMember
export def "members-custom-emoji create" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --file: string # A file
  --name: string # a string with a length from 2 to 64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/customEmoji") $qp)
  let req_body = {"file": $file, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getMembersCustomEmojiByIdMemberByIdCustomEmoji()
#
# GET /members/{idMember}/customEmoji/{idCustomEmoji}
# operationId: getMembersCustomEmojiByIdMemberByIdCustomEmoji
export def "members-custom-emoji get-by" [
  id_member: string
  id_custom_emoji: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: name or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_custom_emoji: (encode-path-segment $id_custom_emoji)} | format pattern "/members/{id_member}/customEmoji/{id_custom_emoji}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getMembersCustomStickersByIdMember()
#
# GET /members/{idMember}/customStickers
# operationId: getMembersCustomStickersByIdMember
export def "members-custom-stickers get" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all or none (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/customStickers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addMembersCustomStickersByIdMember()
#
# POST /members/{idMember}/customStickers
# operationId: addMembersCustomStickersByIdMember
export def "members-custom-stickers create" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --file: string # A file
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/customStickers") $qp)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteMembersCustomStickersByIdMemberByIdCustomSticker()
#
# DELETE /members/{idMember}/customStickers/{idCustomSticker}
# operationId: deleteMembersCustomStickersByIdMemberByIdCustomSticker
export def "members-custom-stickers delete-by" [
  id_member: string
  id_custom_sticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_custom_sticker: (encode-path-segment $id_custom_sticker)} | format pattern "/members/{id_member}/customStickers/{id_custom_sticker}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getMembersCustomStickersByIdMemberByIdCustomSticker()
#
# GET /members/{idMember}/customStickers/{idCustomSticker}
# operationId: getMembersCustomStickersByIdMemberByIdCustomSticker
export def "members-custom-stickers get-by" [
  id_member: string
  id_custom_sticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: scaled or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_custom_sticker: (encode-path-segment $id_custom_sticker)} | format pattern "/members/{id_member}/customStickers/{id_custom_sticker}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getMembersDeltasByIdMember()
#
# GET /members/{idMember}/deltas
# operationId: getMembersDeltasByIdMember
export def "members-deltas get" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: string # A valid tag for subscribing
  --ix-last-update: string # a number from -1 to Infinity
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tags" $tags "scalar") (serialize-qp "ixLastUpdate" $ix_last_update "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/deltas") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateMembersFullNameByIdMember()
#
# PUT /members/{idMember}/fullName
# operationId: updateMembersFullNameByIdMember
export def "members-full-name update" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # A string with a length of at least 1. Cannot begin or end with a space.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/fullName") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateMembersInitialsByIdMember()
#
# PUT /members/{idMember}/initials
# operationId: updateMembersInitialsByIdMember
export def "members-initials update" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # A string with a length from 1 to 4. Cannot begin or end with a space
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/initials") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getMembersNotificationsByIdMember()
#
# GET /members/{idMember}/notifications
# operationId: getMembersNotificationsByIdMember
export def "members-notifications get" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: string # true or false
  --display: string # true or false
  --filter: string # all or a comma-separated list of: addAdminToBoard, addAdminToOrganization, addedAttachmentToCard, addedMemberToCard, addedToBoard, addedToCard, addedToOrganization, cardDueSoon, changeCard, closeBoard, commentCard, createdCard, declinedInvitationToBoard, declinedInvitationToOrganization, invitedToBoard, invitedToOrganization, makeAdminOfBoard, makeAdminOfOrganization, memberJoinedTrello, mentionedOnCard, removedFromBoard, removedFromCard, removedFromOrganization, removedMemberFromCard, unconfirmedInvitedToBoard, unconfirmedInvitedToOrganization or updateCheckItemStateOnCard (default: all)
  --read-filter: string # One of: all, read or unread (default: all)
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator, type or unread (default: all)
  --limit: string # a number from 1 to 1000 (default: 50)
  --page: string # a number from 0 to 100 (default: 0)
  --before: string # An id, or null
  --since: string # An id, or null
  --member-creator: string # true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entities" $entities "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "read_filter" $read_filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "memberCreator" $member_creator "scalar") (serialize-qp "memberCreator_fields" $member_creator_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/notifications") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getMembersNotificationsByIdMemberByFilter()
#
# GET /members/{idMember}/notifications/{filter}
# operationId: getMembersNotificationsByIdMemberByFilter
export def "members-notifications get-by" [
  id_member: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), filter: (encode-path-segment $filter)} | format pattern "/members/{id_member}/notifications/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addMembersOneTimeMessagesDismissedByIdMember()
#
# POST /members/{idMember}/oneTimeMessagesDismissed
# operationId: addMembersOneTimeMessagesDismissedByIdMember
export def "members-one-time-messages-dismissed create" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # Type of message dismissed
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/oneTimeMessagesDismissed") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getMembersOrganizationsByIdMember()
#
# GET /members/{idMember}/organizations
# operationId: getMembersOrganizationsByIdMember
export def "members-organizations get" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all, members, none or public (default: all)
  --fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --paid-account: string # true or false
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "paid_account" $paid_account "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/organizations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getMembersOrganizationsByIdMemberByFilter()
#
# GET /members/{idMember}/organizations/{filter}
# operationId: getMembersOrganizationsByIdMemberByFilter
export def "members-organizations get-by" [
  id_member: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), filter: (encode-path-segment $filter)} | format pattern "/members/{id_member}/organizations/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getMembersOrganizationsInvitedByIdMember()
#
# GET /members/{idMember}/organizationsInvited
# operationId: getMembersOrganizationsInvitedByIdMember
export def "members-organizations-invited get" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/organizationsInvited") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getMembersOrganizationsInvitedByIdMemberByField()
#
# GET /members/{idMember}/organizationsInvited/{field}
# operationId: getMembersOrganizationsInvitedByIdMemberByField
export def "members-organizations-invited get-by" [
  id_member: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), field: (encode-path-segment $field)} | format pattern "/members/{id_member}/organizationsInvited/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateMembersPrefsColorBlindByIdMember()
#
# PUT /members/{idMember}/prefs/colorBlind
# operationId: updateMembersPrefsColorBlindByIdMember
export def "members-prefs-color-blind update" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/prefs/colorBlind") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateMembersPrefsLocaleByIdMember()
#
# PUT /members/{idMember}/prefs/locale
# operationId: updateMembersPrefsLocaleByIdMember
export def "members-prefs-locale update" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 0 to 255
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/prefs/locale") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateMembersPrefsMinutesBetweenSummariesByIdMember()
#
# PUT /members/{idMember}/prefs/minutesBetweenSummaries
# operationId: updateMembersPrefsMinutesBetweenSummariesByIdMember
export def "members-prefs-minutes-between-summaries update" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # -1 (disabled), 1 or 60
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/prefs/minutesBetweenSummaries") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getMembersSavedSearchesByIdMember()
#
# GET /members/{idMember}/savedSearches
# operationId: getMembersSavedSearchesByIdMember
export def "members-saved-searches get" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/savedSearches") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addMembersSavedSearchesByIdMember()
#
# POST /members/{idMember}/savedSearches
# operationId: addMembersSavedSearchesByIdMember
export def "members-saved-searches create" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --name: string # A non-empty string with at least one non-space character
  --pos: string # A position. top , bottom , or a positive number.
  --query: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/savedSearches") $qp)
  let req_body = {"name": $name, "pos": $pos, "query": $query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteMembersSavedSearchesByIdMemberByIdSavedSearch()
#
# DELETE /members/{idMember}/savedSearches/{idSavedSearch}
# operationId: deleteMembersSavedSearchesByIdMemberByIdSavedSearch
export def "members-saved-searches delete-by-by-list" [
  id_member: string
  id_saved_search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_saved_search: (encode-path-segment $id_saved_search)} | format pattern "/members/{id_member}/savedSearches/{id_saved_search}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getMembersSavedSearchesByIdMemberByIdSavedSearch()
#
# GET /members/{idMember}/savedSearches/{idSavedSearch}
# operationId: getMembersSavedSearchesByIdMemberByIdSavedSearch
export def "members-saved-searches get-by-by-list" [
  id_member: string
  id_saved_search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_saved_search: (encode-path-segment $id_saved_search)} | format pattern "/members/{id_member}/savedSearches/{id_saved_search}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateMembersSavedSearchesByIdMemberByIdSavedSearch()
#
# PUT /members/{idMember}/savedSearches/{idSavedSearch}
# operationId: updateMembersSavedSearchesByIdMemberByIdSavedSearch
export def "members-saved-searches update-by-by-list" [
  id_member: string
  id_saved_search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --name: string # A non-empty string with at least one non-space character
  --pos: string # A position. top , bottom , or a positive number.
  --query: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_saved_search: (encode-path-segment $id_saved_search)} | format pattern "/members/{id_member}/savedSearches/{id_saved_search}") $qp)
  let req_body = {"name": $name, "pos": $pos, "query": $query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateMembersSavedSearchesNameByIdMemberByIdSavedSearch()
#
# PUT /members/{idMember}/savedSearches/{idSavedSearch}/name
# operationId: updateMembersSavedSearchesNameByIdMemberByIdSavedSearch
export def "members-saved-searches-name update-by-by-list" [
  id_member: string
  id_saved_search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # A non-empty string with at least one non-space character
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_saved_search: (encode-path-segment $id_saved_search)} | format pattern "/members/{id_member}/savedSearches/{id_saved_search}/name") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateMembersSavedSearchesPosByIdMemberByIdSavedSearch()
#
# PUT /members/{idMember}/savedSearches/{idSavedSearch}/pos
# operationId: updateMembersSavedSearchesPosByIdMemberByIdSavedSearch
export def "members-saved-searches-pos update-by-by-list" [
  id_member: string
  id_saved_search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_saved_search: (encode-path-segment $id_saved_search)} | format pattern "/members/{id_member}/savedSearches/{id_saved_search}/pos") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateMembersSavedSearchesQueryByIdMemberByIdSavedSearch()
#
# PUT /members/{idMember}/savedSearches/{idSavedSearch}/query
# operationId: updateMembersSavedSearchesQueryByIdMemberByIdSavedSearch
export def "members-saved-searches-query update-by-by-list" [
  id_member: string
  id_saved_search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), id_saved_search: (encode-path-segment $id_saved_search)} | format pattern "/members/{id_member}/savedSearches/{id_saved_search}/query") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getMembersTokensByIdMember()
#
# GET /members/{idMember}/tokens
# operationId: getMembersTokensByIdMember
export def "members-tokens get" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all or none (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/tokens") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateMembersUsernameByIdMember()
#
# PUT /members/{idMember}/username
# operationId: updateMembersUsernameByIdMember
export def "members-username update" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # A string with a length of at least 3. Only lowercase letters, underscores, and numbers are allowed. Must be unique.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member)} | format pattern "/members/{id_member}/username") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getMembersByIdMemberByField()
#
# GET /members/{idMember}/{field}
# operationId: getMembersByIdMemberByField
export def "members get-by" [
  id_member: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: (encode-path-segment $id_member), field: (encode-path-segment $field)} | format pattern "/members/{id_member}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addNotificationsAllRead()
#
# POST /notifications/all/read
# operationId: addNotificationsAllRead
export def "notifications-all-read create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/all/read" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getNotificationsByIdNotification()
#
# GET /notifications/{idNotification}
# operationId: getNotificationsByIdNotification
export def "notifications get" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display: string # true or false
  --entities: string # true or false
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator, type or unread (default: all)
  --member-creator: string # true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --board: string # true or false
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name)
  --list: string # true or false
  --card: string # true or false
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: name)
  --organization: string # true or false
  --organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: displayName)
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "display" $display "scalar") (serialize-qp "entities" $entities "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "memberCreator" $member_creator "scalar") (serialize-qp "memberCreator_fields" $member_creator_fields "scalar") (serialize-qp "board" $board "scalar") (serialize-qp "board_fields" $board_fields "scalar") (serialize-qp "list" $list "scalar") (serialize-qp "card" $card "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "organization_fields" $organization_fields "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: (encode-path-segment $id_notification)} | format pattern "/notifications/{id_notification}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateNotificationsByIdNotification()
#
# PUT /notifications/{idNotification}
# operationId: updateNotificationsByIdNotification
export def "notifications update" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --unread: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: (encode-path-segment $id_notification)} | format pattern "/notifications/{id_notification}") $qp)
  let req_body = {"unread": $unread} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getNotificationsBoardByIdNotification()
#
# GET /notifications/{idNotification}/board
# operationId: getNotificationsBoardByIdNotification
export def "notifications-board get" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: (encode-path-segment $id_notification)} | format pattern "/notifications/{id_notification}/board") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getNotificationsBoardByIdNotificationByField()
#
# GET /notifications/{idNotification}/board/{field}
# operationId: getNotificationsBoardByIdNotificationByField
export def "notifications-board get-by" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: (encode-path-segment $id_notification), field: (encode-path-segment $field)} | format pattern "/notifications/{id_notification}/board/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getNotificationsCardByIdNotification()
#
# GET /notifications/{idNotification}/card
# operationId: getNotificationsCardByIdNotification
export def "notifications-card get" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: (encode-path-segment $id_notification)} | format pattern "/notifications/{id_notification}/card") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getNotificationsCardByIdNotificationByField()
#
# GET /notifications/{idNotification}/card/{field}
# operationId: getNotificationsCardByIdNotificationByField
export def "notifications-card get-by" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: (encode-path-segment $id_notification), field: (encode-path-segment $field)} | format pattern "/notifications/{id_notification}/card/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getNotificationsDisplayByIdNotification()
#
# GET /notifications/{idNotification}/display
# operationId: getNotificationsDisplayByIdNotification
export def "notifications-display get" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: (encode-path-segment $id_notification)} | format pattern "/notifications/{id_notification}/display") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getNotificationsEntitiesByIdNotification()
#
# GET /notifications/{idNotification}/entities
# operationId: getNotificationsEntitiesByIdNotification
export def "notifications-entities get" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: (encode-path-segment $id_notification)} | format pattern "/notifications/{id_notification}/entities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getNotificationsListByIdNotification()
#
# GET /notifications/{idNotification}/list
# operationId: getNotificationsListByIdNotification
export def "notifications-list get" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: (encode-path-segment $id_notification)} | format pattern "/notifications/{id_notification}/list") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getNotificationsListByIdNotificationByField()
#
# GET /notifications/{idNotification}/list/{field}
# operationId: getNotificationsListByIdNotificationByField
export def "notifications-list get-by" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: (encode-path-segment $id_notification), field: (encode-path-segment $field)} | format pattern "/notifications/{id_notification}/list/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getNotificationsMemberByIdNotification()
#
# GET /notifications/{idNotification}/member
# operationId: getNotificationsMemberByIdNotification
export def "notifications-member get" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: (encode-path-segment $id_notification)} | format pattern "/notifications/{id_notification}/member") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getNotificationsMemberByIdNotificationByField()
#
# GET /notifications/{idNotification}/member/{field}
# operationId: getNotificationsMemberByIdNotificationByField
export def "notifications-member get-by" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: (encode-path-segment $id_notification), field: (encode-path-segment $field)} | format pattern "/notifications/{id_notification}/member/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getNotificationsMemberCreatorByIdNotification()
#
# GET /notifications/{idNotification}/memberCreator
# operationId: getNotificationsMemberCreatorByIdNotification
export def "notifications-member-creator get" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: (encode-path-segment $id_notification)} | format pattern "/notifications/{id_notification}/memberCreator") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getNotificationsMemberCreatorByIdNotificationByField()
#
# GET /notifications/{idNotification}/memberCreator/{field}
# operationId: getNotificationsMemberCreatorByIdNotificationByField
export def "notifications-member-creator get-by" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: (encode-path-segment $id_notification), field: (encode-path-segment $field)} | format pattern "/notifications/{id_notification}/memberCreator/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getNotificationsOrganizationByIdNotification()
#
# GET /notifications/{idNotification}/organization
# operationId: getNotificationsOrganizationByIdNotification
export def "notifications-organization get" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: (encode-path-segment $id_notification)} | format pattern "/notifications/{id_notification}/organization") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getNotificationsOrganizationByIdNotificationByField()
#
# GET /notifications/{idNotification}/organization/{field}
# operationId: getNotificationsOrganizationByIdNotificationByField
export def "notifications-organization get-by" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: (encode-path-segment $id_notification), field: (encode-path-segment $field)} | format pattern "/notifications/{id_notification}/organization/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateNotificationsUnreadByIdNotification()
#
# PUT /notifications/{idNotification}/unread
# operationId: updateNotificationsUnreadByIdNotification
export def "notifications-unread update" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: (encode-path-segment $id_notification)} | format pattern "/notifications/{id_notification}/unread") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getNotificationsByIdNotificationByField()
#
# GET /notifications/{idNotification}/{field}
# operationId: getNotificationsByIdNotificationByField
export def "notifications get-by" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: (encode-path-segment $id_notification), field: (encode-path-segment $field)} | format pattern "/notifications/{id_notification}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addOrganizations()
#
# POST /organizations
# operationId: addOrganizations
export def "organizations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --desc: string # a string with a length from 0 to 16384
  --display-name: string # A string with a length of at least 1. Cannot begin or end with a space.
  --name: string # a string with a length from 0 to 16384
  --prefs-associated-domain: string # The google apps domain to link this org to.
  --prefs-board-visibility-restrict-org: string # One of: admin, none or org
  --prefs-board-visibility-restrict-private: string # One of: admin, none or org
  --prefs-board-visibility-restrict-public: string # One of: admin, none or org
  --prefs-external-members-disabled: string # true or false
  --prefs-google-apps-version: string # a number from 1 to 2
  --prefs-org-invite-restrict: string # An email address with optional expansion tokens
  --prefs-permission-level: string # One of: private or public
  --website: string # A URL starting with http:// or https:// or null
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizations" $qp)
  let req_body = {"desc": $desc, "displayName": $display_name, "name": $name, "prefs/associatedDomain": $prefs_associated_domain, "prefs/boardVisibilityRestrict/org": $prefs_board_visibility_restrict_org, "prefs/boardVisibilityRestrict/private": $prefs_board_visibility_restrict_private, "prefs/boardVisibilityRestrict/public": $prefs_board_visibility_restrict_public, "prefs/externalMembersDisabled": $prefs_external_members_disabled, "prefs/googleAppsVersion": $prefs_google_apps_version, "prefs/orgInviteRestrict": $prefs_org_invite_restrict, "prefs/permissionLevel": $prefs_permission_level, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteOrganizationsByIdOrg()
#
# DELETE /organizations/{idOrg}
# operationId: deleteOrganizationsByIdOrg
export def "organizations delete-by-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getOrganizationsByIdOrg()
#
# GET /organizations/{idOrg}
# operationId: getOrganizationsByIdOrg
export def "organizations list" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string # true or false
  --actions-display: string # true or false
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --memberships: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: none)
  --memberships-member: string # true or false
  --memberships-member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --members: string # One of: admins, all, none, normal or owners (default: none)
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials, username and confirmed)
  --member-activity: string # true or false ; works for premium organizations only.
  --members-invited: string # One of: admins, all, none, normal or owners (default: none)
  --members-invited-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, initials, fullName and username)
  --boards: string # all or a comma-separated list of: closed, members, open, organization, pinned, public, starred or unpinned (default: none)
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --board-actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --board-actions-entities: string # true or false
  --board-actions-display: string # true or false
  --board-actions-format: string # One of: count, list or minimal (default: list)
  --board-actions-since: string # A date, null or lastView
  --board-actions-limit: string # a number from 0 to 1000 (default: 50)
  --board-action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --board-lists: string # One of: all, closed, none or open (default: none)
  --paid-account: string # true or false
  --fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: name, displayName, desc, descData, url, website, logoHash, products and powerUps)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "actions_entities" $actions_entities "scalar") (serialize-qp "actions_display" $actions_display "scalar") (serialize-qp "actions_limit" $actions_limit "scalar") (serialize-qp "action_fields" $action_fields "scalar") (serialize-qp "memberships" $memberships "scalar") (serialize-qp "memberships_member" $memberships_member "scalar") (serialize-qp "memberships_member_fields" $memberships_member_fields "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "member_activity" $member_activity "scalar") (serialize-qp "membersInvited" $members_invited "scalar") (serialize-qp "membersInvited_fields" $members_invited_fields "scalar") (serialize-qp "boards" $boards "scalar") (serialize-qp "board_fields" $board_fields "scalar") (serialize-qp "board_actions" $board_actions "scalar") (serialize-qp "board_actions_entities" $board_actions_entities "scalar") (serialize-qp "board_actions_display" $board_actions_display "scalar") (serialize-qp "board_actions_format" $board_actions_format "scalar") (serialize-qp "board_actions_since" $board_actions_since "scalar") (serialize-qp "board_actions_limit" $board_actions_limit "scalar") (serialize-qp "board_action_fields" $board_action_fields "scalar") (serialize-qp "board_lists" $board_lists "scalar") (serialize-qp "paid_account" $paid_account "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateOrganizationsByIdOrg()
#
# PUT /organizations/{idOrg}
# operationId: updateOrganizationsByIdOrg
export def "organizations update-by-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --desc: string # a string with a length from 0 to 16384
  --display-name: string # A string with a length of at least 1. Cannot begin or end with a space.
  --name: string # a string with a length from 0 to 16384
  --prefs-associated-domain: string # The google apps domain to link this org to.
  --prefs-board-visibility-restrict-org: string # One of: admin, none or org
  --prefs-board-visibility-restrict-private: string # One of: admin, none or org
  --prefs-board-visibility-restrict-public: string # One of: admin, none or org
  --prefs-external-members-disabled: string # true or false
  --prefs-google-apps-version: string # a number from 1 to 2
  --prefs-org-invite-restrict: string # An email address with optional expansion tokens
  --prefs-permission-level: string # One of: private or public
  --website: string # A URL starting with http:// or https:// or null
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}") $qp)
  let req_body = {"desc": $desc, "displayName": $display_name, "name": $name, "prefs/associatedDomain": $prefs_associated_domain, "prefs/boardVisibilityRestrict/org": $prefs_board_visibility_restrict_org, "prefs/boardVisibilityRestrict/private": $prefs_board_visibility_restrict_private, "prefs/boardVisibilityRestrict/public": $prefs_board_visibility_restrict_public, "prefs/externalMembersDisabled": $prefs_external_members_disabled, "prefs/googleAppsVersion": $prefs_google_apps_version, "prefs/orgInviteRestrict": $prefs_org_invite_restrict, "prefs/permissionLevel": $prefs_permission_level, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getOrganizationsActionsByIdOrg()
#
# GET /organizations/{idOrg}/actions
# operationId: getOrganizationsActionsByIdOrg
export def "organizations-actions get-by-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: string # true or false
  --display: string # true or false
  --filter: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization (default: all)
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --limit: string # a number from 0 to 1000 (default: 50)
  --format: string # One of: count, list or minimal (default: list)
  --since: string # A date, null or lastView
  --before: string # A date, or null
  --page: string # Page * limit must be less than 1000 (default: 0)
  --id-models: string # Only return actions related to these model ids
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --member-creator: string # true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entities" $entities "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "idModels" $id_models "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "memberCreator" $member_creator "scalar") (serialize-qp "memberCreator_fields" $member_creator_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/actions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getOrganizationsBoardsByIdOrg()
#
# GET /organizations/{idOrg}/boards
# operationId: getOrganizationsBoardsByIdOrg
export def "organizations-boards list" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # all or a comma-separated list of: closed, members, open, organization, pinned, public, starred or unpinned (default: all)
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string # true or false
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --actions-format: string # One of: count, list or minimal (default: list)
  --actions-since: string # A date, null or lastView
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --memberships: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: none)
  --organization: string # true or false
  --organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: name and displayName)
  --lists: string # One of: all, closed, none or open (default: none)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "actions" $actions "scalar") (serialize-qp "actions_entities" $actions_entities "scalar") (serialize-qp "actions_limit" $actions_limit "scalar") (serialize-qp "actions_format" $actions_format "scalar") (serialize-qp "actions_since" $actions_since "scalar") (serialize-qp "action_fields" $action_fields "scalar") (serialize-qp "memberships" $memberships "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "organization_fields" $organization_fields "scalar") (serialize-qp "lists" $lists "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/boards") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getOrganizationsBoardsByIdOrgByFilter()
#
# GET /organizations/{idOrg}/boards/{filter}
# operationId: getOrganizationsBoardsByIdOrgByFilter
export def "organizations-boards get-by-org" [
  id_org: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org), filter: (encode-path-segment $filter)} | format pattern "/organizations/{id_org}/boards/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getOrganizationsDeltasByIdOrg()
#
# GET /organizations/{idOrg}/deltas
# operationId: getOrganizationsDeltasByIdOrg
export def "organizations-deltas get-by-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: string # A valid tag for subscribing
  --ix-last-update: string # a number from -1 to Infinity
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tags" $tags "scalar") (serialize-qp "ixLastUpdate" $ix_last_update "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/deltas") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateOrganizationsDescByIdOrg()
#
# PUT /organizations/{idOrg}/desc
# operationId: updateOrganizationsDescByIdOrg
export def "organizations-desc update-by-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/desc") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateOrganizationsDisplayNameByIdOrg()
#
# PUT /organizations/{idOrg}/displayName
# operationId: updateOrganizationsDisplayNameByIdOrg
export def "organizations-display-name update-by-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # A string with a length of at least 1. Cannot begin or end with a space.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/displayName") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteOrganizationsLogoByIdOrg()
#
# DELETE /organizations/{idOrg}/logo
# operationId: deleteOrganizationsLogoByIdOrg
export def "organizations-logo delete-by-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/logo") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addOrganizationsLogoByIdOrg()
#
# POST /organizations/{idOrg}/logo
# operationId: addOrganizationsLogoByIdOrg
export def "organizations-logo create-by-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --file: string # A file
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/logo") $qp)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getOrganizationsMembersByIdOrg()
#
# GET /organizations/{idOrg}/members
# operationId: getOrganizationsMembersByIdOrg
export def "organizations-members list" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: admins, all, none, normal or owners (default: all)
  --fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --activity: string # true or false ; works for premium organizations only.
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "activity" $activity "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateOrganizationsMembersByIdOrg()
#
# PUT /organizations/{idOrg}/members
# operationId: updateOrganizationsMembersByIdOrg
export def "organizations-members update-by-org-by-idOrg" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --email: string # An email address
  --full-name: string # A string with a length of at least 1. Cannot begin or end with a space.
  --type: string # One of: admin, normal or observer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/members") $qp)
  let req_body = {"email": $email, "fullName": $full_name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getOrganizationsMembersByIdOrgByFilter()
#
# GET /organizations/{idOrg}/members/{filter}
# operationId: getOrganizationsMembersByIdOrgByFilter
export def "organizations-members get-by-org" [
  id_org: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org), filter: (encode-path-segment $filter)} | format pattern "/organizations/{id_org}/members/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# deleteOrganizationsMembersByIdOrgByIdMember()
#
# DELETE /organizations/{idOrg}/members/{idMember}
# operationId: deleteOrganizationsMembersByIdOrgByIdMember
export def "organizations-members delete-by-org" [
  id_org: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org), id_member: (encode-path-segment $id_member)} | format pattern "/organizations/{id_org}/members/{id_member}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateOrganizationsMembersByIdOrgByIdMember()
#
# PUT /organizations/{idOrg}/members/{idMember}
# operationId: updateOrganizationsMembersByIdOrgByIdMember
export def "organizations-members update-by-org-by-idOrg-idMember" [
  id_org: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --email: string # An email address
  --full-name: string # A string with a length of at least 1. Cannot begin or end with a space.
  --type: string # One of: admin, normal or observer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org), id_member: (encode-path-segment $id_member)} | format pattern "/organizations/{id_org}/members/{id_member}") $qp)
  let req_body = {"email": $email, "fullName": $full_name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteOrganizationsMembersAllByIdOrgByIdMember()
#
# DELETE /organizations/{idOrg}/members/{idMember}/all
# operationId: deleteOrganizationsMembersAllByIdOrgByIdMember
export def "organizations-members-all delete-by-org" [
  id_org: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org), id_member: (encode-path-segment $id_member)} | format pattern "/organizations/{id_org}/members/{id_member}/all") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getOrganizationsMembersCardsByIdOrgByIdMember()
#
# GET /organizations/{idOrg}/members/{idMember}/cards
# operationId: getOrganizationsMembersCardsByIdOrgByIdMember
export def "organizations-members-cards get-by-org" [
  id_org: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --attachments: string # A boolean value or "cover" for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --members: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string # true or false
  --checklists: string # One of: all or none (default: none)
  --board: string # true or false
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, desc, closed, idOrganization, pinned, url and prefs)
  --list: string # true or false
  --list-fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --filter: string # One of: all, closed, none, open or visible (default: visible)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "attachments" $attachments "scalar") (serialize-qp "attachment_fields" $attachment_fields "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "checkItemStates" $check_item_states "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "board" $board "scalar") (serialize-qp "board_fields" $board_fields "scalar") (serialize-qp "list" $list "scalar") (serialize-qp "list_fields" $list_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org), id_member: (encode-path-segment $id_member)} | format pattern "/organizations/{id_org}/members/{id_member}/cards") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateOrganizationsMembersDeactivatedByIdOrgByIdMember()
#
# PUT /organizations/{idOrg}/members/{idMember}/deactivated
# operationId: updateOrganizationsMembersDeactivatedByIdOrgByIdMember
export def "organizations-members-deactivated update-by-org" [
  id_org: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org), id_member: (encode-path-segment $id_member)} | format pattern "/organizations/{id_org}/members/{id_member}/deactivated") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getOrganizationsMembersInvitedByIdOrg()
#
# GET /organizations/{idOrg}/membersInvited
# operationId: getOrganizationsMembersInvitedByIdOrg
export def "organizations-members-invited list" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/membersInvited") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getOrganizationsMembersInvitedByIdOrgByField()
#
# GET /organizations/{idOrg}/membersInvited/{field}
# operationId: getOrganizationsMembersInvitedByIdOrgByField
export def "organizations-members-invited get-by-org" [
  id_org: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org), field: (encode-path-segment $field)} | format pattern "/organizations/{id_org}/membersInvited/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getOrganizationsMembershipsByIdOrg()
#
# GET /organizations/{idOrg}/memberships
# operationId: getOrganizationsMembershipsByIdOrg
export def "organizations-memberships list" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: all)
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/memberships") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getOrganizationsMembershipsByIdOrgByIdMembership()
#
# GET /organizations/{idOrg}/memberships/{idMembership}
# operationId: getOrganizationsMembershipsByIdOrgByIdMembership
export def "organizations-memberships get-by-org" [
  id_org: string
  id_membership: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org), id_membership: (encode-path-segment $id_membership)} | format pattern "/organizations/{id_org}/memberships/{id_membership}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateOrganizationsMembershipsByIdOrgByIdMembership()
#
# PUT /organizations/{idOrg}/memberships/{idMembership}
# operationId: updateOrganizationsMembershipsByIdOrgByIdMembership
export def "organizations-memberships update-by-org" [
  id_org: string
  id_membership: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username
  --type: string # One of: admin, normal or observer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org), id_membership: (encode-path-segment $id_membership)} | format pattern "/organizations/{id_org}/memberships/{id_membership}") $qp)
  let req_body = {"member_fields": $member_fields, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateOrganizationsNameByIdOrg()
#
# PUT /organizations/{idOrg}/name
# operationId: updateOrganizationsNameByIdOrg
export def "organizations-name update-by-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # A string with a length of at least 3. Only lowercase letters, underscores, and numbers are allowed. Must be unique.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/name") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteOrganizationsPrefsAssociatedDomainByIdOrg()
#
# DELETE /organizations/{idOrg}/prefs/associatedDomain
# operationId: deleteOrganizationsPrefsAssociatedDomainByIdOrg
export def "organizations-prefs-associated-domain delete-by-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/prefs/associatedDomain") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateOrganizationsPrefsAssociatedDomainByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/associatedDomain
# operationId: updateOrganizationsPrefsAssociatedDomainByIdOrg
export def "organizations-prefs-associated-domain update-by-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # The google apps domain to link this org to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/prefs/associatedDomain") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateOrganizationsPrefsBoardVisibilityRestrictOrgByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/boardVisibilityRestrict/org
# operationId: updateOrganizationsPrefsBoardVisibilityRestrictOrgByIdOrg
export def "organizations-prefs-board-visibility-restrict-org update" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # One of: admin, none or org
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/prefs/boardVisibilityRestrict/org") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateOrganizationsPrefsBoardVisibilityRestrictPrivateByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/boardVisibilityRestrict/private
# operationId: updateOrganizationsPrefsBoardVisibilityRestrictPrivateByIdOrg
export def "organizations-prefs-board-visibility-restrict-private update-by-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # One of: admin, none or org
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/prefs/boardVisibilityRestrict/private") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateOrganizationsPrefsBoardVisibilityRestrictPublicByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/boardVisibilityRestrict/public
# operationId: updateOrganizationsPrefsBoardVisibilityRestrictPublicByIdOrg
export def "organizations-prefs-board-visibility-restrict-public update-by-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # One of: admin, none or org
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/prefs/boardVisibilityRestrict/public") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateOrganizationsPrefsExternalMembersDisabledByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/externalMembersDisabled
# operationId: updateOrganizationsPrefsExternalMembersDisabledByIdOrg
export def "organizations-prefs-external-members-disabled update-by-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/prefs/externalMembersDisabled") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateOrganizationsPrefsGoogleAppsVersionByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/googleAppsVersion
# operationId: updateOrganizationsPrefsGoogleAppsVersionByIdOrg
export def "organizations-prefs-google-apps-version update-by-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a number from 1 to 2
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/prefs/googleAppsVersion") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteOrganizationsPrefsOrgInviteRestrictByIdOrg()
#
# DELETE /organizations/{idOrg}/prefs/orgInviteRestrict
# operationId: deleteOrganizationsPrefsOrgInviteRestrictByIdOrg
export def "organizations-prefs-org-invite-restrict delete" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # An email address with optional expansion tokens
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/prefs/orgInviteRestrict") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateOrganizationsPrefsOrgInviteRestrictByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/orgInviteRestrict
# operationId: updateOrganizationsPrefsOrgInviteRestrictByIdOrg
export def "organizations-prefs-org-invite-restrict update" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # An email address with optional expansion tokens
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/prefs/orgInviteRestrict") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateOrganizationsPrefsPermissionLevelByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/permissionLevel
# operationId: updateOrganizationsPrefsPermissionLevelByIdOrg
export def "organizations-prefs-permission-level update-by-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # One of: private or public
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/prefs/permissionLevel") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateOrganizationsWebsiteByIdOrg()
#
# PUT /organizations/{idOrg}/website
# operationId: updateOrganizationsWebsiteByIdOrg
export def "organizations-website update-by-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # A URL starting with http:// or https:// or null
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org)} | format pattern "/organizations/{id_org}/website") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getOrganizationsByIdOrgByField()
#
# GET /organizations/{idOrg}/{field}
# operationId: getOrganizationsByIdOrgByField
export def "organizations get-by-org" [
  id_org: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: (encode-path-segment $id_org), field: (encode-path-segment $field)} | format pattern "/organizations/{id_org}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getSearch()
#
# GET /search
# operationId: getSearch
export def "search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # a string with a length from 1 to 16384
  --id-boards: string # A comma-separated list of objectIds, 24-character hex strings (default: mine)
  --id-organizations: string # A comma-separated list of objectIds, 24-character hex strings
  --id-cards: string # A comma-separated list of objectIds, 24-character hex strings
  --model-types: string # all or a comma-separated list of: actions, boards, cards, members or organizations (default: all)
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name and idOrganization)
  --boards-limit: string # a number from 1 to 1000 (default: 10)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --cards-limit: string # a number from 1 to 1000 (default: 10)
  --cards-page: string # a number from 0 to 100 (default: 0)
  --card-board: string # true or false
  --card-list: string # true or false
  --card-members: string # true or false
  --card-stickers: string # true or false
  --card-attachments: string # A boolean value or "cover" for only card cover attachments
  --organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: name and displayName)
  --organizations-limit: string # a number from 1 to 1000 (default: 10)
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials, username and confirmed)
  --members-limit: string # a number from 1 to 1000 (default: 10)
  --partial: string # true or false
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "idBoards" $id_boards "scalar") (serialize-qp "idOrganizations" $id_organizations "scalar") (serialize-qp "idCards" $id_cards "scalar") (serialize-qp "modelTypes" $model_types "scalar") (serialize-qp "board_fields" $board_fields "scalar") (serialize-qp "boards_limit" $boards_limit "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "cards_limit" $cards_limit "scalar") (serialize-qp "cards_page" $cards_page "scalar") (serialize-qp "card_board" $card_board "scalar") (serialize-qp "card_list" $card_list "scalar") (serialize-qp "card_members" $card_members "scalar") (serialize-qp "card_stickers" $card_stickers "scalar") (serialize-qp "card_attachments" $card_attachments "scalar") (serialize-qp "organization_fields" $organization_fields "scalar") (serialize-qp "organizations_limit" $organizations_limit "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "members_limit" $members_limit "scalar") (serialize-qp "partial" $partial "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getSearchMembers()
#
# GET /search/members
# operationId: getSearchMembers
export def "search-members get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # a string with a length from 1 to 16384
  --limit: string # a number from 1 to 20 (default: 8)
  --id-board: string # An id, or null
  --id-organization: string # An id, or null
  --only-org-members: string # A boolean
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "idBoard" $id_board "scalar") (serialize-qp "idOrganization" $id_organization "scalar") (serialize-qp "onlyOrgMembers" $only_org_members "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addSessions()
#
# POST /sessions
# operationId: addSessions
export def "sessions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --id-board: string # The id of the board you're viewing. Boards with no viewers will not get updates about members' statuses.
  --status: string # One of: active, disconnected or idle
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sessions" $qp)
  let req_body = {"idBoard": $id_board, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getSessionsSocket()
#
# GET /sessions/socket
# operationId: getSessionsSocket
export def "sessions-socket get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sessions/socket" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateSessionsByIdSession()
#
# PUT /sessions/{idSession}
# operationId: updateSessionsByIdSession
export def "sessions update" [
  id_session: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --id-board: string # The id of the board you're viewing. Boards with no viewers will not get updates about members' statuses.
  --status: string # One of: active, disconnected or idle
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_session: (encode-path-segment $id_session)} | format pattern "/sessions/{id_session}") $qp)
  let req_body = {"idBoard": $id_board, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateSessionsStatusByIdSession()
#
# PUT /sessions/{idSession}/status
# operationId: updateSessionsStatusByIdSession
export def "sessions-status update" [
  id_session: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # One of: active, disconnected or idle
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_session: (encode-path-segment $id_session)} | format pattern "/sessions/{id_session}/status") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteTokensByToken()
#
# DELETE /tokens/{token}
# operationId: deleteTokensByToken
export def "tokens delete" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/tokens/{token_arg}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getTokensByToken()
#
# GET /tokens/{token}
# operationId: getTokensByToken
export def "tokens get" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: dateCreated, dateExpires, idMember, identifier or permissions (default: all)
  --webhooks: string # true or false
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "webhooks" $webhooks "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/tokens/{token_arg}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getTokensMemberByToken()
#
# GET /tokens/{token}/member
# operationId: getTokensMemberByToken
export def "tokens-member get" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/tokens/{token_arg}/member") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getTokensMemberByTokenByField()
#
# GET /tokens/{token}/member/{field}
# operationId: getTokensMemberByTokenByField
export def "tokens-member get-by" [
  token_arg: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg), field: (encode-path-segment $field)} | format pattern "/tokens/{token_arg}/member/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getTokensWebhooksByToken()
#
# GET /tokens/{token}/webhooks
# operationId: getTokensWebhooksByToken
export def "tokens-webhooks get" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/tokens/{token_arg}/webhooks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addTokensWebhooksByToken()
#
# POST /tokens/{token}/webhooks
# operationId: addTokensWebhooksByToken
export def "tokens-webhooks create" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --callback-url: string # A valid URL that is reachable with a HEAD request
  --description: string # a string with a length from 0 to 16384
  --id-model: string # id of the model to be monitored
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/tokens/{token_arg}/webhooks") $qp)
  let req_body = {"callbackURL": $callback_url, "description": $description, "idModel": $id_model} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateTokensWebhooksByToken()
#
# PUT /tokens/{token}/webhooks
# operationId: updateTokensWebhooksByToken
export def "tokens-webhooks update" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --callback-url: string # A valid URL that is reachable with a HEAD request
  --description: string # a string with a length from 0 to 16384
  --id-model: string # id of the model to be monitored
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/tokens/{token_arg}/webhooks") $qp)
  let req_body = {"callbackURL": $callback_url, "description": $description, "idModel": $id_model} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteTokensWebhooksByTokenByIdWebhook()
#
# DELETE /tokens/{token}/webhooks/{idWebhook}
# operationId: deleteTokensWebhooksByTokenByIdWebhook
export def "tokens-webhooks delete-by" [
  token_arg: string
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg), id_webhook: (encode-path-segment $id_webhook)} | format pattern "/tokens/{token_arg}/webhooks/{id_webhook}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getTokensWebhooksByTokenByIdWebhook()
#
# GET /tokens/{token}/webhooks/{idWebhook}
# operationId: getTokensWebhooksByTokenByIdWebhook
export def "tokens-webhooks get-by" [
  token_arg: string
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg), id_webhook: (encode-path-segment $id_webhook)} | format pattern "/tokens/{token_arg}/webhooks/{id_webhook}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getTokensByTokenByField()
#
# GET /tokens/{token}/{field}
# operationId: getTokensByTokenByField
export def "tokens get-by" [
  token_arg: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg), field: (encode-path-segment $field)} | format pattern "/tokens/{token_arg}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getTypesById()
#
# GET /types/{id}
# operationId: getTypesById
export def "types get" [
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
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/types/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# addWebhooks()
#
# POST /webhooks
# operationId: addWebhooks
export def "webhooks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --active: string # true or false
  --callback-url: string # A valid URL that is reachable with a HEAD request
  --description: string # a string with a length from 0 to 16384
  --id-model: string # id of the model that should be hooked
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks" $qp)
  let req_body = {"active": $active, "callbackURL": $callback_url, "description": $description, "idModel": $id_model} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateWebhooks()
#
# PUT /webhooks/
# operationId: updateWebhooks
export def "webhooks update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --active: string # true or false
  --callback-url: string # A valid URL that is reachable with a HEAD request
  --description: string # a string with a length from 0 to 16384
  --id-model: string # id of the model that should be hooked
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks/" $qp)
  let req_body = {"active": $active, "callbackURL": $callback_url, "description": $description, "idModel": $id_model} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# deleteWebhooksByIdWebhook()
#
# DELETE /webhooks/{idWebhook}
# operationId: deleteWebhooksByIdWebhook
export def "webhooks delete" [
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: (encode-path-segment $id_webhook)} | format pattern "/webhooks/{id_webhook}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getWebhooksByIdWebhook()
#
# GET /webhooks/{idWebhook}
# operationId: getWebhooksByIdWebhook
export def "webhooks get" [
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: (encode-path-segment $id_webhook)} | format pattern "/webhooks/{id_webhook}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# updateWebhooksByIdWebhook()
#
# PUT /webhooks/{idWebhook}
# operationId: updateWebhooksByIdWebhook
export def "webhooks update-by-idWebhook" [
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --active: string # true or false
  --callback-url: string # A valid URL that is reachable with a HEAD request
  --description: string # a string with a length from 0 to 16384
  --id-model: string # id of the model that should be hooked
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: (encode-path-segment $id_webhook)} | format pattern "/webhooks/{id_webhook}") $qp)
  let req_body = {"active": $active, "callbackURL": $callback_url, "description": $description, "idModel": $id_model} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateWebhooksActiveByIdWebhook()
#
# PUT /webhooks/{idWebhook}/active
# operationId: updateWebhooksActiveByIdWebhook
export def "webhooks-active update" [
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: (encode-path-segment $id_webhook)} | format pattern "/webhooks/{id_webhook}/active") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateWebhooksCallbackURLByIdWebhook()
#
# PUT /webhooks/{idWebhook}/callbackURL
# operationId: updateWebhooksCallbackURLByIdWebhook
export def "webhooks-callback-url update" [
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # A valid URL that is reachable with a HEAD request
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: (encode-path-segment $id_webhook)} | format pattern "/webhooks/{id_webhook}/callbackURL") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateWebhooksDescriptionByIdWebhook()
#
# PUT /webhooks/{idWebhook}/description
# operationId: updateWebhooksDescriptionByIdWebhook
export def "webhooks-description update" [
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: (encode-path-segment $id_webhook)} | format pattern "/webhooks/{id_webhook}/description") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# updateWebhooksIdModelByIdWebhook()
#
# PUT /webhooks/{idWebhook}/idModel
# operationId: updateWebhooksIdModelByIdWebhook
export def "webhooks-id-model update" [
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  --value: string # id of the model to be monitored
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: (encode-path-segment $id_webhook)} | format pattern "/webhooks/{id_webhook}/idModel") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# getWebhooksByIdWebhookByField()
#
# GET /webhooks/{idWebhook}/{field}
# operationId: getWebhooksByIdWebhookByField
export def "webhooks get-by" [
  id_webhook: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: (encode-path-segment $id_webhook), field: (encode-path-segment $field)} | format pattern "/webhooks/{id_webhook}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
