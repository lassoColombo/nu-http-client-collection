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
    "query-key" => { {headers: {}, query: $"key=($token_val)"} }
    "query-token" => { {headers: {}, query: $"token=($token_val)"} }
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

def base-url-completer [] { ["https://trello.com/1"] }
def auth-scheme-completer [] { ["query-key" "query-token"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: $id_action} | format pattern "/actions/{id_action}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getActionsByIdAction()
#
# GET /actions/{idAction}
# operationId: getActionsByIdAction
export def "actions list" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --display: string #  true or false
  --entities: string #  true or false
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --member: string #  true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --member-creator: string #  true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "display" $display "scalar") (serialize-qp "entities" $entities "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "memberCreator" $member_creator "scalar") (serialize-qp "memberCreator_fields" $member_creator_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: $id_action} | format pattern "/actions/{id_action}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --text: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: $id_action} | format pattern "/actions/{id_action}") $qp)
  let body = {"text": $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getActionsBoardByIdAction()
#
# GET /actions/{idAction}/board
# operationId: getActionsBoardByIdAction
export def "actions-board list" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: $id_action} | format pattern "/actions/{id_action}/board") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getActionsBoardByIdActionByField()
#
# GET /actions/{idAction}/board/{field}
# operationId: getActionsBoardByIdActionByField
export def "actions-board get" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: $id_action, field: $field} | format pattern "/actions/{id_action}/board/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getActionsCardByIdAction()
#
# GET /actions/{idAction}/card
# operationId: getActionsCardByIdAction
export def "actions-card list" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: $id_action} | format pattern "/actions/{id_action}/card") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getActionsCardByIdActionByField()
#
# GET /actions/{idAction}/card/{field}
# operationId: getActionsCardByIdActionByField
export def "actions-card get" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: $id_action, field: $field} | format pattern "/actions/{id_action}/card/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: $id_action} | format pattern "/actions/{id_action}/display") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: $id_action} | format pattern "/actions/{id_action}/entities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getActionsListByIdAction()
#
# GET /actions/{idAction}/list
# operationId: getActionsListByIdAction
export def "actions-list list" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: $id_action} | format pattern "/actions/{id_action}/list") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getActionsListByIdActionByField()
#
# GET /actions/{idAction}/list/{field}
# operationId: getActionsListByIdActionByField
export def "actions-list get" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: $id_action, field: $field} | format pattern "/actions/{id_action}/list/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getActionsMemberByIdAction()
#
# GET /actions/{idAction}/member
# operationId: getActionsMemberByIdAction
export def "actions-member list" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: $id_action} | format pattern "/actions/{id_action}/member") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getActionsMemberByIdActionByField()
#
# GET /actions/{idAction}/member/{field}
# operationId: getActionsMemberByIdActionByField
export def "actions-member get" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: $id_action, field: $field} | format pattern "/actions/{id_action}/member/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getActionsMemberCreatorByIdAction()
#
# GET /actions/{idAction}/memberCreator
# operationId: getActionsMemberCreatorByIdAction
export def "actions-member-creator list" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: $id_action} | format pattern "/actions/{id_action}/memberCreator") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getActionsMemberCreatorByIdActionByField()
#
# GET /actions/{idAction}/memberCreator/{field}
# operationId: getActionsMemberCreatorByIdActionByField
export def "actions-member-creator get" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: $id_action, field: $field} | format pattern "/actions/{id_action}/memberCreator/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getActionsOrganizationByIdAction()
#
# GET /actions/{idAction}/organization
# operationId: getActionsOrganizationByIdAction
export def "actions-organization list" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: $id_action} | format pattern "/actions/{id_action}/organization") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getActionsOrganizationByIdActionByField()
#
# GET /actions/{idAction}/organization/{field}
# operationId: getActionsOrganizationByIdActionByField
export def "actions-organization get" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: $id_action, field: $field} | format pattern "/actions/{id_action}/organization/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: $id_action} | format pattern "/actions/{id_action}/text") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getActionsByIdActionByField()
#
# GET /actions/{idAction}/{field}
# operationId: getActionsByIdActionByField
export def "actions get" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_action: $id_action, field: $field} | format pattern "/actions/{id_action}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --urls: string # list of API v1 GET routes, not including the version prefix
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "urls" $urls "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/batch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --closed: string #  true or false
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
  --prefs-calendar-feed-enabled: string #  true or false
  --prefs-card-aging: string # One of: pirate or regular
  --prefs-card-covers: string #  true or false
  --prefs-comments: string # One of: disabled, members, observers, org or public
  --prefs-invitations: string # One of: admins or members
  --prefs-permission-level: string # One of: org, private or public
  --prefs-self-join: string #  true or false
  --prefs-voting: string # One of: disabled, members, observers, org or public
  --prefs-background: string # a string with a length from 0 to 16384
  --prefs-card-aging: string # One of: pirate or regular
  --prefs-card-covers: string #  true or false
  --prefs-comments: string # One of: disabled, members, observers, org or public
  --prefs-invitations: string # One of: admins or members
  --prefs-permission-level: string # One of: org, private or public
  --prefs-self-join: string #  true or false
  --prefs-voting: string # One of: disabled, members, observers, org or public
  --subscribed: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boards" $qp)
  let body = {"closed": $closed, "desc": $desc, "idBoardSource": $id_board_source, "idOrganization": $id_organization, "keepFromSource": $keep_from_source, "labelNames/blue": $label_names_blue, "labelNames/green": $label_names_green, "labelNames/orange": $label_names_orange, "labelNames/purple": $label_names_purple, "labelNames/red": $label_names_red, "labelNames/yellow": $label_names_yellow, "name": $name, "powerUps": $power_ups, "prefs/background": $prefs_background, "prefs/calendarFeedEnabled": $prefs_calendar_feed_enabled, "prefs/cardAging": $prefs_card_aging, "prefs/cardCovers": $prefs_card_covers, "prefs/comments": $prefs_comments, "prefs/invitations": $prefs_invitations, "prefs/permissionLevel": $prefs_permission_level, "prefs/selfJoin": $prefs_self_join, "prefs/voting": $prefs_voting, "prefs_background": $prefs_background, "prefs_cardAging": $prefs_card_aging, "prefs_cardCovers": $prefs_card_covers, "prefs_comments": $prefs_comments, "prefs_invitations": $prefs_invitations, "prefs_permissionLevel": $prefs_permission_level, "prefs_selfJoin": $prefs_self_join, "prefs_voting": $prefs_voting, "subscribed": $subscribed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getBoardsByIdBoard()
#
# GET /boards/{idBoard}
# operationId: getBoardsByIdBoard
export def "boards list" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string #  true or false
  --actions-display: string #  true or false
  --actions-format: string # One of: count, list or minimal (default: list)
  --actions-since: string # A date, null or lastView
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --action-member: string #  true or false
  --action-member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --action-member-creator: string #  true or false
  --action-member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --cards: string # One of: all, closed, none, open or visible (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --card-attachments: string # A boolean value or &quot;cover&quot; for only card cover attachments
  --card-attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --card-checklists: string # One of: all or none (default: none)
  --card-stickers: string #  true or false
  --board-stars: string # One of: mine or none (default: none)
  --labels: string # One of: all or none (default: none)
  --label-fields: string # all or a comma-separated list of: color, idBoard, name or uses (default: all)
  --labels-limit: string # a number from 0 to 1000 (default: 50)
  --lists: string # One of: all, closed, none or open (default: none)
  --list-fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --memberships: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: none)
  --memberships-member: string #  true or false
  --memberships-member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --members: string # One of: admins, all, none, normal or owners (default: none)
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, initials, fullName, username and confirmed)
  --members-invited: string # One of: admins, all, none, normal or owners (default: none)
  --members-invited-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, initials, fullName and username)
  --checklists: string # One of: all or none (default: none)
  --checklist-fields: string # all or a comma-separated list of: idBoard, idCard, name or pos (default: all)
  --organization: string #  true or false
  --organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: name and displayName)
  --organization-memberships: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: none)
  --my-prefs: string #  true or false
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, desc, descData, closed, idOrganization, pinned, url, shortUrl, prefs and labelNames)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "actions_entities" $actions_entities "scalar") (serialize-qp "actions_display" $actions_display "scalar") (serialize-qp "actions_format" $actions_format "scalar") (serialize-qp "actions_since" $actions_since "scalar") (serialize-qp "actions_limit" $actions_limit "scalar") (serialize-qp "action_fields" $action_fields "scalar") (serialize-qp "action_member" $action_member "scalar") (serialize-qp "action_member_fields" $action_member_fields "scalar") (serialize-qp "action_memberCreator" $action_member_creator "scalar") (serialize-qp "action_memberCreator_fields" $action_member_creator_fields "scalar") (serialize-qp "cards" $cards "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "card_attachments" $card_attachments "scalar") (serialize-qp "card_attachment_fields" $card_attachment_fields "scalar") (serialize-qp "card_checklists" $card_checklists "scalar") (serialize-qp "card_stickers" $card_stickers "scalar") (serialize-qp "boardStars" $board_stars "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "label_fields" $label_fields "scalar") (serialize-qp "labels_limit" $labels_limit "scalar") (serialize-qp "lists" $lists "scalar") (serialize-qp "list_fields" $list_fields "scalar") (serialize-qp "memberships" $memberships "scalar") (serialize-qp "memberships_member" $memberships_member "scalar") (serialize-qp "memberships_member_fields" $memberships_member_fields "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "membersInvited" $members_invited "scalar") (serialize-qp "membersInvited_fields" $members_invited_fields "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "checklist_fields" $checklist_fields "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "organization_fields" $organization_fields "scalar") (serialize-qp "organization_memberships" $organization_memberships "scalar") (serialize-qp "myPrefs" $my_prefs "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --closed: string #  true or false
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
  --prefs-calendar-feed-enabled: string #  true or false
  --prefs-card-aging: string # One of: pirate or regular
  --prefs-card-covers: string #  true or false
  --prefs-comments: string # One of: disabled, members, observers, org or public
  --prefs-invitations: string # One of: admins or members
  --prefs-permission-level: string # One of: org, private or public
  --prefs-self-join: string #  true or false
  --prefs-voting: string # One of: disabled, members, observers, org or public
  --prefs-background: string # a string with a length from 0 to 16384
  --prefs-card-aging: string # One of: pirate or regular
  --prefs-card-covers: string #  true or false
  --prefs-comments: string # One of: disabled, members, observers, org or public
  --prefs-invitations: string # One of: admins or members
  --prefs-permission-level: string # One of: org, private or public
  --prefs-self-join: string #  true or false
  --prefs-voting: string # One of: disabled, members, observers, org or public
  --subscribed: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}") $qp)
  let body = {"closed": $closed, "desc": $desc, "idBoardSource": $id_board_source, "idOrganization": $id_organization, "keepFromSource": $keep_from_source, "labelNames/blue": $label_names_blue, "labelNames/green": $label_names_green, "labelNames/orange": $label_names_orange, "labelNames/purple": $label_names_purple, "labelNames/red": $label_names_red, "labelNames/yellow": $label_names_yellow, "name": $name, "powerUps": $power_ups, "prefs/background": $prefs_background, "prefs/calendarFeedEnabled": $prefs_calendar_feed_enabled, "prefs/cardAging": $prefs_card_aging, "prefs/cardCovers": $prefs_card_covers, "prefs/comments": $prefs_comments, "prefs/invitations": $prefs_invitations, "prefs/permissionLevel": $prefs_permission_level, "prefs/selfJoin": $prefs_self_join, "prefs/voting": $prefs_voting, "prefs_background": $prefs_background, "prefs_cardAging": $prefs_card_aging, "prefs_cardCovers": $prefs_card_covers, "prefs_comments": $prefs_comments, "prefs_invitations": $prefs_invitations, "prefs_permissionLevel": $prefs_permission_level, "prefs_selfJoin": $prefs_self_join, "prefs_voting": $prefs_voting, "subscribed": $subscribed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: string #  true or false
  --display: string #  true or false
  --filter: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization (default: all)
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --limit: string # a number from 0 to 1000 (default: 50)
  --format: string # One of: count, list or minimal (default: list)
  --since: string # A date, null or lastView
  --before: string # A date, or null
  --page: string # Page * limit must be less than 1000 (default: 0)
  --id-models: string # Only return actions related to these model ids
  --member: string #  true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --member-creator: string #  true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entities" $entities "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "idModels" $id_models "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "memberCreator" $member_creator "scalar") (serialize-qp "memberCreator_fields" $member_creator_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/actions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: mine or none (default: mine)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/boardStars") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/calendarKey/generate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getBoardsCardsByIdBoard()
#
# GET /boards/{idBoard}/cards
# operationId: getBoardsCardsByIdBoard
export def "boards-cards get-by-idBoard" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --attachments: string # A boolean value or &quot;cover&quot; for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --stickers: string #  true or false
  --members: string #  true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string #  true or false
  --checklists: string # One of: all or none (default: none)
  --limit: string # a number from 1 to 1000
  --since: string # A date, or null
  --before: string # A date, or null
  --filter: string # One of: all, closed, none, open or visible (default: visible)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "attachments" $attachments "scalar") (serialize-qp "attachment_fields" $attachment_fields "scalar") (serialize-qp "stickers" $stickers "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "checkItemStates" $check_item_states "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/cards") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getBoardsCardsByIdBoardByFilter()
#
# GET /boards/{idBoard}/cards/{filter}
# operationId: getBoardsCardsByIdBoardByFilter
export def "boards-cards get-by-idBoard-filter" [
  id_board: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board, filter: $filter} | format pattern "/boards/{id_board}/cards/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getBoardsCardsByIdBoardByIdCard()
#
# GET /boards/{idBoard}/cards/{idCard}
# operationId: getBoardsCardsByIdBoardByIdCard
export def "boards-cards get-by-idBoard-idCard" [
  id_board: string
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachments: string # A boolean value or &quot;cover&quot; for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string #  true or false
  --actions-display: string #  true or false
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --action-member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --members: string #  true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, initials, fullName and username)
  --check-item-states: string #  true or false
  --check-item-state-fields: string # all or a comma-separated list of: idCheckItem or state (default: all)
  --labels: string #  true or false
  --checklists: string # One of: all or none (default: none)
  --checklist-fields: string # all or a comma-separated list of: idBoard, idCard, name or pos (default: all)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attachments" $attachments "scalar") (serialize-qp "attachment_fields" $attachment_fields "scalar") (serialize-qp "actions" $actions "scalar") (serialize-qp "actions_entities" $actions_entities "scalar") (serialize-qp "actions_display" $actions_display "scalar") (serialize-qp "actions_limit" $actions_limit "scalar") (serialize-qp "action_fields" $action_fields "scalar") (serialize-qp "action_memberCreator_fields" $action_member_creator_fields "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "checkItemStates" $check_item_states "scalar") (serialize-qp "checkItemState_fields" $check_item_state_fields "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "checklist_fields" $checklist_fields "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board, id_card: $id_card} | format pattern "/boards/{id_board}/cards/{id_card}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --cards: string # One of: all, closed, none, open or visible (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --check-items: string # One of: all or none (default: all)
  --check-item-fields: string # all or a comma-separated list of: name, nameData, pos, state or type (default: name, nameData, pos and state)
  --filter: string # One of: all or none (default: all)
  --fields: string # all or a comma-separated list of: idBoard, idCard, name or pos (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cards" $cards "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "checkItems" $check_items "scalar") (serialize-qp "checkItem_fields" $check_item_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/checklists") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --name: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/checklists") $qp)
  let body = {"name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/closed") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: string # A valid tag for subscribing
  --ix-last-update: string # a number from -1 to Infinity
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tags" $tags "scalar") (serialize-qp "ixLastUpdate" $ix_last_update "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/deltas") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/desc") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/emailKey/generate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/idOrganization") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/labelNames/blue") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/labelNames/green") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/labelNames/orange") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/labelNames/purple") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/labelNames/red") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/labelNames/yellow") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getBoardsLabelsByIdBoard()
#
# GET /boards/{idBoard}/labels
# operationId: getBoardsLabelsByIdBoard
export def "boards-labels list" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: color, idBoard, name or uses (default: all)
  --limit: string # a number from 0 to 1000 (default: 50)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/labels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --color: string # A valid label color or null
  --name: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/labels") $qp)
  let body = {"color": $color, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getBoardsLabelsByIdBoardByIdLabel()
#
# GET /boards/{idBoard}/labels/{idLabel}
# operationId: getBoardsLabelsByIdBoardByIdLabel
export def "boards-labels get" [
  id_board: string
  id_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: color, idBoard, name or uses (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board, id_label: $id_label} | format pattern "/boards/{id_board}/labels/{id_label}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getBoardsListsByIdBoard()
#
# GET /boards/{idBoard}/lists
# operationId: getBoardsListsByIdBoard
export def "boards-lists list" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cards: string # One of: all, closed, none, open or visible (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --filter: string # One of: all, closed, none or open (default: open)
  --fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cards" $cards "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/lists") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --name: string # a string with a length from 1 to 16384
  --pos: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/lists") $qp)
  let body = {"name": $name, "pos": $pos} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getBoardsListsByIdBoardByFilter()
#
# GET /boards/{idBoard}/lists/{filter}
# operationId: getBoardsListsByIdBoardByFilter
export def "boards-lists get" [
  id_board: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board, filter: $filter} | format pattern "/boards/{id_board}/lists/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/markAsViewed") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getBoardsMembersByIdBoard()
#
# GET /boards/{idBoard}/members
# operationId: getBoardsMembersByIdBoard
export def "boards-members list" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: admins, all, none, normal or owners (default: all)
  --fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --activity: string # true or false ; works for premium organizations only.
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "activity" $activity "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateBoardsMembersByIdBoard()
#
# PUT /boards/{idBoard}/members
# operationId: updateBoardsMembersByIdBoard
export def "boards-members update-by-idBoard" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --email: string # An email address
  --full-name: string # A string with a length of at least 1.  Cannot begin or end with a space.
  --type: string # One of: admin, normal or observer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/members") $qp)
  let body = {"email": $email, "fullName": $full_name, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getBoardsMembersByIdBoardByFilter()
#
# GET /boards/{idBoard}/members/{filter}
# operationId: getBoardsMembersByIdBoardByFilter
export def "boards-members get" [
  id_board: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board, filter: $filter} | format pattern "/boards/{id_board}/members/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# deleteBoardsMembersByIdBoardByIdMember()
#
# DELETE /boards/{idBoard}/members/{idMember}
# operationId: deleteBoardsMembersByIdBoardByIdMember
export def "boards-members delete" [
  id_board: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board, id_member: $id_member} | format pattern "/boards/{id_board}/members/{id_member}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateBoardsMembersByIdBoardByIdMember()
#
# PUT /boards/{idBoard}/members/{idMember}
# operationId: updateBoardsMembersByIdBoardByIdMember
export def "boards-members update-by-idBoard-idMember" [
  id_board: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --email: string # An email address
  --full-name: string # A string with a length of at least 1.  Cannot begin or end with a space.
  --type: string # One of: admin, normal or observer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board, id_member: $id_member} | format pattern "/boards/{id_board}/members/{id_member}") $qp)
  let body = {"email": $email, "fullName": $full_name, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getBoardsMembersCardsByIdBoardByIdMember()
#
# GET /boards/{idBoard}/members/{idMember}/cards
# operationId: getBoardsMembersCardsByIdBoardByIdMember
export def "boards-members-cards get" [
  id_board: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --attachments: string # A boolean value or &quot;cover&quot; for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --members: string #  true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string #  true or false
  --checklists: string # One of: all or none (default: none)
  --board: string #  true or false
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, desc, closed, idOrganization, pinned, url and prefs)
  --list: string #  true or false
  --list-fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --filter: string # One of: all, closed, none, open or visible (default: visible)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "attachments" $attachments "scalar") (serialize-qp "attachment_fields" $attachment_fields "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "checkItemStates" $check_item_states "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "board" $board "scalar") (serialize-qp "board_fields" $board_fields "scalar") (serialize-qp "list" $list "scalar") (serialize-qp "list_fields" $list_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board, id_member: $id_member} | format pattern "/boards/{id_board}/members/{id_member}/cards") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getBoardsMembersInvitedByIdBoard()
#
# GET /boards/{idBoard}/membersInvited
# operationId: getBoardsMembersInvitedByIdBoard
export def "boards-members-invited list" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/membersInvited") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getBoardsMembersInvitedByIdBoardByField()
#
# GET /boards/{idBoard}/membersInvited/{field}
# operationId: getBoardsMembersInvitedByIdBoardByField
export def "boards-members-invited get" [
  id_board: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board, field: $field} | format pattern "/boards/{id_board}/membersInvited/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getBoardsMembershipsByIdBoard()
#
# GET /boards/{idBoard}/memberships
# operationId: getBoardsMembershipsByIdBoard
export def "boards-memberships list" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: all)
  --member: string #  true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/memberships") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getBoardsMembershipsByIdBoardByIdMembership()
#
# GET /boards/{idBoard}/memberships/{idMembership}
# operationId: getBoardsMembershipsByIdBoardByIdMembership
export def "boards-memberships get" [
  id_board: string
  id_membership: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --member: string #  true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board, id_membership: $id_membership} | format pattern "/boards/{id_board}/memberships/{id_membership}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateBoardsMembershipsByIdBoardByIdMembership()
#
# PUT /boards/{idBoard}/memberships/{idMembership}
# operationId: updateBoardsMembershipsByIdBoardByIdMembership
export def "boards-memberships update" [
  id_board: string
  id_membership: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username
  --type: string # One of: admin, normal or observer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board, id_membership: $id_membership} | format pattern "/boards/{id_board}/memberships/{id_membership}") $qp)
  let body = {"member_fields": $member_fields, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/myPrefs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # One of: bottom or top
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/myPrefs/emailPosition") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # An id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/myPrefs/idEmailList") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/myPrefs/showListGuide") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/myPrefs/showSidebar") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/myPrefs/showSidebarActivity") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/myPrefs/showSidebarBoardActions") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/myPrefs/showSidebarMembers") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/name") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getBoardsOrganizationByIdBoard()
#
# GET /boards/{idBoard}/organization
# operationId: getBoardsOrganizationByIdBoard
export def "boards-organization list" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/organization") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getBoardsOrganizationByIdBoardByField()
#
# GET /boards/{idBoard}/organization/{field}
# operationId: getBoardsOrganizationByIdBoardByField
export def "boards-organization get" [
  id_board: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board, field: $field} | format pattern "/boards/{id_board}/organization/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # One of: calendar, cardAging, recap or voting
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/powerUps") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteBoardsPowerUpsByIdBoardByPowerUp()
#
# DELETE /boards/{idBoard}/powerUps/{powerUp}
# operationId: deleteBoardsPowerUpsByIdBoardByPowerUp
export def "boards-power-ups delete" [
  id_board: string
  power_up: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board, power_up: $power_up} | format pattern "/boards/{id_board}/powerUps/{power_up}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # A standard background name, or the id of a custom background
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/prefs/background") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/prefs/calendarFeedEnabled") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # One of: pirate or regular
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/prefs/cardAging") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/prefs/cardCovers") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # One of: disabled, members, observers, org or public
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/prefs/comments") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # One of: admins or members
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/prefs/invitations") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # One of: private or public
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/prefs/permissionLevel") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/prefs/selfJoin") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # One of: disabled, members, observers, org or public
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/prefs/voting") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board} | format pattern "/boards/{id_board}/subscribed") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getBoardsByIdBoardByField()
#
# GET /boards/{idBoard}/{field}
# operationId: getBoardsByIdBoardByField
export def "boards get" [
  id_board: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_board: $id_board, field: $field} | format pattern "/boards/{id_board}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --closed: string #  true or false
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
  --name: string # The name of the new card.  It isn&#39;t required if the name is being copied from provided by a URL, file or card that is being copied.
  --pos: string # A position. top , bottom , or a positive number.
  --subscribed: string #  true or false
  --url-source: string # A URL starting with http:// or https:// or null
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cards" $qp)
  let body = {"closed": $closed, "desc": $desc, "due": $due, "fileSource": $file_source, "idAttachmentCover": $id_attachment_cover, "idBoard": $id_board, "idCardSource": $id_card_source, "idLabels": $id_labels, "idList": $id_list, "idMembers": $id_members, "keepFromSource": $keep_from_source, "labels": $labels, "name": $name, "pos": $pos, "subscribed": $subscribed, "urlSource": $url_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getCardsByIdCard()
#
# GET /cards/{idCard}
# operationId: getCardsByIdCard
export def "cards list" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string #  true or false
  --actions-display: string #  true or false
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --action-member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --attachments: string # A boolean value or &quot;cover&quot; for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --members: string #  true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --members-voted: string #  true or false
  --member-voted-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string #  true or false
  --check-item-state-fields: string # all or a comma-separated list of: idCheckItem or state (default: all)
  --checklists: string # One of: all or none (default: none)
  --checklist-fields: string # all or a comma-separated list of: idBoard, idCard, name or pos (default: all)
  --board: string #  true or false
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, desc, descData, closed, idOrganization, pinned, url and prefs)
  --list: string #  true or false
  --list-fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --stickers: string #  true or false
  --sticker-fields: string # all or a comma-separated list of: image, imageScaled, imageUrl, left, rotate, top or zIndex (default: all)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idBoard, idChecklists, idLabels, idList, idMembers, idShort, idAttachmentCover, manualCoverAttachment, labels, name, pos, shortUrl and url)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "actions_entities" $actions_entities "scalar") (serialize-qp "actions_display" $actions_display "scalar") (serialize-qp "actions_limit" $actions_limit "scalar") (serialize-qp "action_fields" $action_fields "scalar") (serialize-qp "action_memberCreator_fields" $action_member_creator_fields "scalar") (serialize-qp "attachments" $attachments "scalar") (serialize-qp "attachment_fields" $attachment_fields "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "membersVoted" $members_voted "scalar") (serialize-qp "memberVoted_fields" $member_voted_fields "scalar") (serialize-qp "checkItemStates" $check_item_states "scalar") (serialize-qp "checkItemState_fields" $check_item_state_fields "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "checklist_fields" $checklist_fields "scalar") (serialize-qp "board" $board "scalar") (serialize-qp "board_fields" $board_fields "scalar") (serialize-qp "list" $list "scalar") (serialize-qp "list_fields" $list_fields "scalar") (serialize-qp "stickers" $stickers "scalar") (serialize-qp "sticker_fields" $sticker_fields "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --closed: string #  true or false
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
  --name: string # The name of the new card.  It isn&#39;t required if the name is being copied from provided by a URL, file or card that is being copied.
  --pos: string # A position. top , bottom , or a positive number.
  --subscribed: string #  true or false
  --url-source: string # A URL starting with http:// or https:// or null
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}") $qp)
  let body = {"closed": $closed, "desc": $desc, "due": $due, "fileSource": $file_source, "idAttachmentCover": $id_attachment_cover, "idBoard": $id_board, "idCardSource": $id_card_source, "idLabels": $id_labels, "idList": $id_list, "idMembers": $id_members, "keepFromSource": $keep_from_source, "labels": $labels, "name": $name, "pos": $pos, "subscribed": $subscribed, "urlSource": $url_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: string #  true or false
  --display: string #  true or false
  --filter: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization (default: commentCard and updateCard:idList)
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --limit: string # a number from 0 to 1000 (default: 50)
  --format: string # One of: count, list or minimal (default: list)
  --since: string # A date, null or lastView
  --before: string # A date, or null
  --page: string # Page * limit must be less than 1000 (default: 0)
  --id-models: string # Only return actions related to these model ids
  --member: string #  true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --member-creator: string #  true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entities" $entities "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "idModels" $id_models "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "memberCreator" $member_creator "scalar") (serialize-qp "memberCreator_fields" $member_creator_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/actions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --text: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/actions/comments") $qp)
  let body = {"text": $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteCardsActionsCommentsByIdCardByIdAction()
#
# DELETE /cards/{idCard}/actions/{idAction}/comments
# operationId: deleteCardsActionsCommentsByIdCardByIdAction
export def "cards-actions-comments delete" [
  id_card: string
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, id_action: $id_action} | format pattern "/cards/{id_card}/actions/{id_action}/comments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateCardsActionsCommentsByIdCardByIdAction()
#
# PUT /cards/{idCard}/actions/{idAction}/comments
# operationId: updateCardsActionsCommentsByIdCardByIdAction
export def "cards-actions-comments update" [
  id_card: string
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --text: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, id_action: $id_action} | format pattern "/cards/{id_card}/actions/{id_action}/comments") $qp)
  let body = {"text": $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getCardsAttachmentsByIdCard()
#
# GET /cards/{idCard}/attachments
# operationId: getCardsAttachmentsByIdCard
export def "cards-attachments list" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --filter: string # A boolean value or &quot;cover&quot; for only card cover attachments
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/attachments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --file: string # A file
  --mime-type: string # a string with a length from 0 to 256
  --name: string # a string with a length from 0 to 256
  --body-url: string # A URL starting with http:// or https:// or null
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/attachments") $qp)
  let body = {"file": $file, "mimeType": $mime_type, "name": $name, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteCardsAttachmentsByIdCardByIdAttachment()
#
# DELETE /cards/{idCard}/attachments/{idAttachment}
# operationId: deleteCardsAttachmentsByIdCardByIdAttachment
export def "cards-attachments delete" [
  id_card: string
  id_attachment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, id_attachment: $id_attachment} | format pattern "/cards/{id_card}/attachments/{id_attachment}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getCardsAttachmentsByIdCardByIdAttachment()
#
# GET /cards/{idCard}/attachments/{idAttachment}
# operationId: getCardsAttachmentsByIdCardByIdAttachment
export def "cards-attachments get" [
  id_card: string
  id_attachment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, id_attachment: $id_attachment} | format pattern "/cards/{id_card}/attachments/{id_attachment}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getCardsBoardByIdCard()
#
# GET /cards/{idCard}/board
# operationId: getCardsBoardByIdCard
export def "cards-board list" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/board") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getCardsBoardByIdCardByField()
#
# GET /cards/{idCard}/board/{field}
# operationId: getCardsBoardByIdCardByField
export def "cards-board get" [
  id_card: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, field: $field} | format pattern "/cards/{id_card}/board/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: idCheckItem or state (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/checkItemStates") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateCardsChecklistCheckItemByIdCardByIdChecklistCurrentByIdCheckItem()
#
# PUT /cards/{idCard}/checklist/{idChecklistCurrent}/checkItem/{idCheckItem}
# operationId: updateCardsChecklistCheckItemByIdCardByIdChecklistCurrentByIdCheckItem
export def "cards-checklist-check-item update" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --id-checklist: string # An id, or null
  --name: string # a string with a length from 1 to 16384
  --pos: string # A position. top , bottom , or a positive number.
  --state: string # One of: complete, false, incomplete or true
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, id_checklist_current: $id_checklist_current, id_check_item: $id_check_item} | format pattern "/cards/{id_card}/checklist/{id_checklist_current}/checkItem/{id_check_item}") $qp)
  let body = {"idChecklist": $id_checklist, "name": $name, "pos": $pos, "state": $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# addCardsChecklistCheckItemByIdCardByIdChecklist()
#
# POST /cards/{idCard}/checklist/{idChecklist}/checkItem
# operationId: addCardsChecklistCheckItemByIdCardByIdChecklist
export def "cards-checklist-check-item create" [
  id_card: string
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --name: string # a string with a length from 1 to 16384
  --pos: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, id_checklist: $id_checklist} | format pattern "/cards/{id_card}/checklist/{id_checklist}/checkItem") $qp)
  let body = {"name": $name, "pos": $pos} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteCardsChecklistCheckItemByIdCardByIdChecklistByIdCheckItem()
#
# DELETE /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}
# operationId: deleteCardsChecklistCheckItemByIdCardByIdChecklistByIdCheckItem
export def "cards-checklist-check-item delete" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, id_checklist: $id_checklist, id_check_item: $id_check_item} | format pattern "/cards/{id_card}/checklist/{id_checklist}/checkItem/{id_check_item}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# addCardsChecklistCheckItemConvertToCardByIdCardByIdChecklistByIdCheckItem()
#
# POST /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}/convertToCard
# operationId: addCardsChecklistCheckItemConvertToCardByIdCardByIdChecklistByIdCheckItem
export def "cards-checklist-check-item-convert-to-card create" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, id_checklist: $id_checklist, id_check_item: $id_check_item} | format pattern "/cards/{id_card}/checklist/{id_checklist}/checkItem/{id_check_item}/convertToCard") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateCardsChecklistCheckItemNameByIdCardByIdChecklistByIdCheckItem()
#
# PUT /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}/name
# operationId: updateCardsChecklistCheckItemNameByIdCardByIdChecklistByIdCheckItem
export def "cards-checklist-check-item-name update" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, id_checklist: $id_checklist, id_check_item: $id_check_item} | format pattern "/cards/{id_card}/checklist/{id_checklist}/checkItem/{id_check_item}/name") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# updateCardsChecklistCheckItemPosByIdCardByIdChecklistByIdCheckItem()
#
# PUT /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}/pos
# operationId: updateCardsChecklistCheckItemPosByIdCardByIdChecklistByIdCheckItem
export def "cards-checklist-check-item-pos update" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, id_checklist: $id_checklist, id_check_item: $id_check_item} | format pattern "/cards/{id_card}/checklist/{id_checklist}/checkItem/{id_check_item}/pos") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# updateCardsChecklistCheckItemStateByIdCardByIdChecklistByIdCheckItem()
#
# PUT /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}/state
# operationId: updateCardsChecklistCheckItemStateByIdCardByIdChecklistByIdCheckItem
export def "cards-checklist-check-item-state update" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # One of: complete, false, incomplete or true
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, id_checklist: $id_checklist, id_check_item: $id_check_item} | format pattern "/cards/{id_card}/checklist/{id_checklist}/checkItem/{id_check_item}/state") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --cards: string # One of: all, closed, none, open or visible (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --check-items: string # One of: all or none (default: all)
  --check-item-fields: string # all or a comma-separated list of: name, nameData, pos, state or type (default: name, nameData, pos and state)
  --filter: string # One of: all or none (default: all)
  --fields: string # all or a comma-separated list of: idBoard, idCard, name or pos (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cards" $cards "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "checkItems" $check_items "scalar") (serialize-qp "checkItem_fields" $check_item_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/checklists") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --id-checklist-source: string # The id of the source checklist to copy into a new checklist.
  --name: string # a string with a length from 0 to 16384
  --value: string # The id of the checklist to add to the card, or null to create a new one.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/checklists") $qp)
  let body = {"idChecklistSource": $id_checklist_source, "name": $name, "value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteCardsChecklistsByIdCardByIdChecklist()
#
# DELETE /cards/{idCard}/checklists/{idChecklist}
# operationId: deleteCardsChecklistsByIdCardByIdChecklist
export def "cards-checklists delete" [
  id_card: string
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, id_checklist: $id_checklist} | format pattern "/cards/{id_card}/checklists/{id_checklist}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/closed") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/desc") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # A date, or null
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/due") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # Id of the image attachment of this card to use as its cover, or null for no cover
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/idAttachmentCover") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --id-list: string # id of the list that the card should be moved to on the new board
  --value: string # id of the board the card should be moved to
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/idBoard") $qp)
  let body = {"idList": $id_list, "value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # The id of the label to add
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/idLabels") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteCardsIdLabelsByIdCardByIdLabel()
#
# DELETE /cards/{idCard}/idLabels/{idLabel}
# operationId: deleteCardsIdLabelsByIdCardByIdLabel
export def "cards-id-labels delete" [
  id_card: string
  id_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, id_label: $id_label} | format pattern "/cards/{id_card}/idLabels/{id_label}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # id of the list the card should be moved to
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/idList") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # The id of the member to add to the card
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/idMembers") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # The id of the member to add to the card
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/idMembers") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteCardsIdMembersByIdCardByIdMember()
#
# DELETE /cards/{idCard}/idMembers/{idMember}
# operationId: deleteCardsIdMembersByIdCardByIdMember
export def "cards-id-members delete" [
  id_card: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, id_member: $id_member} | format pattern "/cards/{id_card}/idMembers/{id_member}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --color: string # A valid label color or null
  --name: string # a string with a length from 0 to 16384
  --value: string # all or a comma-separated list of: blue, green, orange, purple, red or yellow
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/labels") $qp)
  let body = {"color": $color, "name": $name, "value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --color: string # A valid label color or null
  --name: string # a string with a length from 0 to 16384
  --value: string # all or a comma-separated list of: blue, green, orange, purple, red or yellow
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/labels") $qp)
  let body = {"color": $color, "name": $name, "value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteCardsLabelsByIdCardByColor()
#
# DELETE /cards/{idCard}/labels/{color}
# operationId: deleteCardsLabelsByIdCardByColor
export def "cards-labels delete" [
  id_card: string
  color: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, color: $color} | format pattern "/cards/{id_card}/labels/{color}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getCardsListByIdCard()
#
# GET /cards/{idCard}/list
# operationId: getCardsListByIdCard
export def "cards-list list" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/list") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getCardsListByIdCardByField()
#
# GET /cards/{idCard}/list/{field}
# operationId: getCardsListByIdCardByField
export def "cards-list get" [
  id_card: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, field: $field} | format pattern "/cards/{id_card}/list/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/markAssociatedNotificationsRead") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/membersVoted") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # The id of the member to vote &#39;yes&#39; on the card
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/membersVoted") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteCardsMembersVotedByIdCardByIdMember()
#
# DELETE /cards/{idCard}/membersVoted/{idMember}
# operationId: deleteCardsMembersVotedByIdCardByIdMember
export def "cards-members-voted delete" [
  id_card: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, id_member: $id_member} | format pattern "/cards/{id_card}/membersVoted/{id_member}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/name") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/pos") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getCardsStickersByIdCard()
#
# GET /cards/{idCard}/stickers
# operationId: getCardsStickersByIdCard
export def "cards-stickers list" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: image, imageScaled, imageUrl, left, rotate, top or zIndex (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/stickers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
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
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/stickers") $qp)
  let body = {"image": $image, "left": $left, "rotate": $rotate, "top": $top, "zIndex": $z_index} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteCardsStickersByIdCardByIdSticker()
#
# DELETE /cards/{idCard}/stickers/{idSticker}
# operationId: deleteCardsStickersByIdCardByIdSticker
export def "cards-stickers delete" [
  id_card: string
  id_sticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, id_sticker: $id_sticker} | format pattern "/cards/{id_card}/stickers/{id_sticker}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getCardsStickersByIdCardByIdSticker()
#
# GET /cards/{idCard}/stickers/{idSticker}
# operationId: getCardsStickersByIdCardByIdSticker
export def "cards-stickers get" [
  id_card: string
  id_sticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: image, imageScaled, imageUrl, left, rotate, top or zIndex (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, id_sticker: $id_sticker} | format pattern "/cards/{id_card}/stickers/{id_sticker}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateCardsStickersByIdCardByIdSticker()
#
# PUT /cards/{idCard}/stickers/{idSticker}
# operationId: updateCardsStickersByIdCardByIdSticker
export def "cards-stickers update" [
  id_card: string
  id_sticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
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
  let full_url = (build-url $base ({id_card: $id_card, id_sticker: $id_sticker} | format pattern "/cards/{id_card}/stickers/{id_sticker}") $qp)
  let body = {"image": $image, "left": $left, "rotate": $rotate, "top": $top, "zIndex": $z_index} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card} | format pattern "/cards/{id_card}/subscribed") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getCardsByIdCardByField()
#
# GET /cards/{idCard}/{field}
# operationId: getCardsByIdCardByField
export def "cards get" [
  id_card: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_card: $id_card, field: $field} | format pattern "/cards/{id_card}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
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
  let body = {"idBoard": $id_board, "idCard": $id_card, "idChecklistSource": $id_checklist_source, "name": $name, "pos": $pos} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: $id_checklist} | format pattern "/checklists/{id_checklist}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getChecklistsByIdChecklist()
#
# GET /checklists/{idChecklist}
# operationId: getChecklistsByIdChecklist
export def "checklists list" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cards: string # One of: all, closed, none, open or visible (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --check-items: string # One of: all or none (default: all)
  --check-item-fields: string # all or a comma-separated list of: name, nameData, pos, state or type (default: name, nameData, pos and state)
  --fields: string # all or a comma-separated list of: idBoard, idCard, name or pos (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cards" $cards "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "checkItems" $check_items "scalar") (serialize-qp "checkItem_fields" $check_item_fields "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: $id_checklist} | format pattern "/checklists/{id_checklist}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
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
  let full_url = (build-url $base ({id_checklist: $id_checklist} | format pattern "/checklists/{id_checklist}") $qp)
  let body = {"idBoard": $id_board, "idCard": $id_card, "idChecklistSource": $id_checklist_source, "name": $name, "pos": $pos} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getChecklistsBoardByIdChecklist()
#
# GET /checklists/{idChecklist}/board
# operationId: getChecklistsBoardByIdChecklist
export def "checklists-board list" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: $id_checklist} | format pattern "/checklists/{id_checklist}/board") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getChecklistsBoardByIdChecklistByField()
#
# GET /checklists/{idChecklist}/board/{field}
# operationId: getChecklistsBoardByIdChecklistByField
export def "checklists-board get" [
  id_checklist: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: $id_checklist, field: $field} | format pattern "/checklists/{id_checklist}/board/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getChecklistsCardsByIdChecklist()
#
# GET /checklists/{idChecklist}/cards
# operationId: getChecklistsCardsByIdChecklist
export def "checklists-cards list" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --attachments: string # A boolean value or &quot;cover&quot; for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --stickers: string #  true or false
  --members: string #  true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string #  true or false
  --checklists: string # One of: all or none (default: none)
  --limit: string # a number from 1 to 1000
  --since: string # A date, or null
  --before: string # A date, or null
  --filter: string # One of: all, closed, none or open (default: open)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "attachments" $attachments "scalar") (serialize-qp "attachment_fields" $attachment_fields "scalar") (serialize-qp "stickers" $stickers "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "checkItemStates" $check_item_states "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: $id_checklist} | format pattern "/checklists/{id_checklist}/cards") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getChecklistsCardsByIdChecklistByFilter()
#
# GET /checklists/{idChecklist}/cards/{filter}
# operationId: getChecklistsCardsByIdChecklistByFilter
export def "checklists-cards get" [
  id_checklist: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: $id_checklist, filter: $filter} | format pattern "/checklists/{id_checklist}/cards/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getChecklistsCheckItemsByIdChecklist()
#
# GET /checklists/{idChecklist}/checkItems
# operationId: getChecklistsCheckItemsByIdChecklist
export def "checklists-check-items list" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all or none (default: all)
  --fields: string # all or a comma-separated list of: name, nameData, pos, state or type (default: name, nameData, pos and state)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: $id_checklist} | format pattern "/checklists/{id_checklist}/checkItems") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --checked: string #  true or false
  --name: string # a string with a length from 1 to 16384
  --pos: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: $id_checklist} | format pattern "/checklists/{id_checklist}/checkItems") $qp)
  let body = {"checked": $checked, "name": $name, "pos": $pos} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteChecklistsCheckItemsByIdChecklistByIdCheckItem()
#
# DELETE /checklists/{idChecklist}/checkItems/{idCheckItem}
# operationId: deleteChecklistsCheckItemsByIdChecklistByIdCheckItem
export def "checklists-check-items delete" [
  id_checklist: string
  id_check_item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: $id_checklist, id_check_item: $id_check_item} | format pattern "/checklists/{id_checklist}/checkItems/{id_check_item}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getChecklistsCheckItemsByIdChecklistByIdCheckItem()
#
# GET /checklists/{idChecklist}/checkItems/{idCheckItem}
# operationId: getChecklistsCheckItemsByIdChecklistByIdCheckItem
export def "checklists-check-items get" [
  id_checklist: string
  id_check_item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: name, nameData, pos, state or type (default: name, nameData, pos and state)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: $id_checklist, id_check_item: $id_check_item} | format pattern "/checklists/{id_checklist}/checkItems/{id_check_item}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # The id of the card that the checklist is on
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: $id_checklist} | format pattern "/checklists/{id_checklist}/idCard") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: $id_checklist} | format pattern "/checklists/{id_checklist}/name") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: $id_checklist} | format pattern "/checklists/{id_checklist}/pos") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getChecklistsByIdChecklistByField()
#
# GET /checklists/{idChecklist}/{field}
# operationId: getChecklistsByIdChecklistByField
export def "checklists get" [
  id_checklist: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_checklist: $id_checklist, field: $field} | format pattern "/checklists/{id_checklist}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --color: string # A valid label color or null
  --id-board: string # An id
  --name: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/labels" $qp)
  let body = {"color": $color, "idBoard": $id_board, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_label: $id_label} | format pattern "/labels/{id_label}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: color, idBoard, name or uses (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_label: $id_label} | format pattern "/labels/{id_label}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --color: string # A valid label color or null
  --id-board: string # An id
  --name: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_label: $id_label} | format pattern "/labels/{id_label}") $qp)
  let body = {"color": $color, "idBoard": $id_board, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getLabelsBoardByIdLabel()
#
# GET /labels/{idLabel}/board
# operationId: getLabelsBoardByIdLabel
export def "labels-board list" [
  id_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_label: $id_label} | format pattern "/labels/{id_label}/board") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getLabelsBoardByIdLabelByField()
#
# GET /labels/{idLabel}/board/{field}
# operationId: getLabelsBoardByIdLabelByField
export def "labels-board get" [
  id_label: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_label: $id_label, field: $field} | format pattern "/labels/{id_label}/board/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # A valid label color or null
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_label: $id_label} | format pattern "/labels/{id_label}/color") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_label: $id_label} | format pattern "/labels/{id_label}/name") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --closed: string #  true or false
  --id-board: string # id of the board that the list should be added to
  --id-list-source: string # The id of the list to copy into a new list.
  --name: string # a string with a length from 1 to 16384
  --pos: string # A position. top , bottom , or a positive number.
  --subscribed: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists" $qp)
  let body = {"closed": $closed, "idBoard": $id_board, "idListSource": $id_list_source, "name": $name, "pos": $pos, "subscribed": $subscribed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getListsByIdList()
#
# GET /lists/{idList}
# operationId: getListsByIdList
export def "lists list" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cards: string # One of: all, closed, none or open (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --board: string #  true or false
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, desc, descData, closed, idOrganization, pinned, url and prefs)
  --fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: name, closed, idBoard and pos)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cards" $cards "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "board" $board "scalar") (serialize-qp "board_fields" $board_fields "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: $id_list} | format pattern "/lists/{id_list}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --closed: string #  true or false
  --id-board: string # id of the board that the list should be added to
  --id-list-source: string # The id of the list to copy into a new list.
  --name: string # a string with a length from 1 to 16384
  --pos: string # A position. top , bottom , or a positive number.
  --subscribed: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: $id_list} | format pattern "/lists/{id_list}") $qp)
  let body = {"closed": $closed, "idBoard": $id_board, "idListSource": $id_list_source, "name": $name, "pos": $pos, "subscribed": $subscribed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: string #  true or false
  --display: string #  true or false
  --filter: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization (default: all)
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --limit: string # a number from 0 to 1000 (default: 50)
  --format: string # One of: count, list or minimal (default: list)
  --since: string # A date, null or lastView
  --before: string # A date, or null
  --page: string # Page * limit must be less than 1000 (default: 0)
  --id-models: string # Only return actions related to these model ids
  --member: string #  true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --member-creator: string #  true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entities" $entities "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "idModels" $id_models "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "memberCreator" $member_creator "scalar") (serialize-qp "memberCreator_fields" $member_creator_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: $id_list} | format pattern "/lists/{id_list}/actions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: $id_list} | format pattern "/lists/{id_list}/archiveAllCards") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getListsBoardByIdList()
#
# GET /lists/{idList}/board
# operationId: getListsBoardByIdList
export def "lists-board list" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: $id_list} | format pattern "/lists/{id_list}/board") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getListsBoardByIdListByField()
#
# GET /lists/{idList}/board/{field}
# operationId: getListsBoardByIdListByField
export def "lists-board get" [
  id_list: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: $id_list, field: $field} | format pattern "/lists/{id_list}/board/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getListsCardsByIdList()
#
# GET /lists/{idList}/cards
# operationId: getListsCardsByIdList
export def "lists-cards list" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --attachments: string # A boolean value or &quot;cover&quot; for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --stickers: string #  true or false
  --members: string #  true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string #  true or false
  --checklists: string # One of: all or none (default: none)
  --limit: string # a number from 1 to 1000
  --since: string # A date, or null
  --before: string # A date, or null
  --filter: string # One of: all, closed, none or open (default: open)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "attachments" $attachments "scalar") (serialize-qp "attachment_fields" $attachment_fields "scalar") (serialize-qp "stickers" $stickers "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "checkItemStates" $check_item_states "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: $id_list} | format pattern "/lists/{id_list}/cards") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
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
  let full_url = (build-url $base ({id_list: $id_list} | format pattern "/lists/{id_list}/cards") $qp)
  let body = {"desc": $desc, "due": $due, "idMembers": $id_members, "labels": $labels, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getListsCardsByIdListByFilter()
#
# GET /lists/{idList}/cards/{filter}
# operationId: getListsCardsByIdListByFilter
export def "lists-cards get" [
  id_list: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: $id_list, filter: $filter} | format pattern "/lists/{id_list}/cards/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: $id_list} | format pattern "/lists/{id_list}/closed") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --pos: string # position of the list on the new board
  --value: string # id of the board the list should be moved to
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: $id_list} | format pattern "/lists/{id_list}/idBoard") $qp)
  let body = {"pos": $pos, "value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --id-board: string # id of the board that the cards should be moved to
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: $id_list} | format pattern "/lists/{id_list}/moveAllCards") $qp)
  let body = {"idBoard": $id_board} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: $id_list} | format pattern "/lists/{id_list}/name") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: $id_list} | format pattern "/lists/{id_list}/pos") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: $id_list} | format pattern "/lists/{id_list}/subscribed") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getListsByIdListByField()
#
# GET /lists/{idList}/{field}
# operationId: getListsByIdListByField
export def "lists get" [
  id_list: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_list: $id_list, field: $field} | format pattern "/lists/{id_list}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getMembersByIdMember()
#
# GET /members/{idMember}
# operationId: getMembersByIdMember
export def "members list" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string #  true or false
  --actions-display: string #  true or false
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --action-since: string # A date, null or lastView
  --action-before: string # A date, or null
  --cards: string # One of: all, closed, none, open or visible (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --card-members: string #  true or false
  --card-member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --card-attachments: string # A boolean value or &quot;cover&quot; for only card cover attachments
  --card-attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: url and previews)
  --card-stickers: string #  true or false
  --boards: string # all or a comma-separated list of: closed, members, open, organization, pinned, public, starred or unpinned
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, closed, idOrganization and pinned)
  --board-actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --board-actions-entities: string #  true or false
  --board-actions-display: string #  true or false
  --board-actions-format: string # One of: count, list or minimal (default: list)
  --board-actions-since: string # A date, null or lastView
  --board-actions-limit: string # a number from 0 to 1000 (default: 50)
  --board-action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --board-lists: string # One of: all, closed, none or open (default: none)
  --board-memberships: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: none)
  --board-organization: string #  true or false
  --board-organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: name and displayName)
  --boards-invited: string # all or a comma-separated list of: closed, members, open, organization, pinned, public, starred or unpinned
  --boards-invited-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, closed, idOrganization and pinned)
  --board-stars: string #  true or false
  --saved-searches: string #  true or false
  --organizations: string # One of: all, members, none or public (default: none)
  --organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --organization-paid-account: string #  true or false
  --organizations-invited: string # One of: all, members, none or public (default: none)
  --organizations-invited-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --notifications: string # all or a comma-separated list of: addAdminToBoard, addAdminToOrganization, addedAttachmentToCard, addedMemberToCard, addedToBoard, addedToCard, addedToOrganization, cardDueSoon, changeCard, closeBoard, commentCard, createdCard, declinedInvitationToBoard, declinedInvitationToOrganization, invitedToBoard, invitedToOrganization, makeAdminOfBoard, makeAdminOfOrganization, memberJoinedTrello, mentionedOnCard, removedFromBoard, removedFromCard, removedFromOrganization, removedMemberFromCard, unconfirmedInvitedToBoard, unconfirmedInvitedToOrganization or updateCheckItemStateOnCard
  --notifications-entities: string #  true or false
  --notifications-display: string #  true or false
  --notifications-limit: string # a number from 1 to 1000 (default: 50)
  --notification-fields: string # all or a comma-separated list of: data, date, idMemberCreator, type or unread (default: all)
  --notification-member-creator: string #  true or false
  --notification-member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --notification-before: string # An id, or null
  --notification-since: string # An id, or null
  --tokens: string # One of: all or none (default: none)
  --paid-account: string #  true or false
  --board-backgrounds: string # One of: all, custom, default, none or premium (default: none)
  --custom-board-backgrounds: string # One of: all or none (default: none)
  --custom-stickers: string # One of: all or none (default: none)
  --custom-emoji: string # One of: all or none (default: none)
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "actions_entities" $actions_entities "scalar") (serialize-qp "actions_display" $actions_display "scalar") (serialize-qp "actions_limit" $actions_limit "scalar") (serialize-qp "action_fields" $action_fields "scalar") (serialize-qp "action_since" $action_since "scalar") (serialize-qp "action_before" $action_before "scalar") (serialize-qp "cards" $cards "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "card_members" $card_members "scalar") (serialize-qp "card_member_fields" $card_member_fields "scalar") (serialize-qp "card_attachments" $card_attachments "scalar") (serialize-qp "card_attachment_fields" $card_attachment_fields "scalar") (serialize-qp "card_stickers" $card_stickers "scalar") (serialize-qp "boards" $boards "scalar") (serialize-qp "board_fields" $board_fields "scalar") (serialize-qp "board_actions" $board_actions "scalar") (serialize-qp "board_actions_entities" $board_actions_entities "scalar") (serialize-qp "board_actions_display" $board_actions_display "scalar") (serialize-qp "board_actions_format" $board_actions_format "scalar") (serialize-qp "board_actions_since" $board_actions_since "scalar") (serialize-qp "board_actions_limit" $board_actions_limit "scalar") (serialize-qp "board_action_fields" $board_action_fields "scalar") (serialize-qp "board_lists" $board_lists "scalar") (serialize-qp "board_memberships" $board_memberships "scalar") (serialize-qp "board_organization" $board_organization "scalar") (serialize-qp "board_organization_fields" $board_organization_fields "scalar") (serialize-qp "boardsInvited" $boards_invited "scalar") (serialize-qp "boardsInvited_fields" $boards_invited_fields "scalar") (serialize-qp "boardStars" $board_stars "scalar") (serialize-qp "savedSearches" $saved_searches "scalar") (serialize-qp "organizations" $organizations "scalar") (serialize-qp "organization_fields" $organization_fields "scalar") (serialize-qp "organization_paid_account" $organization_paid_account "scalar") (serialize-qp "organizationsInvited" $organizations_invited "scalar") (serialize-qp "organizationsInvited_fields" $organizations_invited_fields "scalar") (serialize-qp "notifications" $notifications "scalar") (serialize-qp "notifications_entities" $notifications_entities "scalar") (serialize-qp "notifications_display" $notifications_display "scalar") (serialize-qp "notifications_limit" $notifications_limit "scalar") (serialize-qp "notification_fields" $notification_fields "scalar") (serialize-qp "notification_memberCreator" $notification_member_creator "scalar") (serialize-qp "notification_memberCreator_fields" $notification_member_creator_fields "scalar") (serialize-qp "notification_before" $notification_before "scalar") (serialize-qp "notification_since" $notification_since "scalar") (serialize-qp "tokens" $tokens "scalar") (serialize-qp "paid_account" $paid_account "scalar") (serialize-qp "boardBackgrounds" $board_backgrounds "scalar") (serialize-qp "customBoardBackgrounds" $custom_board_backgrounds "scalar") (serialize-qp "customStickers" $custom_stickers "scalar") (serialize-qp "customEmoji" $custom_emoji "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --avatar-source: string # One of: gravatar, none or upload
  --bio: string # a string with a length from 0 to 16384
  --full-name: string # A string with a length of at least 1.  Cannot begin or end with a space.
  --initials: string # A string with a length from 1 to 4.  Cannot begin or end with a space
  --prefs-color-blind: string #  true or false
  --prefs-locale: string # a string with a length from 0 to 255
  --prefs-minutes-between-summaries: string # -1 (disabled), 1 or 60
  --username: string # A string with a length of at least 3.  Only lowercase letters, underscores, and numbers are allowed.  Must be unique.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}") $qp)
  let body = {"avatarSource": $avatar_source, "bio": $bio, "fullName": $full_name, "initials": $initials, "prefs/colorBlind": $prefs_color_blind, "prefs/locale": $prefs_locale, "prefs/minutesBetweenSummaries": $prefs_minutes_between_summaries, "username": $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: string #  true or false
  --display: string #  true or false
  --filter: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization (default: all)
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --limit: string # a number from 0 to 1000 (default: 50)
  --format: string # One of: count, list or minimal (default: list)
  --since: string # A date, null or lastView
  --before: string # A date, or null
  --page: string # Page * limit must be less than 1000 (default: 0)
  --id-models: string # Only return actions related to these model ids
  --member: string #  true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --member-creator: string #  true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entities" $entities "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "idModels" $id_models "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "memberCreator" $member_creator "scalar") (serialize-qp "memberCreator_fields" $member_creator_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/actions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --file: string # A file
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/avatar") $qp)
  let body = {"file": $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # One of: gravatar, none or upload
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/avatarSource") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/bio") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getMembersBoardBackgroundsByIdMember()
#
# GET /members/{idMember}/boardBackgrounds
# operationId: getMembersBoardBackgroundsByIdMember
export def "members-board-backgrounds list" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all, custom, default, none or premium (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/boardBackgrounds") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --brightness: string # One of: dark, light or unknown
  --file: string # A file
  --tile: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/boardBackgrounds") $qp)
  let body = {"brightness": $brightness, "file": $file, "tile": $tile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteMembersBoardBackgroundsByIdMemberByIdBoardBackground()
#
# DELETE /members/{idMember}/boardBackgrounds/{idBoardBackground}
# operationId: deleteMembersBoardBackgroundsByIdMemberByIdBoardBackground
export def "members-board-backgrounds delete" [
  id_member: string
  id_board_background: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_board_background: $id_board_background} | format pattern "/members/{id_member}/boardBackgrounds/{id_board_background}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getMembersBoardBackgroundsByIdMemberByIdBoardBackground()
#
# GET /members/{idMember}/boardBackgrounds/{idBoardBackground}
# operationId: getMembersBoardBackgroundsByIdMemberByIdBoardBackground
export def "members-board-backgrounds get" [
  id_member: string
  id_board_background: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: brightness, fullSizeUrl, scaled or tile (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_board_background: $id_board_background} | format pattern "/members/{id_member}/boardBackgrounds/{id_board_background}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateMembersBoardBackgroundsByIdMemberByIdBoardBackground()
#
# PUT /members/{idMember}/boardBackgrounds/{idBoardBackground}
# operationId: updateMembersBoardBackgroundsByIdMemberByIdBoardBackground
export def "members-board-backgrounds update" [
  id_member: string
  id_board_background: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --brightness: string # One of: dark, light or unknown
  --file: string # A file
  --tile: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_board_background: $id_board_background} | format pattern "/members/{id_member}/boardBackgrounds/{id_board_background}") $qp)
  let body = {"brightness": $brightness, "file": $file, "tile": $tile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getMembersBoardStarsByIdMember()
#
# GET /members/{idMember}/boardStars
# operationId: getMembersBoardStarsByIdMember
export def "members-board-stars list" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/boardStars") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --id-board: string # The id of the board to star
  --pos: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/boardStars") $qp)
  let body = {"idBoard": $id_board, "pos": $pos} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteMembersBoardStarsByIdMemberByIdBoardStar()
#
# DELETE /members/{idMember}/boardStars/{idBoardStar}
# operationId: deleteMembersBoardStarsByIdMemberByIdBoardStar
export def "members-board-stars delete" [
  id_member: string
  id_board_star: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_board_star: $id_board_star} | format pattern "/members/{id_member}/boardStars/{id_board_star}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getMembersBoardStarsByIdMemberByIdBoardStar()
#
# GET /members/{idMember}/boardStars/{idBoardStar}
# operationId: getMembersBoardStarsByIdMemberByIdBoardStar
export def "members-board-stars get" [
  id_member: string
  id_board_star: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_board_star: $id_board_star} | format pattern "/members/{id_member}/boardStars/{id_board_star}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateMembersBoardStarsByIdMemberByIdBoardStar()
#
# PUT /members/{idMember}/boardStars/{idBoardStar}
# operationId: updateMembersBoardStarsByIdMemberByIdBoardStar
export def "members-board-stars update" [
  id_member: string
  id_board_star: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --id-board: string # The id of the board to star
  --pos: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_board_star: $id_board_star} | format pattern "/members/{id_member}/boardStars/{id_board_star}") $qp)
  let body = {"idBoard": $id_board, "pos": $pos} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# updateMembersBoardStarsIdBoardByIdMemberByIdBoardStar()
#
# PUT /members/{idMember}/boardStars/{idBoardStar}/idBoard
# operationId: updateMembersBoardStarsIdBoardByIdMemberByIdBoardStar
export def "members-board-stars-id-board update" [
  id_member: string
  id_board_star: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # An id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_board_star: $id_board_star} | format pattern "/members/{id_member}/boardStars/{id_board_star}/idBoard") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# updateMembersBoardStarsPosByIdMemberByIdBoardStar()
#
# PUT /members/{idMember}/boardStars/{idBoardStar}/pos
# operationId: updateMembersBoardStarsPosByIdMemberByIdBoardStar
export def "members-board-stars-pos update" [
  id_member: string
  id_board_star: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_board_star: $id_board_star} | format pattern "/members/{id_member}/boardStars/{id_board_star}/pos") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getMembersBoardsByIdMember()
#
# GET /members/{idMember}/boards
# operationId: getMembersBoardsByIdMember
export def "members-boards list" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # all or a comma-separated list of: closed, members, open, organization, pinned, public, starred or unpinned (default: all)
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string #  true or false
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --actions-format: string # One of: count, list or minimal (default: list)
  --actions-since: string # A date, null or lastView
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --memberships: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: none)
  --organization: string #  true or false
  --organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: name and displayName)
  --lists: string # One of: all, closed, none or open (default: none)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "actions" $actions "scalar") (serialize-qp "actions_entities" $actions_entities "scalar") (serialize-qp "actions_limit" $actions_limit "scalar") (serialize-qp "actions_format" $actions_format "scalar") (serialize-qp "actions_since" $actions_since "scalar") (serialize-qp "action_fields" $action_fields "scalar") (serialize-qp "memberships" $memberships "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "organization_fields" $organization_fields "scalar") (serialize-qp "lists" $lists "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/boards") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getMembersBoardsByIdMemberByFilter()
#
# GET /members/{idMember}/boards/{filter}
# operationId: getMembersBoardsByIdMemberByFilter
export def "members-boards get" [
  id_member: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, filter: $filter} | format pattern "/members/{id_member}/boards/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getMembersBoardsInvitedByIdMember()
#
# GET /members/{idMember}/boardsInvited
# operationId: getMembersBoardsInvitedByIdMember
export def "members-boards-invited list" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/boardsInvited") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getMembersBoardsInvitedByIdMemberByField()
#
# GET /members/{idMember}/boardsInvited/{field}
# operationId: getMembersBoardsInvitedByIdMemberByField
export def "members-boards-invited get" [
  id_member: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, field: $field} | format pattern "/members/{id_member}/boardsInvited/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getMembersCardsByIdMember()
#
# GET /members/{idMember}/cards
# operationId: getMembersCardsByIdMember
export def "members-cards list" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --attachments: string # A boolean value or &quot;cover&quot; for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --stickers: string #  true or false
  --members: string #  true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string #  true or false
  --checklists: string # One of: all or none (default: none)
  --limit: string # a number from 1 to 1000
  --since: string # A date, or null
  --before: string # A date, or null
  --filter: string # One of: all, closed, none, open or visible (default: visible)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "attachments" $attachments "scalar") (serialize-qp "attachment_fields" $attachment_fields "scalar") (serialize-qp "stickers" $stickers "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "checkItemStates" $check_item_states "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/cards") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getMembersCardsByIdMemberByFilter()
#
# GET /members/{idMember}/cards/{filter}
# operationId: getMembersCardsByIdMemberByFilter
export def "members-cards get" [
  id_member: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, filter: $filter} | format pattern "/members/{id_member}/cards/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getMembersCustomBoardBackgroundsByIdMember()
#
# GET /members/{idMember}/customBoardBackgrounds
# operationId: getMembersCustomBoardBackgroundsByIdMember
export def "members-custom-board-backgrounds list" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all or none (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/customBoardBackgrounds") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --brightness: string # One of: dark, light or unknown
  --file: string # A file
  --tile: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/customBoardBackgrounds") $qp)
  let body = {"brightness": $brightness, "file": $file, "tile": $tile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteMembersCustomBoardBackgroundsByIdMemberByIdBoardBackground()
#
# DELETE /members/{idMember}/customBoardBackgrounds/{idBoardBackground}
# operationId: deleteMembersCustomBoardBackgroundsByIdMemberByIdBoardBackground
export def "members-custom-board-backgrounds delete" [
  id_member: string
  id_board_background: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_board_background: $id_board_background} | format pattern "/members/{id_member}/customBoardBackgrounds/{id_board_background}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getMembersCustomBoardBackgroundsByIdMemberByIdBoardBackground()
#
# GET /members/{idMember}/customBoardBackgrounds/{idBoardBackground}
# operationId: getMembersCustomBoardBackgroundsByIdMemberByIdBoardBackground
export def "members-custom-board-backgrounds get" [
  id_member: string
  id_board_background: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: brightness, fullSizeUrl, scaled or tile (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_board_background: $id_board_background} | format pattern "/members/{id_member}/customBoardBackgrounds/{id_board_background}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateMembersCustomBoardBackgroundsByIdMemberByIdBoardBackground()
#
# PUT /members/{idMember}/customBoardBackgrounds/{idBoardBackground}
# operationId: updateMembersCustomBoardBackgroundsByIdMemberByIdBoardBackground
export def "members-custom-board-backgrounds update" [
  id_member: string
  id_board_background: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --brightness: string # One of: dark, light or unknown
  --file: string # A file
  --tile: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_board_background: $id_board_background} | format pattern "/members/{id_member}/customBoardBackgrounds/{id_board_background}") $qp)
  let body = {"brightness": $brightness, "file": $file, "tile": $tile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getMembersCustomEmojiByIdMember()
#
# GET /members/{idMember}/customEmoji
# operationId: getMembersCustomEmojiByIdMember
export def "members-custom-emoji list" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all or none (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/customEmoji") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --file: string # A file
  --name: string # a string with a length from 2 to 64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/customEmoji") $qp)
  let body = {"file": $file, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getMembersCustomEmojiByIdMemberByIdCustomEmoji()
#
# GET /members/{idMember}/customEmoji/{idCustomEmoji}
# operationId: getMembersCustomEmojiByIdMemberByIdCustomEmoji
export def "members-custom-emoji get" [
  id_member: string
  id_custom_emoji: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: name or url (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_custom_emoji: $id_custom_emoji} | format pattern "/members/{id_member}/customEmoji/{id_custom_emoji}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getMembersCustomStickersByIdMember()
#
# GET /members/{idMember}/customStickers
# operationId: getMembersCustomStickersByIdMember
export def "members-custom-stickers list" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all or none (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/customStickers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --file: string # A file
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/customStickers") $qp)
  let body = {"file": $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteMembersCustomStickersByIdMemberByIdCustomSticker()
#
# DELETE /members/{idMember}/customStickers/{idCustomSticker}
# operationId: deleteMembersCustomStickersByIdMemberByIdCustomSticker
export def "members-custom-stickers delete" [
  id_member: string
  id_custom_sticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_custom_sticker: $id_custom_sticker} | format pattern "/members/{id_member}/customStickers/{id_custom_sticker}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getMembersCustomStickersByIdMemberByIdCustomSticker()
#
# GET /members/{idMember}/customStickers/{idCustomSticker}
# operationId: getMembersCustomStickersByIdMemberByIdCustomSticker
export def "members-custom-stickers get" [
  id_member: string
  id_custom_sticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: scaled or url (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_custom_sticker: $id_custom_sticker} | format pattern "/members/{id_member}/customStickers/{id_custom_sticker}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: string # A valid tag for subscribing
  --ix-last-update: string # a number from -1 to Infinity
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tags" $tags "scalar") (serialize-qp "ixLastUpdate" $ix_last_update "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/deltas") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # A string with a length of at least 1.  Cannot begin or end with a space.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/fullName") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # A string with a length from 1 to 4.  Cannot begin or end with a space
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/initials") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getMembersNotificationsByIdMember()
#
# GET /members/{idMember}/notifications
# operationId: getMembersNotificationsByIdMember
export def "members-notifications list" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: string #  true or false
  --display: string #  true or false
  --filter: string # all or a comma-separated list of: addAdminToBoard, addAdminToOrganization, addedAttachmentToCard, addedMemberToCard, addedToBoard, addedToCard, addedToOrganization, cardDueSoon, changeCard, closeBoard, commentCard, createdCard, declinedInvitationToBoard, declinedInvitationToOrganization, invitedToBoard, invitedToOrganization, makeAdminOfBoard, makeAdminOfOrganization, memberJoinedTrello, mentionedOnCard, removedFromBoard, removedFromCard, removedFromOrganization, removedMemberFromCard, unconfirmedInvitedToBoard, unconfirmedInvitedToOrganization or updateCheckItemStateOnCard (default: all)
  --read-filter: string # One of: all, read or unread (default: all)
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator, type or unread (default: all)
  --limit: string # a number from 1 to 1000 (default: 50)
  --page: string # a number from 0 to 100 (default: 0)
  --before: string # An id, or null
  --since: string # An id, or null
  --member-creator: string #  true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entities" $entities "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "read_filter" $read_filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "memberCreator" $member_creator "scalar") (serialize-qp "memberCreator_fields" $member_creator_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/notifications") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getMembersNotificationsByIdMemberByFilter()
#
# GET /members/{idMember}/notifications/{filter}
# operationId: getMembersNotificationsByIdMemberByFilter
export def "members-notifications get" [
  id_member: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, filter: $filter} | format pattern "/members/{id_member}/notifications/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # Type of message dismissed
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/oneTimeMessagesDismissed") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getMembersOrganizationsByIdMember()
#
# GET /members/{idMember}/organizations
# operationId: getMembersOrganizationsByIdMember
export def "members-organizations list" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all, members, none or public (default: all)
  --fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --paid-account: string #  true or false
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "paid_account" $paid_account "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/organizations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getMembersOrganizationsByIdMemberByFilter()
#
# GET /members/{idMember}/organizations/{filter}
# operationId: getMembersOrganizationsByIdMemberByFilter
export def "members-organizations get" [
  id_member: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, filter: $filter} | format pattern "/members/{id_member}/organizations/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getMembersOrganizationsInvitedByIdMember()
#
# GET /members/{idMember}/organizationsInvited
# operationId: getMembersOrganizationsInvitedByIdMember
export def "members-organizations-invited list" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/organizationsInvited") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getMembersOrganizationsInvitedByIdMemberByField()
#
# GET /members/{idMember}/organizationsInvited/{field}
# operationId: getMembersOrganizationsInvitedByIdMemberByField
export def "members-organizations-invited get" [
  id_member: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, field: $field} | format pattern "/members/{id_member}/organizationsInvited/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/prefs/colorBlind") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 0 to 255
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/prefs/locale") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # -1 (disabled), 1 or 60
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/prefs/minutesBetweenSummaries") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getMembersSavedSearchesByIdMember()
#
# GET /members/{idMember}/savedSearches
# operationId: getMembersSavedSearchesByIdMember
export def "members-saved-searches list" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/savedSearches") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --name: string # A non-empty string with at least one non-space character
  --pos: string # A position. top , bottom , or a positive number.
  --query: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/savedSearches") $qp)
  let body = {"name": $name, "pos": $pos, "query": $query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteMembersSavedSearchesByIdMemberByIdSavedSearch()
#
# DELETE /members/{idMember}/savedSearches/{idSavedSearch}
# operationId: deleteMembersSavedSearchesByIdMemberByIdSavedSearch
export def "members-saved-searches delete" [
  id_member: string
  id_saved_search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_saved_search: $id_saved_search} | format pattern "/members/{id_member}/savedSearches/{id_saved_search}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getMembersSavedSearchesByIdMemberByIdSavedSearch()
#
# GET /members/{idMember}/savedSearches/{idSavedSearch}
# operationId: getMembersSavedSearchesByIdMemberByIdSavedSearch
export def "members-saved-searches get" [
  id_member: string
  id_saved_search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_saved_search: $id_saved_search} | format pattern "/members/{id_member}/savedSearches/{id_saved_search}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateMembersSavedSearchesByIdMemberByIdSavedSearch()
#
# PUT /members/{idMember}/savedSearches/{idSavedSearch}
# operationId: updateMembersSavedSearchesByIdMemberByIdSavedSearch
export def "members-saved-searches update" [
  id_member: string
  id_saved_search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --name: string # A non-empty string with at least one non-space character
  --pos: string # A position. top , bottom , or a positive number.
  --query: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_saved_search: $id_saved_search} | format pattern "/members/{id_member}/savedSearches/{id_saved_search}") $qp)
  let body = {"name": $name, "pos": $pos, "query": $query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# updateMembersSavedSearchesNameByIdMemberByIdSavedSearch()
#
# PUT /members/{idMember}/savedSearches/{idSavedSearch}/name
# operationId: updateMembersSavedSearchesNameByIdMemberByIdSavedSearch
export def "members-saved-searches-name update" [
  id_member: string
  id_saved_search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # A non-empty string with at least one non-space character
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_saved_search: $id_saved_search} | format pattern "/members/{id_member}/savedSearches/{id_saved_search}/name") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# updateMembersSavedSearchesPosByIdMemberByIdSavedSearch()
#
# PUT /members/{idMember}/savedSearches/{idSavedSearch}/pos
# operationId: updateMembersSavedSearchesPosByIdMemberByIdSavedSearch
export def "members-saved-searches-pos update" [
  id_member: string
  id_saved_search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # A position. top , bottom , or a positive number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_saved_search: $id_saved_search} | format pattern "/members/{id_member}/savedSearches/{id_saved_search}/pos") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# updateMembersSavedSearchesQueryByIdMemberByIdSavedSearch()
#
# PUT /members/{idMember}/savedSearches/{idSavedSearch}/query
# operationId: updateMembersSavedSearchesQueryByIdMemberByIdSavedSearch
export def "members-saved-searches-query update" [
  id_member: string
  id_saved_search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, id_saved_search: $id_saved_search} | format pattern "/members/{id_member}/savedSearches/{id_saved_search}/query") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all or none (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/tokens") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # A string with a length of at least 3.  Only lowercase letters, underscores, and numbers are allowed.  Must be unique.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member} | format pattern "/members/{id_member}/username") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getMembersByIdMemberByField()
#
# GET /members/{idMember}/{field}
# operationId: getMembersByIdMemberByField
export def "members get" [
  id_member: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_member: $id_member, field: $field} | format pattern "/members/{id_member}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/all/read" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getNotificationsByIdNotification()
#
# GET /notifications/{idNotification}
# operationId: getNotificationsByIdNotification
export def "notifications list" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --display: string #  true or false
  --entities: string #  true or false
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator, type or unread (default: all)
  --member-creator: string #  true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --board: string #  true or false
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name)
  --list: string #  true or false
  --card: string #  true or false
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: name)
  --organization: string #  true or false
  --organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: displayName)
  --member: string #  true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "display" $display "scalar") (serialize-qp "entities" $entities "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "memberCreator" $member_creator "scalar") (serialize-qp "memberCreator_fields" $member_creator_fields "scalar") (serialize-qp "board" $board "scalar") (serialize-qp "board_fields" $board_fields "scalar") (serialize-qp "list" $list "scalar") (serialize-qp "card" $card "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "organization_fields" $organization_fields "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: $id_notification} | format pattern "/notifications/{id_notification}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --unread: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: $id_notification} | format pattern "/notifications/{id_notification}") $qp)
  let body = {"unread": $unread} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getNotificationsBoardByIdNotification()
#
# GET /notifications/{idNotification}/board
# operationId: getNotificationsBoardByIdNotification
export def "notifications-board list" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: $id_notification} | format pattern "/notifications/{id_notification}/board") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getNotificationsBoardByIdNotificationByField()
#
# GET /notifications/{idNotification}/board/{field}
# operationId: getNotificationsBoardByIdNotificationByField
export def "notifications-board get" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: $id_notification, field: $field} | format pattern "/notifications/{id_notification}/board/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getNotificationsCardByIdNotification()
#
# GET /notifications/{idNotification}/card
# operationId: getNotificationsCardByIdNotification
export def "notifications-card list" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: $id_notification} | format pattern "/notifications/{id_notification}/card") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getNotificationsCardByIdNotificationByField()
#
# GET /notifications/{idNotification}/card/{field}
# operationId: getNotificationsCardByIdNotificationByField
export def "notifications-card get" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: $id_notification, field: $field} | format pattern "/notifications/{id_notification}/card/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: $id_notification} | format pattern "/notifications/{id_notification}/display") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: $id_notification} | format pattern "/notifications/{id_notification}/entities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getNotificationsListByIdNotification()
#
# GET /notifications/{idNotification}/list
# operationId: getNotificationsListByIdNotification
export def "notifications-list list" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: $id_notification} | format pattern "/notifications/{id_notification}/list") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getNotificationsListByIdNotificationByField()
#
# GET /notifications/{idNotification}/list/{field}
# operationId: getNotificationsListByIdNotificationByField
export def "notifications-list get" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: $id_notification, field: $field} | format pattern "/notifications/{id_notification}/list/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getNotificationsMemberByIdNotification()
#
# GET /notifications/{idNotification}/member
# operationId: getNotificationsMemberByIdNotification
export def "notifications-member list" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: $id_notification} | format pattern "/notifications/{id_notification}/member") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getNotificationsMemberByIdNotificationByField()
#
# GET /notifications/{idNotification}/member/{field}
# operationId: getNotificationsMemberByIdNotificationByField
export def "notifications-member get" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: $id_notification, field: $field} | format pattern "/notifications/{id_notification}/member/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getNotificationsMemberCreatorByIdNotification()
#
# GET /notifications/{idNotification}/memberCreator
# operationId: getNotificationsMemberCreatorByIdNotification
export def "notifications-member-creator list" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: $id_notification} | format pattern "/notifications/{id_notification}/memberCreator") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getNotificationsMemberCreatorByIdNotificationByField()
#
# GET /notifications/{idNotification}/memberCreator/{field}
# operationId: getNotificationsMemberCreatorByIdNotificationByField
export def "notifications-member-creator get" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: $id_notification, field: $field} | format pattern "/notifications/{id_notification}/memberCreator/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getNotificationsOrganizationByIdNotification()
#
# GET /notifications/{idNotification}/organization
# operationId: getNotificationsOrganizationByIdNotification
export def "notifications-organization list" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: $id_notification} | format pattern "/notifications/{id_notification}/organization") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getNotificationsOrganizationByIdNotificationByField()
#
# GET /notifications/{idNotification}/organization/{field}
# operationId: getNotificationsOrganizationByIdNotificationByField
export def "notifications-organization get" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: $id_notification, field: $field} | format pattern "/notifications/{id_notification}/organization/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: $id_notification} | format pattern "/notifications/{id_notification}/unread") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getNotificationsByIdNotificationByField()
#
# GET /notifications/{idNotification}/{field}
# operationId: getNotificationsByIdNotificationByField
export def "notifications get" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_notification: $id_notification, field: $field} | format pattern "/notifications/{id_notification}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --desc: string # a string with a length from 0 to 16384
  --display-name: string # A string with a length of at least 1.  Cannot begin or end with a space.
  --name: string # a string with a length from 0 to 16384
  --prefs-associated-domain: string # The google apps domain to link this org to.
  --prefs-board-visibility-restrict-org: string # One of: admin, none or org
  --prefs-board-visibility-restrict-private: string # One of: admin, none or org
  --prefs-board-visibility-restrict-public: string # One of: admin, none or org
  --prefs-external-members-disabled: string #  true or false
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
  let body = {"desc": $desc, "displayName": $display_name, "name": $name, "prefs/associatedDomain": $prefs_associated_domain, "prefs/boardVisibilityRestrict/org": $prefs_board_visibility_restrict_org, "prefs/boardVisibilityRestrict/private": $prefs_board_visibility_restrict_private, "prefs/boardVisibilityRestrict/public": $prefs_board_visibility_restrict_public, "prefs/externalMembersDisabled": $prefs_external_members_disabled, "prefs/googleAppsVersion": $prefs_google_apps_version, "prefs/orgInviteRestrict": $prefs_org_invite_restrict, "prefs/permissionLevel": $prefs_permission_level, "website": $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteOrganizationsByIdOrg()
#
# DELETE /organizations/{idOrg}
# operationId: deleteOrganizationsByIdOrg
export def "organizations delete" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string #  true or false
  --actions-display: string #  true or false
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --memberships: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: none)
  --memberships-member: string #  true or false
  --memberships-member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --members: string # One of: admins, all, none, normal or owners (default: none)
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials, username and confirmed)
  --member-activity: string # true or false ; works for premium organizations only.
  --members-invited: string # One of: admins, all, none, normal or owners (default: none)
  --members-invited-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, initials, fullName and username)
  --boards: string # all or a comma-separated list of: closed, members, open, organization, pinned, public, starred or unpinned (default: none)
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --board-actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --board-actions-entities: string #  true or false
  --board-actions-display: string #  true or false
  --board-actions-format: string # One of: count, list or minimal (default: list)
  --board-actions-since: string # A date, null or lastView
  --board-actions-limit: string # a number from 0 to 1000 (default: 50)
  --board-action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --board-lists: string # One of: all, closed, none or open (default: none)
  --paid-account: string #  true or false
  --fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: name, displayName, desc, descData, url, website, logoHash, products and powerUps)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "actions_entities" $actions_entities "scalar") (serialize-qp "actions_display" $actions_display "scalar") (serialize-qp "actions_limit" $actions_limit "scalar") (serialize-qp "action_fields" $action_fields "scalar") (serialize-qp "memberships" $memberships "scalar") (serialize-qp "memberships_member" $memberships_member "scalar") (serialize-qp "memberships_member_fields" $memberships_member_fields "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "member_activity" $member_activity "scalar") (serialize-qp "membersInvited" $members_invited "scalar") (serialize-qp "membersInvited_fields" $members_invited_fields "scalar") (serialize-qp "boards" $boards "scalar") (serialize-qp "board_fields" $board_fields "scalar") (serialize-qp "board_actions" $board_actions "scalar") (serialize-qp "board_actions_entities" $board_actions_entities "scalar") (serialize-qp "board_actions_display" $board_actions_display "scalar") (serialize-qp "board_actions_format" $board_actions_format "scalar") (serialize-qp "board_actions_since" $board_actions_since "scalar") (serialize-qp "board_actions_limit" $board_actions_limit "scalar") (serialize-qp "board_action_fields" $board_action_fields "scalar") (serialize-qp "board_lists" $board_lists "scalar") (serialize-qp "paid_account" $paid_account "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateOrganizationsByIdOrg()
#
# PUT /organizations/{idOrg}
# operationId: updateOrganizationsByIdOrg
export def "organizations update" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --desc: string # a string with a length from 0 to 16384
  --display-name: string # A string with a length of at least 1.  Cannot begin or end with a space.
  --name: string # a string with a length from 0 to 16384
  --prefs-associated-domain: string # The google apps domain to link this org to.
  --prefs-board-visibility-restrict-org: string # One of: admin, none or org
  --prefs-board-visibility-restrict-private: string # One of: admin, none or org
  --prefs-board-visibility-restrict-public: string # One of: admin, none or org
  --prefs-external-members-disabled: string #  true or false
  --prefs-google-apps-version: string # a number from 1 to 2
  --prefs-org-invite-restrict: string # An email address with optional expansion tokens
  --prefs-permission-level: string # One of: private or public
  --website: string # A URL starting with http:// or https:// or null
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}") $qp)
  let body = {"desc": $desc, "displayName": $display_name, "name": $name, "prefs/associatedDomain": $prefs_associated_domain, "prefs/boardVisibilityRestrict/org": $prefs_board_visibility_restrict_org, "prefs/boardVisibilityRestrict/private": $prefs_board_visibility_restrict_private, "prefs/boardVisibilityRestrict/public": $prefs_board_visibility_restrict_public, "prefs/externalMembersDisabled": $prefs_external_members_disabled, "prefs/googleAppsVersion": $prefs_google_apps_version, "prefs/orgInviteRestrict": $prefs_org_invite_restrict, "prefs/permissionLevel": $prefs_permission_level, "website": $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getOrganizationsActionsByIdOrg()
#
# GET /organizations/{idOrg}/actions
# operationId: getOrganizationsActionsByIdOrg
export def "organizations-actions get" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: string #  true or false
  --display: string #  true or false
  --filter: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization (default: all)
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --limit: string # a number from 0 to 1000 (default: 50)
  --format: string # One of: count, list or minimal (default: list)
  --since: string # A date, null or lastView
  --before: string # A date, or null
  --page: string # Page * limit must be less than 1000 (default: 0)
  --id-models: string # Only return actions related to these model ids
  --member: string #  true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --member-creator: string #  true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entities" $entities "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "idModels" $id_models "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "memberCreator" $member_creator "scalar") (serialize-qp "memberCreator_fields" $member_creator_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/actions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # all or a comma-separated list of: closed, members, open, organization, pinned, public, starred or unpinned (default: all)
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string #  true or false
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --actions-format: string # One of: count, list or minimal (default: list)
  --actions-since: string # A date, null or lastView
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --memberships: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: none)
  --organization: string #  true or false
  --organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: name and displayName)
  --lists: string # One of: all, closed, none or open (default: none)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "actions" $actions "scalar") (serialize-qp "actions_entities" $actions_entities "scalar") (serialize-qp "actions_limit" $actions_limit "scalar") (serialize-qp "actions_format" $actions_format "scalar") (serialize-qp "actions_since" $actions_since "scalar") (serialize-qp "action_fields" $action_fields "scalar") (serialize-qp "memberships" $memberships "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "organization_fields" $organization_fields "scalar") (serialize-qp "lists" $lists "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/boards") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getOrganizationsBoardsByIdOrgByFilter()
#
# GET /organizations/{idOrg}/boards/{filter}
# operationId: getOrganizationsBoardsByIdOrgByFilter
export def "organizations-boards get" [
  id_org: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org, filter: $filter} | format pattern "/organizations/{id_org}/boards/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getOrganizationsDeltasByIdOrg()
#
# GET /organizations/{idOrg}/deltas
# operationId: getOrganizationsDeltasByIdOrg
export def "organizations-deltas get" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: string # A valid tag for subscribing
  --ix-last-update: string # a number from -1 to Infinity
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tags" $tags "scalar") (serialize-qp "ixLastUpdate" $ix_last_update "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/deltas") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateOrganizationsDescByIdOrg()
#
# PUT /organizations/{idOrg}/desc
# operationId: updateOrganizationsDescByIdOrg
export def "organizations-desc update" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/desc") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# updateOrganizationsDisplayNameByIdOrg()
#
# PUT /organizations/{idOrg}/displayName
# operationId: updateOrganizationsDisplayNameByIdOrg
export def "organizations-display-name update" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # A string with a length of at least 1.  Cannot begin or end with a space.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/displayName") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteOrganizationsLogoByIdOrg()
#
# DELETE /organizations/{idOrg}/logo
# operationId: deleteOrganizationsLogoByIdOrg
export def "organizations-logo delete" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/logo") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# addOrganizationsLogoByIdOrg()
#
# POST /organizations/{idOrg}/logo
# operationId: addOrganizationsLogoByIdOrg
export def "organizations-logo create" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --file: string # A file
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/logo") $qp)
  let body = {"file": $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: admins, all, none, normal or owners (default: all)
  --fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --activity: string # true or false ; works for premium organizations only.
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "activity" $activity "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateOrganizationsMembersByIdOrg()
#
# PUT /organizations/{idOrg}/members
# operationId: updateOrganizationsMembersByIdOrg
export def "organizations-members update-by-idOrg" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --email: string # An email address
  --full-name: string # A string with a length of at least 1.  Cannot begin or end with a space.
  --type: string # One of: admin, normal or observer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/members") $qp)
  let body = {"email": $email, "fullName": $full_name, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getOrganizationsMembersByIdOrgByFilter()
#
# GET /organizations/{idOrg}/members/{filter}
# operationId: getOrganizationsMembersByIdOrgByFilter
export def "organizations-members get" [
  id_org: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org, filter: $filter} | format pattern "/organizations/{id_org}/members/{filter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# deleteOrganizationsMembersByIdOrgByIdMember()
#
# DELETE /organizations/{idOrg}/members/{idMember}
# operationId: deleteOrganizationsMembersByIdOrgByIdMember
export def "organizations-members delete" [
  id_org: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org, id_member: $id_member} | format pattern "/organizations/{id_org}/members/{id_member}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateOrganizationsMembersByIdOrgByIdMember()
#
# PUT /organizations/{idOrg}/members/{idMember}
# operationId: updateOrganizationsMembersByIdOrgByIdMember
export def "organizations-members update-by-idOrg-idMember" [
  id_org: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --email: string # An email address
  --full-name: string # A string with a length of at least 1.  Cannot begin or end with a space.
  --type: string # One of: admin, normal or observer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org, id_member: $id_member} | format pattern "/organizations/{id_org}/members/{id_member}") $qp)
  let body = {"email": $email, "fullName": $full_name, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteOrganizationsMembersAllByIdOrgByIdMember()
#
# DELETE /organizations/{idOrg}/members/{idMember}/all
# operationId: deleteOrganizationsMembersAllByIdOrgByIdMember
export def "organizations-members-all delete" [
  id_org: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org, id_member: $id_member} | format pattern "/organizations/{id_org}/members/{id_member}/all") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getOrganizationsMembersCardsByIdOrgByIdMember()
#
# GET /organizations/{idOrg}/members/{idMember}/cards
# operationId: getOrganizationsMembersCardsByIdOrgByIdMember
export def "organizations-members-cards get" [
  id_org: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --attachments: string # A boolean value or &quot;cover&quot; for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --members: string #  true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string #  true or false
  --checklists: string # One of: all or none (default: none)
  --board: string #  true or false
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, desc, closed, idOrganization, pinned, url and prefs)
  --list: string #  true or false
  --list-fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --filter: string # One of: all, closed, none, open or visible (default: visible)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "attachments" $attachments "scalar") (serialize-qp "attachment_fields" $attachment_fields "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "checkItemStates" $check_item_states "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "board" $board "scalar") (serialize-qp "board_fields" $board_fields "scalar") (serialize-qp "list" $list "scalar") (serialize-qp "list_fields" $list_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org, id_member: $id_member} | format pattern "/organizations/{id_org}/members/{id_member}/cards") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateOrganizationsMembersDeactivatedByIdOrgByIdMember()
#
# PUT /organizations/{idOrg}/members/{idMember}/deactivated
# operationId: updateOrganizationsMembersDeactivatedByIdOrgByIdMember
export def "organizations-members-deactivated update" [
  id_org: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org, id_member: $id_member} | format pattern "/organizations/{id_org}/members/{id_member}/deactivated") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/membersInvited") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getOrganizationsMembersInvitedByIdOrgByField()
#
# GET /organizations/{idOrg}/membersInvited/{field}
# operationId: getOrganizationsMembersInvitedByIdOrgByField
export def "organizations-members-invited get" [
  id_org: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org, field: $field} | format pattern "/organizations/{id_org}/membersInvited/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: all)
  --member: string #  true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/memberships") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getOrganizationsMembershipsByIdOrgByIdMembership()
#
# GET /organizations/{idOrg}/memberships/{idMembership}
# operationId: getOrganizationsMembershipsByIdOrgByIdMembership
export def "organizations-memberships get" [
  id_org: string
  id_membership: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --member: string #  true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org, id_membership: $id_membership} | format pattern "/organizations/{id_org}/memberships/{id_membership}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateOrganizationsMembershipsByIdOrgByIdMembership()
#
# PUT /organizations/{idOrg}/memberships/{idMembership}
# operationId: updateOrganizationsMembershipsByIdOrgByIdMembership
export def "organizations-memberships update" [
  id_org: string
  id_membership: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username
  --type: string # One of: admin, normal or observer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org, id_membership: $id_membership} | format pattern "/organizations/{id_org}/memberships/{id_membership}") $qp)
  let body = {"member_fields": $member_fields, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# updateOrganizationsNameByIdOrg()
#
# PUT /organizations/{idOrg}/name
# operationId: updateOrganizationsNameByIdOrg
export def "organizations-name update" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # A string with a length of at least 3.  Only lowercase letters, underscores, and numbers are allowed.  Must be unique.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/name") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteOrganizationsPrefsAssociatedDomainByIdOrg()
#
# DELETE /organizations/{idOrg}/prefs/associatedDomain
# operationId: deleteOrganizationsPrefsAssociatedDomainByIdOrg
export def "organizations-prefs-associated-domain delete" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/prefs/associatedDomain") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateOrganizationsPrefsAssociatedDomainByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/associatedDomain
# operationId: updateOrganizationsPrefsAssociatedDomainByIdOrg
export def "organizations-prefs-associated-domain update" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # The google apps domain to link this org to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/prefs/associatedDomain") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # One of: admin, none or org
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/prefs/boardVisibilityRestrict/org") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# updateOrganizationsPrefsBoardVisibilityRestrictPrivateByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/boardVisibilityRestrict/private
# operationId: updateOrganizationsPrefsBoardVisibilityRestrictPrivateByIdOrg
export def "organizations-prefs-board-visibility-restrict-private update" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # One of: admin, none or org
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/prefs/boardVisibilityRestrict/private") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# updateOrganizationsPrefsBoardVisibilityRestrictPublicByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/boardVisibilityRestrict/public
# operationId: updateOrganizationsPrefsBoardVisibilityRestrictPublicByIdOrg
export def "organizations-prefs-board-visibility-restrict-public update" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # One of: admin, none or org
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/prefs/boardVisibilityRestrict/public") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# updateOrganizationsPrefsExternalMembersDisabledByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/externalMembersDisabled
# operationId: updateOrganizationsPrefsExternalMembersDisabledByIdOrg
export def "organizations-prefs-external-members-disabled update" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/prefs/externalMembersDisabled") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# updateOrganizationsPrefsGoogleAppsVersionByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/googleAppsVersion
# operationId: updateOrganizationsPrefsGoogleAppsVersionByIdOrg
export def "organizations-prefs-google-apps-version update" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a number from 1 to 2
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/prefs/googleAppsVersion") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # An email address with optional expansion tokens
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/prefs/orgInviteRestrict") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # An email address with optional expansion tokens
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/prefs/orgInviteRestrict") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# updateOrganizationsPrefsPermissionLevelByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/permissionLevel
# operationId: updateOrganizationsPrefsPermissionLevelByIdOrg
export def "organizations-prefs-permission-level update" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # One of: private or public
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/prefs/permissionLevel") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# updateOrganizationsWebsiteByIdOrg()
#
# PUT /organizations/{idOrg}/website
# operationId: updateOrganizationsWebsiteByIdOrg
export def "organizations-website update" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # A URL starting with http:// or https:// or null
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org} | format pattern "/organizations/{id_org}/website") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getOrganizationsByIdOrgByField()
#
# GET /organizations/{idOrg}/{field}
# operationId: getOrganizationsByIdOrgByField
export def "organizations get" [
  id_org: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_org: $id_org, field: $field} | format pattern "/organizations/{id_org}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --card-board: string #  true or false
  --card-list: string #  true or false
  --card-members: string #  true or false
  --card-stickers: string #  true or false
  --card-attachments: string # A boolean value or &quot;cover&quot; for only card cover attachments
  --organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: name and displayName)
  --organizations-limit: string # a number from 1 to 1000 (default: 10)
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials, username and confirmed)
  --members-limit: string # a number from 1 to 1000 (default: 10)
  --partial: string #  true or false
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "idBoards" $id_boards "scalar") (serialize-qp "idOrganizations" $id_organizations "scalar") (serialize-qp "idCards" $id_cards "scalar") (serialize-qp "modelTypes" $model_types "scalar") (serialize-qp "board_fields" $board_fields "scalar") (serialize-qp "boards_limit" $boards_limit "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "cards_limit" $cards_limit "scalar") (serialize-qp "cards_page" $cards_page "scalar") (serialize-qp "card_board" $card_board "scalar") (serialize-qp "card_list" $card_list "scalar") (serialize-qp "card_members" $card_members "scalar") (serialize-qp "card_stickers" $card_stickers "scalar") (serialize-qp "card_attachments" $card_attachments "scalar") (serialize-qp "organization_fields" $organization_fields "scalar") (serialize-qp "organizations_limit" $organizations_limit "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "members_limit" $members_limit "scalar") (serialize-qp "partial" $partial "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # a string with a length from 1 to 16384
  --limit: string # a number from 1 to 20 (default: 8)
  --id-board: string # An id, or null
  --id-organization: string # An id, or null
  --only-org-members: string # A boolean
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "idBoard" $id_board "scalar") (serialize-qp "idOrganization" $id_organization "scalar") (serialize-qp "onlyOrgMembers" $only_org_members "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --id-board: string # The id of the board you&#39;re viewing.  Boards with no viewers will not get updates about members&#39; statuses.
  --status: string # One of: active, disconnected or idle
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sessions" $qp)
  let body = {"idBoard": $id_board, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sessions/socket" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --id-board: string # The id of the board you&#39;re viewing.  Boards with no viewers will not get updates about members&#39; statuses.
  --status: string # One of: active, disconnected or idle
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_session: $id_session} | format pattern "/sessions/{id_session}") $qp)
  let body = {"idBoard": $id_board, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # One of: active, disconnected or idle
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_session: $id_session} | format pattern "/sessions/{id_session}/status") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/tokens/{token_arg}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getTokensByToken()
#
# GET /tokens/{token}
# operationId: getTokensByToken
export def "tokens list" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: dateCreated, dateExpires, idMember, identifier or permissions (default: all)
  --webhooks: string #  true or false
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "webhooks" $webhooks "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/tokens/{token_arg}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getTokensMemberByToken()
#
# GET /tokens/{token}/member
# operationId: getTokensMemberByToken
export def "tokens-member list" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/tokens/{token_arg}/member") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getTokensMemberByTokenByField()
#
# GET /tokens/{token}/member/{field}
# operationId: getTokensMemberByTokenByField
export def "tokens-member get" [
  token_arg: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: $token_arg, field: $field} | format pattern "/tokens/{token_arg}/member/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getTokensWebhooksByToken()
#
# GET /tokens/{token}/webhooks
# operationId: getTokensWebhooksByToken
export def "tokens-webhooks list" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/tokens/{token_arg}/webhooks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --callback-url: string # A valid URL that is reachable with a HEAD request
  --description: string # a string with a length from 0 to 16384
  --id-model: string # id of the model to be monitored
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/tokens/{token_arg}/webhooks") $qp)
  let body = {"callbackURL": $callback_url, "description": $description, "idModel": $id_model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --callback-url: string # A valid URL that is reachable with a HEAD request
  --description: string # a string with a length from 0 to 16384
  --id-model: string # id of the model to be monitored
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/tokens/{token_arg}/webhooks") $qp)
  let body = {"callbackURL": $callback_url, "description": $description, "idModel": $id_model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteTokensWebhooksByTokenByIdWebhook()
#
# DELETE /tokens/{token}/webhooks/{idWebhook}
# operationId: deleteTokensWebhooksByTokenByIdWebhook
export def "tokens-webhooks delete" [
  token_arg: string
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: $token_arg, id_webhook: $id_webhook} | format pattern "/tokens/{token_arg}/webhooks/{id_webhook}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getTokensWebhooksByTokenByIdWebhook()
#
# GET /tokens/{token}/webhooks/{idWebhook}
# operationId: getTokensWebhooksByTokenByIdWebhook
export def "tokens-webhooks get" [
  token_arg: string
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: $token_arg, id_webhook: $id_webhook} | format pattern "/tokens/{token_arg}/webhooks/{id_webhook}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getTokensByTokenByField()
#
# GET /tokens/{token}/{field}
# operationId: getTokensByTokenByField
export def "tokens get" [
  token_arg: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: $token_arg, field: $field} | format pattern "/tokens/{token_arg}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/types/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --active: string #  true or false
  --callback-url: string # A valid URL that is reachable with a HEAD request
  --description: string # a string with a length from 0 to 16384
  --id-model: string # id of the model that should be hooked
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks" $qp)
  let body = {"active": $active, "callbackURL": $callback_url, "description": $description, "idModel": $id_model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --active: string #  true or false
  --callback-url: string # A valid URL that is reachable with a HEAD request
  --description: string # a string with a length from 0 to 16384
  --id-model: string # id of the model that should be hooked
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks/" $qp)
  let body = {"active": $active, "callbackURL": $callback_url, "description": $description, "idModel": $id_model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: $id_webhook} | format pattern "/webhooks/{id_webhook}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getWebhooksByIdWebhook()
#
# GET /webhooks/{idWebhook}
# operationId: getWebhooksByIdWebhook
export def "webhooks list" [
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: $id_webhook} | format pattern "/webhooks/{id_webhook}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --active: string #  true or false
  --callback-url: string # A valid URL that is reachable with a HEAD request
  --description: string # a string with a length from 0 to 16384
  --id-model: string # id of the model that should be hooked
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: $id_webhook} | format pattern "/webhooks/{id_webhook}") $qp)
  let body = {"active": $active, "callbackURL": $callback_url, "description": $description, "idModel": $id_model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string #  true or false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: $id_webhook} | format pattern "/webhooks/{id_webhook}/active") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # A valid URL that is reachable with a HEAD request
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: $id_webhook} | format pattern "/webhooks/{id_webhook}/callbackURL") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: $id_webhook} | format pattern "/webhooks/{id_webhook}/description") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
  --value: string # id of the model to be monitored
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: $id_webhook} | format pattern "/webhooks/{id_webhook}/idModel") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getWebhooksByIdWebhookByField()
#
# GET /webhooks/{idWebhook}/{field}
# operationId: getWebhooksByIdWebhookByField
export def "webhooks get" [
  id_webhook: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # <a href="https://trello.com/1/appKey/generate"  target="_blank">Generate your application key</a>
  --qp-token: string # <a href="https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user"  target="_blank">Getting a token from a user</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: $id_webhook, field: $field} | format pattern "/webhooks/{id_webhook}/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
