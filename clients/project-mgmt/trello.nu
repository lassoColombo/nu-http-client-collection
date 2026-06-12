# Auto-generated client for Trello REST API v0.0.1
# Source: https://developer.atlassian.com/cloud/trello/swagger.v3.json
# Auth: --token flag or $env.TRELLO_REST_API_TOKEN

const BASE_URL = "https://api.trello.com/1"
const DEFAULT_AUTH = "query-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TRELLO_REST_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.trello.com/1"] }
def auth-scheme-completer [] { ["query-key" "query-token"] }

# Completers for enum parameters
def fields-completer [] { ["closed" "desc" "descData" "enterpriseOwned" "id" "idMemberCreator" "idOrganization" "labelNames" "limits" "memberships" "name" "pinned" "prefs" "shortUrl" "starred" "url"] }
def fields-completer-1 [] { ["address" "badges" "checkItemStates" "closed" "coordinates" "cover" "creationMethod" "dateLastActivity" "desc" "descData" "due" "dueComplete" "dueReminder" "id" "idAttachmentCover" "idBoard" "idChecklists" "idLabels" "idList" "idMembers" "idMembersVoted" "idShort" "isTemplate" "labels" "limits" "locationName" "manualCoverAttachment" "name" "pos" "shortLink" "shortUrl" "subscribed" "url"] }
def fields-completer-2 [] { ["id"] }
def fields-completer-3 [] { ["id" "name"] }
def filter-completer [] { ["admins" "all" "none" "normal"] }
def member-fields-completer [] { ["id"] }
def cards-completer [] { ["all" "closed" "none" "open"] }
def filter-completer-1 [] { ["all" "closed" "none" "open"] }
def type-completer [] { ["admin" "normal" "observer"] }
def member-fields-completer-1 [] { ["all" "avatarHash" "bio" "bioData" "confirmed" "fullName" "idPremOrgsAdmin" "initials" "memberType" "products" "status" "url" "username"] }
def value-completer [] { ["bottom" "top"] }
def keepFromSource-completer [] { ["cards" "none"] }
def powerUps-completer [] { ["all" "calendar" "cardAging" "recap" "voting"] }
def prefs-permissionLevel-completer [] { ["org" "private" "public"] }
def prefs-voting-completer [] { ["disabled" "members" "observers" "org" "public"] }
def prefs-comments-completer [] { ["disabled" "members" "observers" "org" "public"] }
def prefs-invitations-completer [] { ["admins" "members"] }
def prefs-background-completer [] { ["blue" "green" "grey" "lime" "orange" "pink" "purple" "red" "sky"] }
def prefs-cardAging-completer [] { ["pirate" "regular"] }
def filter-completer-2 [] { ["available" "enabled"] }
def keepFromSource-completer-1 [] { ["all" "attachments" "checklists" "comments" "customFields" "due" "labels" "members" "start" "start" "stickers"] }
def cardRole-completer [] { ["board" "link" "mirror" "separator"] }
def checkItems-completer [] { ["all" "none"] }
def checkItem-fields-completer [] { ["due" "dueReminder" "idMember" "name" "nameData" "pos" "state" "type"] }
def filter-completer-3 [] { ["all" "none"] }
def fields-completer-4 [] { ["all" "name" "nameData" "pos" "state" "type"] }
def state-completer [] { ["complete" "incomplete"] }
def cards-completer-1 [] { ["all" "closed" "none" "open" "visible"] }
def checkItem-fields-completer-1 [] { ["all" "due" "dueReminder" "idMember" "name" "nameData" "pos" "state" "type"] }
def fields-completer-5 [] { ["all" "name"] }
def fields-completer-6 [] { ["all" "due" "dueReminder" "idMember" "name" "nameData" "pos" "state" "type"] }
def modelType-completer [] { ["board"] }
def type-completer-1 [] { ["checkbox" "date" "list" "number" "text"] }
def sortOrder-completer [] { ["" "asc" "ascending" "desc" "descending"] }
def organization-fields-completer [] { ["id" "name"] }
def board-fields-completer [] { ["closed" "desc" "descData" "enterpriseOwned" "id" "idMemberCreator" "idOrganization" "labelNames" "limits" "memberships" "name" "pinned" "prefs" "shortUrl" "starred" "url"] }
def color-completer [] { ["black" "blue" "green" "lime" "orange" "pink" "purple" "red" "sky" "yellow"] }
def boardBackgrounds-completer [] { ["all" "custom" "default" "none" "premium"] }
def boardsInvited-completer [] { ["closed" "members" "open" "organization" "pinned" "public" "starred" "unpinned"] }
def boardsInvited-fields-completer [] { ["closed" "desc" "descData" "enterpriseOwned" "id" "idMemberCreator" "idOrganization" "labelNames" "limits" "memberships" "name" "pinned" "prefs" "shortUrl" "starred" "url"] }
def customBoardBackgrounds-completer [] { ["all" "none"] }
def customEmoji-completer [] { ["all" "none"] }
def customStickers-completer [] { ["all" "none"] }
def organizations-completer [] { ["all" "members" "none" "public"] }
def organizationsInvited-completer [] { ["all" "members" "none" "public"] }
def organizationsInvited-fields-completer [] { ["id" "name"] }
def tokens-completer [] { ["all" "none"] }
def avatarSource-completer [] { ["gravatar" "none" "upload"] }
def filter-completer-4 [] { ["all" "custom" "default" "none" "premium"] }
def fields-completer-7 [] { ["all" "brightness" "fullSizeUrl" "scaled" "tile"] }
def brightness-completer [] { ["dark" "light" "unknown"] }
def filter-completer-5 [] { ["all" "closed" "members" "open" "organization" "public" "starred"] }
def lists-completer [] { ["all" "closed" "none" "open"] }
def filter-completer-6 [] { ["all" "closed" "complete" "incomplete" "none" "open" "visible"] }
def fields-completer-8 [] { ["all" "name" "url"] }
def fields-completer-9 [] { ["all" "scaled" "url"] }
def filter-completer-7 [] { ["all" "members" "none" "public"] }
def channel-completer [] { ["email"] }
def card-fields-completer [] { ["address" "badges" "checkItemStates" "closed" "coordinates" "cover" "creationMethod" "dateLastActivity" "desc" "descData" "due" "dueComplete" "dueReminder" "id" "idAttachmentCover" "idBoard" "idChecklists" "idLabels" "idList" "idMembers" "idMembersVoted" "idShort" "isTemplate" "labels" "limits" "locationName" "manualCoverAttachment" "name" "pos" "shortLink" "shortUrl" "subscribed" "url"] }
def fields-completer-10 [] { ["board" "card" "data" "date" "dateRead" "id" "idAction" "idMemberCreator" "reactions" "type" "unread"] }
def memberCreator-fields-completer [] { ["id"] }
def filter-completer-8 [] { ["all" "closed" "members" "open" "organization" "public"] }
def type-completer-2 [] { ["admin" "normal"] }
def filter-completer-9 [] { ["active" "admin" "all" "deactivated" "me" "normal"] }
def fields-completer-11 [] { ["dateCreated" "dateExpires" "idMember" "identifier" "permissions"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "actions get-actions-id" } } | get name | first)
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

# Get an Action
#
# GET /actions/{id}
# operationId: get-actions-id
export def "actions get-actions-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --display: oneof<nothing, bool> # default: true
  --entities: oneof<nothing, bool> # default: false
  --qp-fields: string # `all` or a comma-separated list of action [fields](/cloud/trello/guides/rest-api/object-definitions/#action-object) (default: all)
  --member: oneof<nothing, bool> # default: true
  --member-fields: string # `all` or a comma-separated list of member [fields](/cloud/trello/guides/rest-api/object-definitions/) (default: avatarHash,fullName,initials,username)
  --memberCreator: oneof<nothing, bool> # Whether to include the member object for the creator of the action (default: true)
  --memberCreator-fields: string # `all` or a comma-separated list of member [fields](/cloud/trello/guides/rest-api/object-definitions/) (default: avatarHash,fullName,initials,username)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "display" $display "scalar") (serialize-qp "entities" $entities "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "memberCreator" $memberCreator "scalar") (serialize-qp "memberCreator_fields" $memberCreator_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/actions/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Action
#
# PUT /actions/{id}
# operationId: put-actions-id
export def "actions put-actions-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # The new text for the comment
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/actions/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Action
#
# DELETE /actions/{id}
# operationId: delete-actions-id
export def "actions delete-actions-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/actions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific field on an Action
#
# GET /actions/{id}/{field}
# operationId: get-actions-id-field
export def "actions get-actions-id-field" [
  id: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, idMemberCreator: string, data: record<text: string, card: record<id: string, name: string, idShort: int, shortLink: string>, board: record<id: string, name: string, shortLink: string>, list: record<id: string, name: string>>, type: string, date: string, limits: record<reactions: record<perAction: record, uniquePerAction: record>>, display: record<translationKey: string, entities: record<contextOn: record, card: record, comment: record, memberCreator: record>>, memberCreator: record<id: string, activityBlocked: bool, avatarHash: string, avatarUrl: string, fullName: string, idMemberReferrer: string, initials: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/actions/($id)/($field)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Board for an Action
#
# GET /actions/{id}/board
# operationId: get-actions-id-board
export def "actions-board get-actions-id-board" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer # `all` or a comma-separated list of board fields
]: nothing -> record<id: string, name: string, desc: string, descData: string, closed: bool, idMemberCreator: string, idOrganization: string, pinned: bool, url: string, shortUrl: string, prefs: record<permissionLevel: string, hideVotes: bool, voting: string, comments: string, invitations: any, selfJoin: bool, cardCovers: bool, isTemplate: bool, cardAging: string, calendarFeedEnabled: bool, background: string, backgroundImage: string, backgroundImageScaled: list<record>, backgroundTile: bool, backgroundBrightness: string, backgroundBottomColor: string, backgroundTopColor: string, canBePublic: bool, canBeEnterprise: bool, canBeOrg: bool, canBePrivate: bool, canInvite: bool>, labelNames: record<green: string, yellow: string, orange: string, red: string, purple: string, blue: string, sky: string, lime: string, pink: string, black: string>, limits: record<attachments: record<perBoard: record>>, starred: bool, memberships: string, shortLink: string, subscribed: bool, powerUps: string, dateLastActivity: string, dateLastView: string, idTags: string, datePluginDisable: string, creationMethod: string, ixUpdate: int, templateGallery: string, enterpriseOwned: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/actions/($id)/board" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Card for an Action
#
# GET /actions/{id}/card
# operationId: get-actions-id-card
export def "actions-card get-actions-id-card" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer-1 # `all` or a comma-separated list of card fields
]: nothing -> record<id: string, address: string, badges: record<attachmentsByType: record<trello: record>, location: bool, votes: int, viewingMemberVoted: bool, subscribed: bool, fogbugz: string, checkItems: int, checkItemsChecked: int, comments: int, attachments: int, description: bool, due: string, start: string, dueComplete: bool>, cardRole: string, checkItemStates: list<any>, closed: bool, coordinates: string, creationMethod: string, dateLastActivity: string, desc: string, descData: record<emoji: record>, due: string, dueReminder: string, idBoard: string, idChecklists: list<any>, idLabels: list<any>, idList: string, idMembers: list<any>, idMembersVoted: list<any>, idShort: int, idAttachmentCover: string, labels: list<any>, limits: record<attachments: record<perBoard: record>>, locationName: string, manualCoverAttachment: bool, mirrorSourceId: string, name: string, pos: float, shortLink: string, shortUrl: string, subscribed: bool, url: string, cover: record<idAttachment: string, color: string, idUploadedBackground: bool, size: string, brightness: string, isTemplate: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/actions/($id)/card" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the List for an Action
#
# GET /actions/{id}/list
# operationId: get-actions-id-list
export def "actions-list get-actions-id-list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer-2 # `all` or a comma-separated list of list fields
]: nothing -> record<id: string, name: string, closed: bool, pos: float, softLimit: string, idBoard: string, subscribed: bool, limits: record<attachments: record<perBoard: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/actions/($id)/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Member of an Action
#
# GET /actions/{id}/member
# operationId: get-actions-id-member
export def "actions-member get-actions-id-member" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer-2 # `all` or a comma-separated list of member fields
]: nothing -> record<id: string, activityBlocked: bool, avatarHash: string, avatarUrl: string, bio: string, bioData: record<emoji: record>, confirmed: bool, fullName: string, idEnterprise: string, idEnterprisesDeactivated: list<string>, idMemberReferrer: string, idPremOrgsAdmin: list<string>, initials: string, memberType: string, nonPublic: record<fullName: string, initials: string, avatarUrl: string, avatarHash: string>, nonPublicAvailable: bool, products: list<int>, url: string, username: string, status: string, aaEmail: string, aaEnrolledDate: string, aaId: string, avatarSource: string, email: string, gravatarHash: string, idBoards: list<string>, idOrganizations: list<string>, idEnterprisesAdmin: list<string>, limits: record<status: string, disableAt: float, warnAt: float>, loginTypes: list<string>, marketingOptIn: record<optedIn: bool, date: string>, messagesDismissed: record<name: string, count: string, lastDismissed: string, _id: string>, oneTimeMessagesDismissed: list<string>, prefs: record<timezoneInfo: record<offsetCurrent: int, timezoneCurrent: string, offsetNext: int, dateNext: string, timezoneNext: string>, privacy: record<fullName: string, avatar: string>, sendSummaries: bool, minutesBetweenSummaries: int, minutesBeforeDeadlineToNotify: int, colorBlind: bool, locale: string, timezone: string, twoFactor: record<enabled: bool, needsNewBackups: bool>>, trophies: list<string>, uploadedAvatarHash: string, uploadedAvatarUrl: string, premiumFeatures: list<string>, isAaMastered: bool, ixUpdate: float, idBoardsPinned: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/actions/($id)/member" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Member Creator of an Action
#
# GET /actions/{id}/memberCreator
# operationId: get-actions-id-membercreator
export def "actions-member-creator get-actions-id-membercreator" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer-2 # `all` or a comma-separated list of member fields
]: nothing -> record<id: string, activityBlocked: bool, avatarHash: string, avatarUrl: string, bio: string, bioData: record<emoji: record>, confirmed: bool, fullName: string, idEnterprise: string, idEnterprisesDeactivated: list<string>, idMemberReferrer: string, idPremOrgsAdmin: list<string>, initials: string, memberType: string, nonPublic: record<fullName: string, initials: string, avatarUrl: string, avatarHash: string>, nonPublicAvailable: bool, products: list<int>, url: string, username: string, status: string, aaEmail: string, aaEnrolledDate: string, aaId: string, avatarSource: string, email: string, gravatarHash: string, idBoards: list<string>, idOrganizations: list<string>, idEnterprisesAdmin: list<string>, limits: record<status: string, disableAt: float, warnAt: float>, loginTypes: list<string>, marketingOptIn: record<optedIn: bool, date: string>, messagesDismissed: record<name: string, count: string, lastDismissed: string, _id: string>, oneTimeMessagesDismissed: list<string>, prefs: record<timezoneInfo: record<offsetCurrent: int, timezoneCurrent: string, offsetNext: int, dateNext: string, timezoneNext: string>, privacy: record<fullName: string, avatar: string>, sendSummaries: bool, minutesBetweenSummaries: int, minutesBeforeDeadlineToNotify: int, colorBlind: bool, locale: string, timezone: string, twoFactor: record<enabled: bool, needsNewBackups: bool>>, trophies: list<string>, uploadedAvatarHash: string, uploadedAvatarUrl: string, premiumFeatures: list<string>, isAaMastered: bool, ixUpdate: float, idBoardsPinned: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/actions/($id)/memberCreator" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Organization of an Action
#
# GET /actions/{id}/organization
# operationId: get-actions-id-organization
export def "actions-organization get-actions-id-organization" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer-3 # `all` or a comma-separated list of organization fields
]: nothing -> record<id: string, name: string, displayName: string, dateLastActivity: string, prefs: record<boardVisibilityRestrict: record, boardDeleteRestrict: record, attachmentRestrictions: list<string>, permissionLevel: string>, idEnterprise: string, offering: string, url: string, idBoards: list<string>, memberships: list<string>, premiumFeatures: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/actions/($id)/organization" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Comment Action
#
# PUT /actions/{id}/text
# operationId: put-actions-id-text
export def "actions-text put-actions-id-text" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # The new text for the comment
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/actions/($id)/text" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Action's Reactions
#
# GET /actions/{idAction}/reactions
# operationId: get-actions-idaction-reactions
export def "actions-reactions get-actions-idaction-reactions" [
  idAction: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --member: oneof<nothing, bool> # Whether to load the member as a nested resource. See [Members Nested Resource](/cloud/trello/guides/rest-api/nested-resources/#members-nested-resource) (default: true)
  --emoji: oneof<nothing, bool> # Whether to load the emoji as a nested resource. (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "member" $member "scalar") (serialize-qp "emoji" $emoji "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/actions/($idAction)/reactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Reaction for Action
#
# POST /actions/{idAction}/reactions
# operationId: post-actions-idaction-reactions
export def "actions-reactions post-actions-idaction-reactions" [
  idAction: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --shortName: string # The primary `shortName` of the emoji to add. See [/emoji](#emoji)
  --skinVariation: string # The `skinVariation` of the emoji to add. See [/emoji](#emoji)
  --native: string # The emoji to add as a native unicode emoji. See [/emoji](#emoji)
  --unified: string # The `unified` value of the emoji to add. See [/emoji](#emoji)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/actions/($idAction)/reactions")
  let body = {shortName: $shortName, skinVariation: $skinVariation, native: $native, unified: $unified} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Action's Reaction
#
# GET /actions/{idAction}/reactions/{id}
# operationId: get-actions-idaction-reactions-id
export def "actions-reactions get-actions-idaction-reactions-id" [
  idAction: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --member: oneof<nothing, bool> # Whether to load the member as a nested resource. See [Members Nested Resource](/cloud/trello/guides/rest-api/nested-resources/#members-nested-resource) (default: true)
  --emoji: oneof<nothing, bool> # Whether to load the emoji as a nested resource. (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "member" $member "scalar") (serialize-qp "emoji" $emoji "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/actions/($idAction)/reactions/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Action's Reaction
#
# DELETE /actions/{idAction}/reactions/{id}
# operationId: delete-actions-idaction-reactions-id
export def "actions-reactions delete-actions-idaction-reactions-id" [
  idAction: string
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/actions/($idAction)/reactions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Action's summary of Reactions
#
# GET /actions/{idAction}/reactionsSummary
# operationId: get-actions-idaction-reactionsummary
export def "actions-reactions-summary get-actions-idaction-reactionsummary" [
  idAction: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/actions/($idAction)/reactionsSummary")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Application's compliance data
#
# GET /applications/{key}/compliance
# operationId: applications-key-compliance
export def "applications-compliance applications-key-compliance" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($key)/compliance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Batch Requests
#
# GET /batch
# operationId: get-batch
export def "batch get-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --urls: string # A list of API routes. Maximum of 10 routes allowed. The routes should begin with a forward slash and should not include the API version number - e.g. "urls=/members/trello,/cards/[cardId]"
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "urls" $urls "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/batch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Memberships of a Board
#
# GET /boards/{id}/memberships
# operationId: get-boards-id-memberships
export def "boards-memberships get-boards-id-memberships" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer # One of `admins`, `all`, `none`, `normal` (default: all)
  --activity: oneof<nothing, bool> # Works for premium organizations only. (default: false)
  --orgMemberType: oneof<nothing, bool> # Shows the type of member to the org the user is. For instance, an org admin will have a `orgMemberType` of `admin`. (default: false)
  --member: oneof<nothing, bool> # Determines whether to include a [nested member object](/cloud/trello/guides/rest-api/nested-resources/). (default: false)
  --member-fields: string@member-fields-completer # Fields to show if `member=true`. Valid values: [nested member resource fields](/cloud/trello/guides/rest-api/nested-resources/).
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "activity" $activity "scalar") (serialize-qp "orgMemberType" $orgMemberType "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($id)/memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Board
#
# GET /boards/{id}
# operationId: get-boards-id
export def "boards get-boards-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # This is a nested resource. Read more about actions as nested resources [here](/cloud/trello/guides/rest-api/nested-resources/). (default: all)
  --boardStars: string # Valid values are one of: `mine` or `none`. (default: none)
  --cards: string # This is a nested resource. Read more about cards as nested resources [here](/cloud/trello/guides/rest-api/nested-resources/). (default: none)
  --card-pluginData: oneof<nothing, bool> # Use with the `cards` param to include card pluginData with the response (default: false)
  --checklists: string # This is a nested resource. Read more about checklists as nested resources [here](/cloud/trello/guides/rest-api/nested-resources/). (default: none)
  --customFields: oneof<nothing, bool> # This is a nested resource. Read more about custom fields as nested resources [here](#custom-fields-nested-resource). (default: false)
  --qp-fields: string # The fields of the board to be included in the response. Valid values: all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idMemberCreator, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed, url (default: name,desc,descData,closed,idOrganization,pinned,url,shortUrl,prefs,labelNames)
  --labels: string # This is a nested resource. Read more about labels as nested resources [here](/cloud/trello/guides/rest-api/nested-resources/).
  --lists: string # This is a nested resource. Read more about lists as nested resources [here](/cloud/trello/guides/rest-api/nested-resources/). (default: open)
  --members: string # This is a nested resource. Read more about members as nested resources [here](/cloud/trello/guides/rest-api/nested-resources/). (default: none)
  --memberships: string # This is a nested resource. Read more about memberships as nested resources [here](/cloud/trello/guides/rest-api/nested-resources/). (default: none)
  --pluginData: oneof<nothing, bool> # Determines whether the pluginData for this board should be returned. Valid values: true or false. (default: false)
  --organization: oneof<nothing, bool> # This is a nested resource. Read more about organizations as nested resources [here](/cloud/trello/guides/rest-api/nested-resources/). (default: false)
  --organization-pluginData: oneof<nothing, bool> # Use with the `organization` param to include organization pluginData with the response (default: false)
  --myPrefs: oneof<nothing, bool> # default: false
  --tags: oneof<nothing, bool> # Also known as collections, tags, refer to the collection(s) that a Board belongs to. (default: false)
]: nothing -> record<id: string, name: string, desc: string, descData: string, closed: bool, idMemberCreator: string, idOrganization: string, pinned: bool, url: string, shortUrl: string, prefs: record<permissionLevel: string, hideVotes: bool, voting: string, comments: string, invitations: any, selfJoin: bool, cardCovers: bool, isTemplate: bool, cardAging: string, calendarFeedEnabled: bool, background: string, backgroundImage: string, backgroundImageScaled: list<record>, backgroundTile: bool, backgroundBrightness: string, backgroundBottomColor: string, backgroundTopColor: string, canBePublic: bool, canBeEnterprise: bool, canBeOrg: bool, canBePrivate: bool, canInvite: bool>, labelNames: record<green: string, yellow: string, orange: string, red: string, purple: string, blue: string, sky: string, lime: string, pink: string, black: string>, limits: record<attachments: record<perBoard: record>>, starred: bool, memberships: string, shortLink: string, subscribed: bool, powerUps: string, dateLastActivity: string, dateLastView: string, idTags: string, datePluginDisable: string, creationMethod: string, ixUpdate: int, templateGallery: string, enterpriseOwned: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "boardStars" $boardStars "scalar") (serialize-qp "cards" $cards "scalar") (serialize-qp "card_pluginData" $card_pluginData "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "customFields" $customFields "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "lists" $lists "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "memberships" $memberships "scalar") (serialize-qp "pluginData" $pluginData "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "organization_pluginData" $organization_pluginData "scalar") (serialize-qp "myPrefs" $myPrefs "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Board
#
# PUT /boards/{id}
# operationId: put-boards-id
export def "boards put-boards-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name for the board. 1 to 16384 characters long.
  --desc: string # A new description for the board, 0 to 16384 characters long
  --closed: oneof<nothing, bool> # Whether the board is closed
  --subscribed: string # Whether the acting user is subscribed to the board (e.g. 5abbe4b7ddc1b351ef961414)
  --idOrganization: string # The id of the Workspace the board should be moved to
  --prefspermissionLevel: string # One of: org, private, public
  --prefsselfJoin: oneof<nothing, bool> # Whether Workspace members can join the board themselves
  --prefscardCovers: oneof<nothing, bool> # Whether card covers should be displayed on this board
  --prefshideVotes: oneof<nothing, bool> # Determines whether the Voting Power-Up should hide who voted on cards or not.
  --prefsinvitations: string # Who can invite people to this board. One of: admins, members
  --prefsvoting: string # Who can vote on this board. One of disabled, members, observers, org, public
  --prefscomments: string # Who can comment on cards on this board. One of: disabled, members, observers, org, public
  --prefsbackground: string # The id of a custom background or one of: blue, orange, green, red, purple, pink, lime, sky, grey
  --prefscardAging: string # One of: pirate, regular
  --prefscalendarFeedEnabled: oneof<nothing, bool> # Determines whether the calendar feed is enabled or not.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "closed" $closed "scalar") (serialize-qp "subscribed" $subscribed "scalar") (serialize-qp "idOrganization" $idOrganization "scalar") (serialize-qp "prefs/permissionLevel" $prefspermissionLevel "scalar") (serialize-qp "prefs/selfJoin" $prefsselfJoin "scalar") (serialize-qp "prefs/cardCovers" $prefscardCovers "scalar") (serialize-qp "prefs/hideVotes" $prefshideVotes "scalar") (serialize-qp "prefs/invitations" $prefsinvitations "scalar") (serialize-qp "prefs/voting" $prefsvoting "scalar") (serialize-qp "prefs/comments" $prefscomments "scalar") (serialize-qp "prefs/background" $prefsbackground "scalar") (serialize-qp "prefs/cardAging" $prefscardAging "scalar") (serialize-qp "prefs/calendarFeedEnabled" $prefscalendarFeedEnabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Board
#
# DELETE /boards/{id}
# operationId: delete-boards-id
export def "boards delete-boards-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/boards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a field on a Board
#
# GET /boards/{id}/{field}
# operationId: get-boards-id-field
export def "boards get-boards-id-field" [
  id: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/boards/($id)/($field)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Actions of a Board
#
# GET /boards/{boardId}/actions
# operationId: get-boards-id-actions
export def "boards-actions get-boards-id-actions" [
  boardId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: record # The fields to be returned for the Actions. [See Action fields here](/cloud/trello/guides/rest-api/object-definitions/#action-object).
  --filter: string # A comma-separated list of [action types](/cloud/trello/guides/rest-api/action-types/).
  --format: string # The format of the returned Actions. Either list or count. (default: list)
  --idModels: string # A comma-separated list of idModels. Only actions related to these models will be returned.
  --limit: float # The limit of the number of responses, between 0 and 1000. (default: 50)
  --member: oneof<nothing, bool> # Whether to return the member object for each action. (default: true)
  --member-fields: string # The fields of the [member](/cloud/trello/guides/rest-api/object-definitions/#member-object) to return. (default: activityBlocked,avatarHash,avatarUrl,fullName,idMemberReferrer,initials,nonPublic,nonPublicAvailable,username)
  --memberCreator: oneof<nothing, bool> # Whether to return the memberCreator object for each action. (default: true)
  --memberCreator-fields: string # The fields of the [member](/cloud/trello/guides/rest-api/object-definitions/#member-object) creator to return (default: activityBlocked,avatarHash,avatarUrl,fullName,idMemberReferrer,initials,nonPublic,nonPublicAvailable,username)
  --page: float # The page of results for actions. (default: 0)
  --reactions: oneof<nothing, bool> # Whether to show reactions on comments or not.
  --before: string # A date string in the form of YYYY-MM-DDThh:mm:ssZ or a mongo object ID. Only objects created before this date will be returned.
  --since: string # A date string in the form of YYYY-MM-DDThh:mm:ssZ or a mongo object ID. Only objects created since this date will be returned.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi") (serialize-qp "filter" $filter "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "idModels" $idModels "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "memberCreator" $memberCreator "scalar") (serialize-qp "memberCreator_fields" $memberCreator_fields "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "reactions" $reactions "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($boardId)/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get boardStars on a Board
#
# GET /boards/{boardId}/boardStars
# operationId: get-boards-id-boardstars
export def "boards-board-stars get-boards-id-boardstars" [
  boardId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Valid values: mine, none (default: mine)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($boardId)/boardStars" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Checklists on a Board
#
# GET /boards/{id}/checklists
# operationId: boards-id-checklists
export def "boards-checklists boards-id-checklists" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/boards/($id)/checklists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Cards on a Board
#
# GET /boards/{id}/cards
# operationId: get-boards-id-cards
export def "boards-cards get-boards-id-cards" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/boards/($id)/cards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get filtered Cards on a Board
#
# GET /boards/{id}/cards/{filter}
# operationId: get-boards-id-cards-filter
export def "boards-cards get-boards-id-cards-filter" [
  id: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/boards/($id)/cards/($filter)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Custom Fields for Board
#
# GET /boards/{id}/customFields
# operationId: get-boards-id-customfields
export def "boards-custom-fields get-boards-id-customfields" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, idModel: string, modelType: string, fieldGroup: string, display: record<cardFront: bool, name: string, pos: string, options: list>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/boards/($id)/customFields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Labels on a Board
#
# GET /boards/{id}/labels
# operationId: get-boards-id-labels
export def "boards-labels get-boards-id-labels" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: record # The fields to be returned for the Labels.
  --limit: int # The number of Labels to be returned. (format: int32, default: 50)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($id)/labels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Label on a Board
#
# POST /boards/{id}/labels
# operationId: post-boards-id-labels
export def "boards-labels post-boards-id-labels" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the label to be created. 1 to 16384 characters long.
  --color: string # Sets the color of the new label. Valid values are a label color or `null`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "color" $color "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($id)/labels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Lists on a Board
#
# GET /boards/{id}/lists
# operationId: get-boards-id-lists
export def "boards-lists get-boards-id-lists" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cards: string@cards-completer # Filter to apply to Cards.
  --card-fields: string # `all` or a comma-separated list of card [fields](/cloud/trello/guides/rest-api/object-definitions/#card-object) (default: all)
  --filter: string@filter-completer-1 # Filter to apply to Lists
  --qp-fields: string # `all` or a comma-separated list of list [fields](/cloud/trello/guides/rest-api/object-definitions/) (default: all)
]: nothing -> table<id: string, name: string, closed: bool, pos: float, softLimit: string, idBoard: string, subscribed: bool, limits: record<attachments: record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cards" $cards "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($id)/lists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a List on a Board
#
# POST /boards/{id}/lists
# operationId: post-boards-id-lists
export def "boards-lists post-boards-id-lists" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the list to be created. 1 to 16384 characters long.
  --pos: string # Determines the position of the list. Valid values: `top`, `bottom`, or a positive number. (default: top)
]: nothing -> record<id: string, name: string, closed: bool, pos: float, softLimit: string, idBoard: string, subscribed: bool, limits: record<attachments: record<perBoard: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "pos" $pos "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($id)/lists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get filtered Lists on a Board
#
# GET /boards/{id}/lists/{filter}
# operationId: get-boards-id-lists-filter
export def "boards-lists get-boards-id-lists-filter" [
  id: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/boards/($id)/lists/($filter)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Members of a Board
#
# GET /boards/{id}/members
# operationId: get-boards-id-members
export def "boards-members get-boards-id-members" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/boards/($id)/members")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invite Member to Board via email
#
# PUT /boards/{id}/members
# operationId: put-boards-id-members
export def "boards-members put-boards-id-members" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address of a user to add as a member of the board. (format: email)
  --type: string@type-completer # Valid values: admin, normal, observer. Determines what type of member the user being added should be of the board. (default: normal)
  --fullName: string # The full name of the user to as a member of the board. Must have a length of at least 1 and cannot begin nor end with a space.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($id)/members" $qp)
  let body = {fullName: $fullName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a Member to a Board
#
# PUT /boards/{id}/members/{idMember}
# operationId: put-boards-id-members-idmember
export def "boards-members put-boards-id-members-idmember" [
  id: string
  idMember: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # One of: admin, normal, observer. Determines the type of member this user will be on the board.
  --allowBillableGuest: oneof<nothing, bool> # Optional param that allows organization admins to add multi-board guests onto a board. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "allowBillableGuest" $allowBillableGuest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($id)/members/($idMember)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove Member from Board
#
# DELETE /boards/{id}/members/{idMember}
# operationId: boardsidmembersidmember
export def "boards-members boardsidmembersidmember" [
  id: string
  idMember: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/boards/($id)/members/($idMember)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Membership of Member on a Board
#
# PUT /boards/{id}/memberships/{idMembership}
# operationId: put-boards-id-memberships-idmembership
export def "boards-memberships put-boards-id-memberships-idmembership" [
  id: string
  idMembership: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # One of: admin, normal, observer. Determines the type of member that this membership will be to this board.
  --member-fields: string@member-fields-completer-1 # Valid values: all, avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url, username (default: fullName, username)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "member_fields" $member_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($id)/memberships/($idMembership)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update emailPosition Pref on a Board
#
# PUT /boards/{id}/myPrefs/emailPosition
# operationId: put-boards-id-myprefs-emailposition
export def "boards-my-prefs-email-position put-boards-id-myprefs-emailposition" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string@value-completer # Valid values: bottom, top. Determines the position of the email address.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($id)/myPrefs/emailPosition" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update idEmailList Pref on a Board
#
# PUT /boards/{id}/myPrefs/idEmailList
# operationId: put-boards-id-myprefs-idemaillist
export def "boards-my-prefs-id-email-list put-boards-id-myprefs-idemaillist" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # The id of an email list. (e.g. 5abbe4b7ddc1b351ef961414)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($id)/myPrefs/idEmailList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update showSidebar Pref on a Board
#
# PUT /boards/{id}/myPrefs/showSidebar
# operationId: put-boards-id-myPrefs-showsidebar
export def "boards-my-prefs-show-sidebar put-boards-id-myPrefs-showsidebar" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: oneof<nothing, bool> # Determines whether to show the side bar.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($id)/myPrefs/showSidebar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update showSidebarActivity Pref on a Board
#
# PUT /boards/{id}/myPrefs/showSidebarActivity
# operationId: put-boards-id-myPrefs-showsidebaractivity
export def "boards-my-prefs-show-sidebar-activity put-boards-id-myPrefs-showsidebaractivity" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: oneof<nothing, bool> # Determines whether to show sidebar activity.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($id)/myPrefs/showSidebarActivity" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update showSidebarBoardActions Pref on a Board
#
# PUT /boards/{id}/myPrefs/showSidebarBoardActions
# operationId: put-boards-id-myPrefs-showsidebarboardactions
export def "boards-my-prefs-show-sidebar-board-actions put-boards-id-myPrefs-showsidebarboardactions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: oneof<nothing, bool> # Determines whether to show the sidebar board actions.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($id)/myPrefs/showSidebarBoardActions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update showSidebarMembers Pref on a Board
#
# PUT /boards/{id}/myPrefs/showSidebarMembers
# operationId: put-boards-id-myPrefs-showsidebarmembers
export def "boards-my-prefs-show-sidebar-members put-boards-id-myPrefs-showsidebarmembers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: oneof<nothing, bool> # Determines whether to show members of the board in the sidebar.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($id)/myPrefs/showSidebarMembers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Board
#
# POST /boards/
# operationId: post-boards
export def "boards post-boards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name for the board. 1 to 16384 characters long.
  --defaultLabels: oneof<nothing, bool> # Determines whether to use the default set of labels. (default: true)
  --defaultLists: oneof<nothing, bool> # Determines whether to add the default set of lists to a board (To Do, Doing, Done). It is ignored if `idBoardSource` is provided. (default: true)
  --desc: string # A new description for the board, 0 to 16384 characters long
  --idOrganization: string # The id or name of the Workspace the board should belong to. (e.g. 5abbe4b7ddc1b351ef961414)
  --idBoardSource: string # The id of a board to copy into the new board. (e.g. 5abbe4b7ddc1b351ef961414)
  --keepFromSource: string@keepFromSource-completer # To keep cards from the original board pass in the value `cards` (default: none)
  --powerUps: string@powerUps-completer # The Power-Ups that should be enabled on the new board. One of: `all`, `calendar`, `cardAging`, `recap`, `voting`.
  --prefs-permissionLevel: string@prefs-permissionLevel-completer # The permissions level of the board. One of: `org`, `private`, `public`. (default: private)
  --prefs-voting: string@prefs-voting-completer # Who can vote on this board. One of `disabled`, `members`, `observers`, `org`, `public`. (default: disabled)
  --prefs-comments: string@prefs-comments-completer # Who can comment on cards on this board. One of: `disabled`, `members`, `observers`, `org`, `public`. (default: members)
  --prefs-invitations: string@prefs-invitations-completer # Determines what types of members can invite users to join. One of: `admins`, `members`. (default: members)
  --prefs-selfJoin: oneof<nothing, bool> # Determines whether users can join the boards themselves or whether they have to be invited. (default: true)
  --prefs-cardCovers: oneof<nothing, bool> # Determines whether card covers are enabled. (default: true)
  --prefs-background: string@prefs-background-completer # The id of a custom background or one of: `blue`, `orange`, `green`, `red`, `purple`, `pink`, `lime`, `sky`, `grey`. (default: blue)
  --prefs-cardAging: string@prefs-cardAging-completer # Determines the type of card aging that should take place on the board if card aging is enabled. One of: `pirate`, `regular`. (default: regular)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "defaultLabels" $defaultLabels "scalar") (serialize-qp "defaultLists" $defaultLists "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "idOrganization" $idOrganization "scalar") (serialize-qp "idBoardSource" $idBoardSource "scalar") (serialize-qp "keepFromSource" $keepFromSource "scalar") (serialize-qp "powerUps" $powerUps "scalar") (serialize-qp "prefs_permissionLevel" $prefs_permissionLevel "scalar") (serialize-qp "prefs_voting" $prefs_voting "scalar") (serialize-qp "prefs_comments" $prefs_comments "scalar") (serialize-qp "prefs_invitations" $prefs_invitations "scalar") (serialize-qp "prefs_selfJoin" $prefs_selfJoin "scalar") (serialize-qp "prefs_cardCovers" $prefs_cardCovers "scalar") (serialize-qp "prefs_background" $prefs_background "scalar") (serialize-qp "prefs_cardAging" $prefs_cardAging "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boards/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a calendarKey for a Board
#
# POST /boards/{id}/calendarKey/generate
# operationId: post-boards-id-calendarkey-generate
export def "boards-calendar-key-generate post-boards-id-calendarkey-generate" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/boards/($id)/calendarKey/generate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a emailKey for a Board
#
# POST /boards/{id}/emailKey/generate
# operationId: post-boards-id-emailkey-generate
export def "boards-email-key-generate post-boards-id-emailkey-generate" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/boards/($id)/emailKey/generate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Tag for a Board
#
# POST /boards/{id}/idTags
# operationId: post-boards-id-idtags
export def "boards-id-tags post-boards-id-idtags" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # The id of a tag from the organization to which this board belongs. (e.g. 5abbe4b7ddc1b351ef961414)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($id)/idTags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Mark Board as viewed
#
# POST /boards/{id}/markedAsViewed
# operationId: post-boards-id-markedasviewed
export def "boards-marked-as-viewed post-boards-id-markedasviewed" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/boards/($id)/markedAsViewed")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Enabled Power-Ups on Board
#
# GET /boards/{id}/boardPlugins
# operationId: get-boards-id-boardplugins
export def "boards-board-plugins get-boards-id-boardplugins" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/boards/($id)/boardPlugins")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a Power-Up on a Board
#
# POST /boards/{id}/boardPlugins
# DEPRECATED
# operationId: post-boards-id-boardplugins
@deprecated
export def "boards-board-plugins post-boards-id-boardplugins" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idPlugin: string # The ID of the Power-Up to enable (e.g. 5abbe4b7ddc1b351ef961414)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "idPlugin" $idPlugin "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($id)/boardPlugins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable a Power-Up on a Board
#
# DELETE /boards/{id}/boardPlugins/{idPlugin}
# DEPRECATED
# operationId: delete-boards-id-boardplugins
@deprecated
export def "boards-board-plugins delete-boards-id-boardplugins" [
  id: string
  idPlugin: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/boards/($id)/boardPlugins/($idPlugin)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Power-Ups on a Board
#
# GET /boards/{id}/plugins
# operationId: get-board-id-plugins
export def "boards-plugins get-board-id-plugins" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-2 # One of: `enabled` or `available` (default: enabled)
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($id)/plugins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Card
#
# POST /cards
# operationId: post-cards
export def "cards post-cards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name for the card
  --desc: string # The description for the card
  --pos: string # The position of the new card. `top`, `bottom`, or a positive float
  --due: string # A due date for the card (format: date)
  --start: string # The start date of a card, or `null` (nullable, format: date)
  --dueComplete: oneof<nothing, bool> # Whether the status of the card is complete
  --idList: string # The ID of the list the card should be created in (e.g. 5abbe4b7ddc1b351ef961414)
  --idMembers: list # Comma-separated list of member IDs to add to the card
  --idLabels: list # Comma-separated list of label IDs to add to the card
  --urlSource: string # A URL starting with `http://` or `https://`. The URL will be attached to the card upon creation. (format: url)
  --fileSource: string # format: binary
  --mimeType: string # The mimeType of the attachment. Max length 256
  --idCardSource: string # The ID of a card to copy into the new card (e.g. 5abbe4b7ddc1b351ef961414)
  --keepFromSource: string@keepFromSource-completer-1 # If using `idCardSource` you can specify which properties to copy over. `all` or comma-separated list of: `attachments,checklists,customFields,comments,due,start,labels,members,start,stickers` (default: all)
  --address: string # For use with/by the Map View
  --locationName: string # For use with/by the Map View
  --coordinates: string # For use with/by the Map View. Should take the form latitude,longitude
  --cardRole: string@cardRole-completer # For displaying cards in different ways based on the card name. Board cards must have a name that is a link to a Trello board. Mirror cards must have a name that is a link to a Trello card. (nullable)
]: nothing -> record<id: string, address: string, badges: record<attachmentsByType: record<trello: record>, location: bool, votes: int, viewingMemberVoted: bool, subscribed: bool, fogbugz: string, checkItems: int, checkItemsChecked: int, comments: int, attachments: int, description: bool, due: string, start: string, dueComplete: bool>, cardRole: string, checkItemStates: list<any>, closed: bool, coordinates: string, creationMethod: string, dateLastActivity: string, desc: string, descData: record<emoji: record>, due: string, dueReminder: string, idBoard: string, idChecklists: list<any>, idLabels: list<any>, idList: string, idMembers: list<any>, idMembersVoted: list<any>, idShort: int, idAttachmentCover: string, labels: list<any>, limits: record<attachments: record<perBoard: record>>, locationName: string, manualCoverAttachment: bool, mirrorSourceId: string, name: string, pos: float, shortLink: string, shortUrl: string, subscribed: bool, url: string, cover: record<idAttachment: string, color: string, idUploadedBackground: bool, size: string, brightness: string, isTemplate: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "pos" $pos "scalar") (serialize-qp "due" $due "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "dueComplete" $dueComplete "scalar") (serialize-qp "idList" $idList "scalar") (serialize-qp "idMembers" $idMembers "multi") (serialize-qp "idLabels" $idLabels "multi") (serialize-qp "urlSource" $urlSource "scalar") (serialize-qp "fileSource" $fileSource "scalar") (serialize-qp "mimeType" $mimeType "scalar") (serialize-qp "idCardSource" $idCardSource "scalar") (serialize-qp "keepFromSource" $keepFromSource "scalar") (serialize-qp "address" $address "scalar") (serialize-qp "locationName" $locationName "scalar") (serialize-qp "coordinates" $coordinates "scalar") (serialize-qp "cardRole" $cardRole "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Card
#
# GET /cards/{id}
# operationId: get-cards-id
export def "cards get-cards-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # `all` or a comma-separated list of [fields](/cloud/trello/guides/rest-api/object-definitions/). **Defaults**: `badges, checkItemStates, closed, dateLastActivity, desc, descData, due, start, idBoard, idChecklists, idLabels, idList, idMembers, idShort, idAttachmentCover, manualCoverAttachment, labels, name, pos, shortUrl, url`
  --actions: string # See the [Actions Nested Resource](/cloud/trello/guides/rest-api/nested-resources/#actions-nested-resource)
  --attachments: string # `true`, `false`, or `cover` (default: false)
  --attachment-fields: string # `all` or a comma-separated list of attachment [fields](/cloud/trello/guides/rest-api/object-definitions/) (default: all)
  --members: oneof<nothing, bool> # Whether to return member objects for members on the card (default: false)
  --member-fields: string # `all` or a comma-separated list of member [fields](/cloud/trello/guides/rest-api/object-definitions/). **Defaults**: `avatarHash, fullName, initials, username`
  --membersVoted: oneof<nothing, bool> # Whether to return member objects for members who voted on the card (default: false)
  --memberVoted-fields: string # `all` or a comma-separated list of member [fields](/cloud/trello/guides/rest-api/object-definitions/). **Defaults**: `avatarHash, fullName, initials, username`
  --checkItemStates: oneof<nothing, bool> # default: false
  --checklists: string # Whether to return the checklists on the card. `all` or `none` (default: none)
  --checklist-fields: string # `all` or a comma-separated list of `idBoard,idCard,name,pos` (default: all)
  --board: oneof<nothing, bool> # Whether to return the board object the card is on (default: false)
  --board-fields: string # `all` or a comma-separated list of board [fields](/cloud/trello/guides/rest-api/object-definitions/#board-object). **Defaults**: `name, desc, descData, closed, idOrganization, pinned, url, prefs`
  --list: oneof<nothing, bool> # See the [Lists Nested Resource](/cloud/trello/guides/rest-api/nested-resources/) (default: false)
  --pluginData: oneof<nothing, bool> # Whether to include pluginData on the card with the response (default: false)
  --stickers: oneof<nothing, bool> # Whether to include sticker models with the response (default: false)
  --sticker-fields: string # `all` or a comma-separated list of sticker [fields](/cloud/trello/guides/rest-api/object-definitions/) (default: all)
  --customFieldItems: oneof<nothing, bool> # Whether to include the customFieldItems (default: false)
]: nothing -> record<id: string, address: string, badges: record<attachmentsByType: record<trello: record>, location: bool, votes: int, viewingMemberVoted: bool, subscribed: bool, fogbugz: string, checkItems: int, checkItemsChecked: int, comments: int, attachments: int, description: bool, due: string, start: string, dueComplete: bool>, cardRole: string, checkItemStates: list<any>, closed: bool, coordinates: string, creationMethod: string, dateLastActivity: string, desc: string, descData: record<emoji: record>, due: string, dueReminder: string, idBoard: string, idChecklists: list<any>, idLabels: list<any>, idList: string, idMembers: list<any>, idMembersVoted: list<any>, idShort: int, idAttachmentCover: string, labels: list<any>, limits: record<attachments: record<perBoard: record>>, locationName: string, manualCoverAttachment: bool, mirrorSourceId: string, name: string, pos: float, shortLink: string, shortUrl: string, subscribed: bool, url: string, cover: record<idAttachment: string, color: string, idUploadedBackground: bool, size: string, brightness: string, isTemplate: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "actions" $actions "scalar") (serialize-qp "attachments" $attachments "scalar") (serialize-qp "attachment_fields" $attachment_fields "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "membersVoted" $membersVoted "scalar") (serialize-qp "memberVoted_fields" $memberVoted_fields "scalar") (serialize-qp "checkItemStates" $checkItemStates "scalar") (serialize-qp "checklists" $checklists "scalar") (serialize-qp "checklist_fields" $checklist_fields "scalar") (serialize-qp "board" $board "scalar") (serialize-qp "board_fields" $board_fields "scalar") (serialize-qp "list" $list "scalar") (serialize-qp "pluginData" $pluginData "scalar") (serialize-qp "stickers" $stickers "scalar") (serialize-qp "sticker_fields" $sticker_fields "scalar") (serialize-qp "customFieldItems" $customFieldItems "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Card
#
# PUT /cards/{id}
# operationId: put-cards-id
export def "cards put-cards-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name for the card
  --desc: string # The new description for the card
  --closed: oneof<nothing, bool> # Whether the card should be archived (closed: true)
  --idMembers: string # Comma-separated list of member IDs (e.g. 5abbe4b7ddc1b351ef961414)
  --idAttachmentCover: string # The ID of the image attachment the card should use as its cover, or null for none (e.g. 5abbe4b7ddc1b351ef961414)
  --idList: string # The ID of the list the card should be in (e.g. 5abbe4b7ddc1b351ef961414)
  --idLabels: string # Comma-separated list of label IDs (e.g. 5abbe4b7ddc1b351ef961414)
  --idBoard: string # The ID of the board the card should be on (e.g. 5abbe4b7ddc1b351ef961414)
  --pos: string # The position of the card in its list. `top`, `bottom`, or a positive float
  --due: string # When the card is due, or `null` (nullable, format: date)
  --start: string # The start date of a card, or `null` (nullable, format: date)
  --dueComplete: oneof<nothing, bool> # Whether the status of the card is complete
  --subscribed: oneof<nothing, bool> # Whether the member is should be subscribed to the card
  --address: string # For use with/by the Map View
  --locationName: string # For use with/by the Map View
  --coordinates: string # For use with/by the Map View. Should be latitude,longitude
  --cover: record # Updates the card's cover  | Option | Values | About |  |--------|--------|-------|  | color | `pink`, `yellow`, `lime`, `blue`, `black`, `orange`, `red`, `purple`, `sky`, `green` | Makes the cover a solid color . |  | brightness | `dark`, `light` | Determines whether the text on the cover should be dark or light.  | url | An unsplash URL: https://images.unsplash.com | Used if making an image the cover. Only Unsplash URLs work.  | idAttachment | ID of an attachment on the card | Used if setting an attached image as the cover. |  | size | `normal`, `full` | Determines whether to show the card name on the cover, or below it. |    `brightness` can be sent alongside any of the other parameters, but all of the other parameters are mutually exclusive; you can not have the cover be a `color` and an `idAttachment` at the same time.     On the brightness options, setting it to light will make the text on the card cover dark:  ![](/cloud/trello/images/rest/cards/cover-brightness-dark.png)    And vice versa, setting it to dark will make the text on the card cover light:   ![](/cloud/trello/images/rest/cards/cover-brightness-light.png) 
]: nothing -> record<id: string, address: string, badges: record<attachmentsByType: record<trello: record>, location: bool, votes: int, viewingMemberVoted: bool, subscribed: bool, fogbugz: string, checkItems: int, checkItemsChecked: int, comments: int, attachments: int, description: bool, due: string, start: string, dueComplete: bool>, cardRole: string, checkItemStates: list<any>, closed: bool, coordinates: string, creationMethod: string, dateLastActivity: string, desc: string, descData: record<emoji: record>, due: string, dueReminder: string, idBoard: string, idChecklists: list<any>, idLabels: list<any>, idList: string, idMembers: list<any>, idMembersVoted: list<any>, idShort: int, idAttachmentCover: string, labels: list<any>, limits: record<attachments: record<perBoard: record>>, locationName: string, manualCoverAttachment: bool, mirrorSourceId: string, name: string, pos: float, shortLink: string, shortUrl: string, subscribed: bool, url: string, cover: record<idAttachment: string, color: string, idUploadedBackground: bool, size: string, brightness: string, isTemplate: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "closed" $closed "scalar") (serialize-qp "idMembers" $idMembers "scalar") (serialize-qp "idAttachmentCover" $idAttachmentCover "scalar") (serialize-qp "idList" $idList "scalar") (serialize-qp "idLabels" $idLabels "scalar") (serialize-qp "idBoard" $idBoard "scalar") (serialize-qp "pos" $pos "scalar") (serialize-qp "due" $due "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "dueComplete" $dueComplete "scalar") (serialize-qp "subscribed" $subscribed "scalar") (serialize-qp "address" $address "scalar") (serialize-qp "locationName" $locationName "scalar") (serialize-qp "coordinates" $coordinates "scalar") (serialize-qp "cover" $cover "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Card
#
# DELETE /cards/{id}
# operationId: delete-cards-id
export def "cards delete-cards-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a field on a Card
#
# GET /cards/{id}/{field}
# operationId: get-cards-id-field
export def "cards get-cards-id-field" [
  id: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, address: string, badges: record<attachmentsByType: record<trello: record>, location: bool, votes: int, viewingMemberVoted: bool, subscribed: bool, fogbugz: string, checkItems: int, checkItemsChecked: int, comments: int, attachments: int, description: bool, due: string, start: string, dueComplete: bool>, cardRole: string, checkItemStates: list<any>, closed: bool, coordinates: string, creationMethod: string, dateLastActivity: string, desc: string, descData: record<emoji: record>, due: string, dueReminder: string, idBoard: string, idChecklists: list<any>, idLabels: list<any>, idList: string, idMembers: list<any>, idMembersVoted: list<any>, idShort: int, idAttachmentCover: string, labels: list<any>, limits: record<attachments: record<perBoard: record>>, locationName: string, manualCoverAttachment: bool, mirrorSourceId: string, name: string, pos: float, shortLink: string, shortUrl: string, subscribed: bool, url: string, cover: record<idAttachment: string, color: string, idUploadedBackground: bool, size: string, brightness: string, isTemplate: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($id)/($field)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Actions on a Card
#
# GET /cards/{id}/actions
# operationId: get-cards-id-actions
export def "cards-actions get-cards-id-actions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # A comma-separated list of [action types](https://developer.atlassian.com/cloud/trello/guides/rest-api/action-types/). (default: commentCard, updateCard:idList)
  --page: float # The page of results for actions. Each page of results has 50 actions. (default: 0)
]: nothing -> table<id: string, idMemberCreator: string, data: record<text: string, card: record, board: record, list: record>, type: string, date: string, limits: record<reactions: record>, display: record<translationKey: string, entities: record>, memberCreator: record<id: string, activityBlocked: bool, avatarHash: string, avatarUrl: string, fullName: string, idMemberReferrer: string, initials: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Attachments on a Card
#
# GET /cards/{id}/attachments
# operationId: get-cards-id-attachments
export def "cards-attachments get-cards-id-attachments" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # `all` or a comma-separated list of attachment [fields](/cloud/trello/guides/rest-api/object-definitions/) (default: all)
  --filter: string # Use `cover` to restrict to just the cover attachment (default: false)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Attachment On Card
#
# POST /cards/{id}/attachments
# operationId: post-cards-id-attachments
export def "cards-attachments post-cards-id-attachments" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the attachment. Max length 256.
  --file: string # The file to attach, as multipart/form-data (format: binary)
  --mimeType: string # The mimeType of the attachment. Max length 256
  --qp-url: string # A URL to attach. Must start with `http://` or `https://`
  --setCover: oneof<nothing, bool> # Determines whether to use the new attachment as a cover for the Card. (default: false)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "file" $file "scalar") (serialize-qp "mimeType" $mimeType "scalar") (serialize-qp "url" $qp_url "scalar") (serialize-qp "setCover" $setCover "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an Attachment on a Card
#
# GET /cards/{id}/attachments/{idAttachment}
# operationId: get-cards-id-attachments-idattachment
export def "cards-attachments get-cards-id-attachments-idattachment" [
  id: string
  idAttachment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # The Attachment fields to be included in the response. (default: [all])
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/attachments/($idAttachment)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Attachment on a Card
#
# DELETE /cards/{id}/attachments/{idAttachment}
# operationId: deleted-cards-id-attachments-idattachment
export def "cards-attachments deleted-cards-id-attachments-idattachment" [
  id: string
  idAttachment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($id)/attachments/($idAttachment)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Board the Card is on
#
# GET /cards/{id}/board
# operationId: get-cards-id-board
export def "cards-board get-cards-id-board" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # `all` or a comma-separated list of board [fields](/cloud/trello/guides/rest-api/object-definitions/#board-object) (default: all)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/board" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get checkItems on a Card
#
# GET /cards/{id}/checkItemStates
# operationId: get-cards-id-checkitemstates
export def "cards-check-item-states get-cards-id-checkitemstates" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # `all` or a comma-separated list of: `idCheckItem`, `state` (default: all)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/checkItemStates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Checklists on a Card
#
# GET /cards/{id}/checklists
# operationId: get-cards-id-checklists
export def "cards-checklists get-cards-id-checklists" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --checkItems: string@checkItems-completer # `all` or `none` (default: all)
  --checkItem-fields: string@checkItem-fields-completer # `all` or a comma-separated list of: `name,nameData,pos,state,type,due,dueReminder,idMember` (default: name,nameData,pos,state,due,dueReminder,idMember)
  --filter: string@filter-completer-3 # `all` or `none` (default: all)
  --qp-fields: string@fields-completer-4 # `all` or a comma-separated list of: `idBoard,idCard,name,pos` (default: all)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "checkItems" $checkItems "scalar") (serialize-qp "checkItem_fields" $checkItem_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/checklists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Checklist on a Card
#
# POST /cards/{id}/checklists
# operationId: post-cards-id-checklists
export def "cards-checklists post-cards-id-checklists" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the checklist
  --idChecklistSource: string # The ID of a source checklist to copy into the new one (e.g. 5abbe4b7ddc1b351ef961414)
  --pos: string # The position of the checklist on the card. One of: `top`, `bottom`, or a positive number.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "idChecklistSource" $idChecklistSource "scalar") (serialize-qp "pos" $pos "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/checklists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get checkItem on a Card
#
# GET /cards/{id}/checkItem/{idCheckItem}
# operationId: get-cards-id-checkitem-idcheckitem
export def "cards-check-item get-cards-id-checkitem-idcheckitem" [
  id: string
  idCheckItem: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # `all` or a comma-separated list of `name,nameData,pos,state,type,due,dueReminder,idMember` (default: name,nameData,pos,state,due,dueReminder,idMember)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/checkItem/($idCheckItem)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a checkItem on a Card
#
# PUT /cards/{id}/checkItem/{idCheckItem}
# operationId: put-cards-id-checkitem-idcheckitem
export def "cards-check-item put-cards-id-checkitem-idcheckitem" [
  id: string
  idCheckItem: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name for the checklist item
  --state: string@state-completer # One of: `complete`, `incomplete`
  --idChecklist: string # The ID of the checklist this item is in (e.g. 5abbe4b7ddc1b351ef961414)
  --pos: string # `top`, `bottom`, or a positive float
  --due: string # A due date for the checkitem (format: date)
  --dueReminder: float # A dueReminder for the due date on the checkitem (nullable)
  --idMember: string # The ID of the member to remove from the card (e.g. 5abbe4b7ddc1b351ef961414)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "idChecklist" $idChecklist "scalar") (serialize-qp "pos" $pos "scalar") (serialize-qp "due" $due "scalar") (serialize-qp "dueReminder" $dueReminder "scalar") (serialize-qp "idMember" $idMember "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/checkItem/($idCheckItem)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete checkItem on a Card
#
# DELETE /cards/{id}/checkItem/{idCheckItem}
# operationId: delete-cards-id-checkitem-idcheckitem
export def "cards-check-item delete-cards-id-checkitem-idcheckitem" [
  id: string
  idCheckItem: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($id)/checkItem/($idCheckItem)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the List of a Card
#
# GET /cards/{id}/list
# operationId: get-cards-id-list
export def "cards-list get-cards-id-list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # `all` or a comma-separated list of list [fields](/cloud/trello/guides/rest-api/object-definitions/) (default: all)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Members of a Card
#
# GET /cards/{id}/members
# operationId: get-cards-id-members
export def "cards-members get-cards-id-members" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # `all` or a comma-separated list of member [fields](/cloud/trello/guides/rest-api/object-definitions/) (default: avatarHash,fullName,initials,username)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Members who have voted on a Card
#
# GET /cards/{id}/membersVoted
# operationId: get-cards-id-membersvoted
export def "cards-members-voted get-cards-id-membersvoted" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # `all` or a comma-separated list of member [fields](/cloud/trello/guides/rest-api/object-definitions/) (default: avatarHash,fullName,initials,username)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/membersVoted" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Member vote to Card
#
# POST /cards/{id}/membersVoted
# operationId: cardsidmembersvoted-1
export def "cards-members-voted cardsidmembersvoted-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # The ID of the member to vote 'yes' on the card (e.g. 5abbe4b7ddc1b351ef961414)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/membersVoted" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pluginData on a Card
#
# GET /cards/{id}/pluginData
# operationId: get-cards-id-plugindata
export def "cards-plugin-data get-cards-id-plugindata" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($id)/pluginData")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Stickers on a Card
#
# GET /cards/{id}/stickers
# operationId: get-cards-id-stickers
export def "cards-stickers get-cards-id-stickers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # `all` or a comma-separated list of sticker [fields](/cloud/trello/guides/rest-api/object-definitions/) (default: all)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/stickers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Sticker to a Card
#
# POST /cards/{id}/stickers
# operationId: post-cards-id-stickers
export def "cards-stickers post-cards-id-stickers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --image: string # For custom stickers, the id of the sticker. For default stickers, the string identifier (like 'taco-cool', see below)
  --top: float # The top position of the sticker, from -60 to 100 (format: float)
  --left: float # The left position of the sticker, from -60 to 100 (format: float)
  --zIndex: int # The z-index of the sticker
  --rotate: float # The rotation of the sticker (format: float, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "image" $image "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "left" $left "scalar") (serialize-qp "zIndex" $zIndex "scalar") (serialize-qp "rotate" $rotate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/stickers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Sticker on a Card
#
# GET /cards/{id}/stickers/{idSticker}
# operationId: get-cards-id-stickers-idsticker
export def "cards-stickers get-cards-id-stickers-idsticker" [
  id: string
  idSticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # `all` or a comma-separated list of sticker [fields](/cloud/trello/guides/rest-api/object-definitions/) (default: all)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/stickers/($idSticker)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Sticker on a Card
#
# DELETE /cards/{id}/stickers/{idSticker}
# operationId: delete-cards-id-stickers-idsticker
export def "cards-stickers delete-cards-id-stickers-idsticker" [
  id: string
  idSticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($id)/stickers/($idSticker)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Sticker on a Card
#
# PUT /cards/{id}/stickers/{idSticker}
# operationId: put-cards-id-stickers-idsticker
export def "cards-stickers put-cards-id-stickers-idsticker" [
  id: string
  idSticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: float # The top position of the sticker, from -60 to 100 (format: float)
  --left: float # The left position of the sticker, from -60 to 100 (format: float)
  --zIndex: int # The z-index of the sticker
  --rotate: float # The rotation of the sticker (format: float, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "top" $top "scalar") (serialize-qp "left" $left "scalar") (serialize-qp "zIndex" $zIndex "scalar") (serialize-qp "rotate" $rotate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/stickers/($idSticker)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Comment Action on a Card
#
# PUT /cards/{id}/actions/{idAction}/comments
# operationId: put-cards-id-actions-idaction-comments
export def "cards-actions-comments put-cards-id-actions-idaction-comments" [
  id: string
  idAction: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # The new text for the comment
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/actions/($idAction)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a comment on a Card
#
# DELETE /cards/{id}/actions/{idAction}/comments
# operationId: delete-cards-id-actions-id-comments
export def "cards-actions-comments delete-cards-id-actions-id-comments" [
  id: string
  idAction: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($id)/actions/($idAction)/comments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Custom Field item on Card
#
# PUT /cards/{idCard}/customField/{idCustomField}/item
# operationId: put-cards-idcard-customfield-idcustomfield-item
# --value shape: {text?: string, checked?: bool, date?: string, number?: string}
export def "cards-custom-field-item put-cards-idcard-customfield-idcustomfield-item" [
  idCard: string
  idCustomField: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: record # An object containing the key and value to set for the card's Custom Field value. The key used to set the value should match the type of Custom Field defined. — shape: {text?: string, checked?: bool, date?: string, number?: string}
  --idValue: string # e.g. 5abbe4b7ddc1b351ef961414
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($idCard)/customField/($idCustomField)/item")
  let body = {value: $value, idValue: $idValue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Multiple Custom Field items on Card
#
# PUT /cards/{idCard}/customFields
# operationId: put-cards-idcard-customfields
# --customFieldItems item shape: {idCustomField?: any, value?: record, idValue?: any}
export def "cards-custom-fields put-cards-idcard-customfields" [
  idCard: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customFieldItems: list # An array of objects containing the custom field ID, key and value, and ID of list type option. — item shape: {idCustomField?: any, value?: record, idValue?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($idCard)/customFields")
  let body = {customFieldItems: $customFieldItems} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Custom Field Items for a Card
#
# GET /cards/{id}/customFieldItems
# operationId: get-cards-id-customfielditems
export def "cards-custom-field-items get-cards-id-customfielditems" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, value: record<checked: string>, idCustomField: string, idModel: string, modelType: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($id)/customFieldItems")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new comment to a Card
#
# POST /cards/{id}/actions/comments
# operationId: post-cards-id-actions-comments
export def "cards-actions-comments post-cards-id-actions-comments" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # The comment
]: nothing -> record<id: string, idMemberCreator: string, data: record<text: string, card: record<id: string, name: string, idShort: int, shortLink: string>, board: record<id: string, name: string, shortLink: string>, list: record<id: string, name: string>>, type: string, date: string, limits: record<reactions: record<perAction: record, uniquePerAction: record>>, display: record<translationKey: string, entities: record<contextOn: record, card: record, comment: record, memberCreator: record>>, memberCreator: record<id: string, activityBlocked: bool, avatarHash: string, avatarUrl: string, fullName: string, idMemberReferrer: string, initials: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/actions/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Label to a Card
#
# POST /cards/{id}/idLabels
# operationId: post-cards-id-idlabels
export def "cards-id-labels post-cards-id-idlabels" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # The ID of the label to add (e.g. 5abbe4b7ddc1b351ef961414)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/idLabels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Member to a Card
#
# POST /cards/{id}/idMembers
# operationId: post-cards-id-idmembers
export def "cards-id-members post-cards-id-idmembers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # The ID of the Member to add to the card (e.g. 5abbe4b7ddc1b351ef961414)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/idMembers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Label on a Card
#
# POST /cards/{id}/labels
# operationId: post-cards-id-labels
export def "cards-labels post-cards-id-labels" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --color: string # A valid label color or `null`. See [labels](/cloud/trello/guides/rest-api/object-definitions/)
  --name: string # A name for the label
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "color" $color "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($id)/labels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Mark a Card's Notifications as read
#
# POST /cards/{id}/markAssociatedNotificationsRead
# operationId: post-cards-id-markassociatednotificationsread
export def "cards-mark-associated-notifications-read post-cards-id-markassociatednotificationsread" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($id)/markAssociatedNotificationsRead")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a Label from a Card
#
# DELETE /cards/{id}/idLabels/{idLabel}
# operationId: delete-cards-id-idlabels-idlabel
export def "cards-id-labels delete-cards-id-idlabels-idlabel" [
  id: string
  idLabel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($id)/idLabels/($idLabel)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a Member from a Card
#
# DELETE /cards/{id}/idMembers/{idMember}
# operationId: delete-id-idmembers-idmember
export def "cards-id-members delete-id-idmembers-idmember" [
  id: string
  idMember: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($id)/idMembers/($idMember)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a Member's Vote on a Card
#
# DELETE /cards/{id}/membersVoted/{idMember}
# operationId: delete-cards-id-membersvoted-idmember
export def "cards-members-voted delete-cards-id-membersvoted-idmember" [
  id: string
  idMember: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($id)/membersVoted/($idMember)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Checkitem on Checklist on Card
#
# PUT /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}
# operationId: put-cards-idcard-checklist-idchecklist-checkitem-idcheckitem
export def "cards-checklist-check-item put-cards-idcard-checklist-idchecklist-checkitem-idcheckitem" [
  idCard: string
  idCheckItem: string
  idChecklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pos: string # `top`, `bottom`, or a positive float
]: nothing -> record<idChecklist: string, state: string, id: string, name: string, nameData: string, pos: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pos" $pos "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cards/($idCard)/checklist/($idChecklist)/checkItem/($idCheckItem)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Checklist on a Card
#
# DELETE /cards/{id}/checklists/{idChecklist}
# operationId: delete-cards-id-checklists-idchecklist
export def "cards-checklists delete-cards-id-checklists-idchecklist" [
  id: string
  idChecklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($id)/checklists/($idChecklist)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Checklist
#
# POST /checklists
# operationId: post-checklists
export def "checklists post-checklists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idCard: string # The ID of the Card that the checklist should be added to. (e.g. 5abbe4b7ddc1b351ef961414)
  --name: string # The name of the checklist. Should be a string of length 1 to 16384.
  --pos: string # The position of the checklist on the card. One of: `top`, `bottom`, or a positive number.
  --idChecklistSource: string # The ID of a checklist to copy into the new checklist. (e.g. 5abbe4b7ddc1b351ef961414)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "idCard" $idCard "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "pos" $pos "scalar") (serialize-qp "idChecklistSource" $idChecklistSource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/checklists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Checklist
#
# GET /checklists/{id}
# operationId: get-checklists-id
export def "checklists get-checklists-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cards: string@cards-completer-1 # Valid values: `all`, `closed`, `none`, `open`, `visible`. Cards is a nested resource. The additional query params available are documented at [Cards Nested Resource](/cloud/trello/guides/rest-api/nested-resources/#cards-nested-resource). (default: none)
  --checkItems: string@checkItems-completer # The check items on the list to return. One of: `all`, `none`. (default: all)
  --checkItem-fields: string@checkItem-fields-completer-1 # The fields on the checkItem to return if checkItems are being returned. `all` or a comma-separated list of: `name`, `nameData`, `pos`, `state`, `type`, `due`, `dueReminder`, `idMember` (default: name, nameData, pos, state, due, dueReminder, idMember)
  --qp-fields: string # `all` or a comma-separated list of checklist [fields](/cloud/trello/guides/rest-api/object-definitions/) (default: all)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cards" $cards "scalar") (serialize-qp "checkItems" $checkItems "scalar") (serialize-qp "checkItem_fields" $checkItem_fields "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/checklists/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Checklist
#
# PUT /checklists/{id}
# operationId: put-checlists-id
export def "checklists put-checlists-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the new checklist being created. Should be length of 1 to 16384.
  --pos: string # Determines the position of the checklist on the card. One of: `top`, `bottom`, or a positive number.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "pos" $pos "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/checklists/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Checklist
#
# DELETE /checklists/{id}
# operationId: delete-checklists-id
export def "checklists delete-checklists-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checklists/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get field on a Checklist
#
# GET /checklists/{id}/{field}
# operationId: get-checklists-id-field
export def "checklists get-checklists-id-field" [
  id: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checklists/($id)/($field)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update field on a Checklist
#
# PUT /checklists/{id}/{field}
# operationId: put-checklists-id-field
export def "checklists put-checklists-id-field" [
  id: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # The value to change the checklist name to. Should be a string of length 1 to 16384.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/checklists/($id)/($field)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Board the Checklist is on
#
# GET /checklists/{id}/board
# operationId: get-checklists-id-board
export def "checklists-board get-checklists-id-board" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer-5 # `all` or a comma-separated list of board [fields](/cloud/trello/guides/rest-api/object-definitions/) (default: all)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/checklists/($id)/board" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Card a Checklist is on
#
# GET /checklists/{id}/cards
# operationId: get-checklists-id-cards
export def "checklists-cards get-checklists-id-cards" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checklists/($id)/cards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Checkitems on a Checklist
#
# GET /checklists/{id}/checkItems
# operationId: get-checklists-id-checkitems
export def "checklists-check-items get-checklists-id-checkitems" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-3 # One of: `all`, `none`. (default: all)
  --qp-fields: string@fields-completer-6 # One of: `all`, `name`, `nameData`, `pos`, `state`,`type`, `due`, `dueReminder`, `idMember`. (default: name, nameData, pos, state, due, dueReminder, idMember)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/checklists/($id)/checkItems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Checkitem on Checklist
#
# POST /checklists/{id}/checkItems
# operationId: post-checklists-id-checkitems
export def "checklists-check-items post-checklists-id-checkitems" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the new check item on the checklist. Should be a string of length 1 to 16384.
  --pos: string # The position of the check item in the checklist. One of: `top`, `bottom`, or a positive number.
  --checked: oneof<nothing, bool> # Determines whether the check item is already checked when created. (default: false)
  --due: string # A due date for the checkitem (format: date)
  --dueReminder: float # A dueReminder for the due date on the checkitem (nullable)
  --idMember: string # An ID of a member resource. (e.g. 5abbe4b7ddc1b351ef961414)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "pos" $pos "scalar") (serialize-qp "checked" $checked "scalar") (serialize-qp "due" $due "scalar") (serialize-qp "dueReminder" $dueReminder "scalar") (serialize-qp "idMember" $idMember "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/checklists/($id)/checkItems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Checkitem on a Checklist
#
# GET /checklists/{id}/checkItems/{idCheckItem}
# operationId: get-checklists-id-checkitems-idcheckitem
export def "checklists-check-items get-checklists-id-checkitems-idcheckitem" [
  id: string
  idCheckItem: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer-6 # One of: `all`, `name`, `nameData`, `pos`, `state`, `type`, `due`, `dueReminder`, `idMember`,. (default: name, nameData, pos, state, due, dueReminder, idMember)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/checklists/($id)/checkItems/($idCheckItem)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Checkitem from Checklist
#
# DELETE /checklists/{id}/checkItems/{idCheckItem}
# operationId: delete-checklists-id-checkitems-idcheckitem
export def "checklists-check-items delete-checklists-id-checkitems-idcheckitem" [
  id: string
  idCheckItem: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checklists/($id)/checkItems/($idCheckItem)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Custom Field on a Board
#
# POST /customFields
# operationId: post-customfields
export def "custom-fields post-customfields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  idModel: string # e.g. 5abbe4b7ddc1b351ef961414
  modelType: string@modelType-completer # The type of model that the Custom Field is being defined on. This should always be `board`.
  name: string # The name of the Custom Field
  type: string@type-completer-1 # The type of Custom Field to create.
  --options: string # If the type is `checkbox` 
  pos: any
  --display-cardFront: oneof<nothing, bool> # Whether this Custom Field should be shown on the front of Cards (default: true)
]: any -> record<id: string, idModel: string, modelType: string, fieldGroup: string, display: record<cardFront: bool, name: string, pos: string, options: list<record>>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customFields")
  let body = {idModel: $idModel, modelType: $modelType, name: $name, type: $type, options: $options, pos: $pos, display_cardFront: $display_cardFront} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a Custom Field
#
# GET /customFields/{id}
# operationId: get-customfields-id
export def "custom-fields get-customfields-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, idModel: string, modelType: string, fieldGroup: string, display: record<cardFront: bool, name: string, pos: string, options: list<record>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customFields/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Custom Field definition
#
# PUT /customFields/{id}
# operationId: put-customfields-id
export def "custom-fields put-customfields-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the Custom Field
  --pos: any
  --displaycardFront: oneof<nothing, bool> # Whether to display this custom field on the front of cards
]: any -> record<id: string, idModel: string, modelType: string, fieldGroup: string, display: record<cardFront: bool, name: string, pos: string, options: list<record>>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customFields/($id)")
  let body = {name: $name, pos: $pos, display/cardFront: $displaycardFront} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Custom Field definition
#
# DELETE /customFields/{id}
# operationId: delete-customfields-id
export def "custom-fields delete-customfields-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customFields/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Option to Custom Field dropdown
#
# POST /customFields/{id}/options
# operationId: get-customfields-id-options
export def "custom-fields-options get-customfields-id-options" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customFields/($id)/options")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Options of Custom Field drop down
#
# GET /customFields/{id}/options
# operationId: post-customfields-id-options
export def "custom-fields-options post-customfields-id-options" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customFields/($id)/options")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Option of Custom Field dropdown
#
# GET /customFields/{id}/options/{idCustomFieldOption}
# operationId: get-customfields-options-idcustomfieldoption
export def "custom-fields-options get-customfields-options-idcustomfieldoption" [
  id: string
  idCustomFieldOption: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customFields/($id)/options/($idCustomFieldOption)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Option of Custom Field dropdown
#
# DELETE /customFields/{id}/options/{idCustomFieldOption}
# operationId: delete-customfields-options-idcustomfieldoption
export def "custom-fields-options delete-customfields-options-idcustomfieldoption" [
  id: string
  idCustomFieldOption: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customFields/($id)/options/($idCustomFieldOption)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List available Emoji
#
# GET /emoji
# operationId: emoji
export def "emoji emoji" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The locale to return emoji descriptions and names in. Defaults to the logged in member's locale.
  --spritesheets: oneof<nothing, bool> # `true` to return spritesheet URLs in the response (default: false)
]: nothing -> record<trello: table<unified: string, name: string, native: string, shortName: string, shortNames: list, text: string, texts: string, category: string, sheetX: float, sheetY: float, tts: string, keywords: list>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "spritesheets" $spritesheets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/emoji" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an Enterprise
#
# GET /enterprises/{id}
# operationId: get-enterprises-id
export def "enterprises get-enterprises-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Comma-separated list of: `id`, `name`, `displayName`, `prefs`, `ssoActivationFailed`, `idAdmins`, `idMembers` (Note that the members array returned will be paginated if `members` is 'normal' or 'admins'. Pagination can be controlled with member_startIndex, etc, but the API response will not contain the total available result count or pagination status data.), `idOrganizations`, `products`, `userTypes`, `idMembers`, `idOrganizations` (default: all)
  --members: string # One of: `none`, `normal`, `admins`, `owners`, `all` (default: none)
  --member-fields: string # One of: `avatarHash`, `fullName`, `initials`, `username` (default: avatarHash, fullName, initials, username)
  --member-filter: string # Pass a SCIM-style query to filter members. This takes precedence over the all/normal/admins value of members. If any of the member_* args are set, the member array will be paginated. (default: none)
  --member-sort: string # This parameter expects a SCIM-style sorting value prefixed by a `-` to sort descending. If no `-` is prefixed, it will be sorted ascending. Note that the members array returned will be paginated if `members` is 'normal' or 'admins'. Pagination can be controlled with member_startIndex, etc, but the API response will not contain the total available result count or pagination status data.
  --member-sortBy: string # Deprecated: Please use member_sort. This parameter expects a SCIM-style sorting value. Note that the members array returned will be paginated if `members` is `normal` or `admins`. Pagination can be controlled with `member_startIndex`, etc, and the API response's header will contain the total count and pagination state. (default: none)
  --member-sortOrder: string # Deprecated: Please use member_sort. One of: `ascending`, `descending`, `asc`, `desc` (default: id)
  --member-startIndex: int # Any integer between 0 and 100. (format: int32, default: 1)
  --member-count: int # 0 to 100 (format: int32, default: 10)
  --organizations: string # One of: `none`, `members`, `public`, `all` (default: none)
  --organization-fields: string # Any valid value that the [nested organization field resource]() accepts. (default: none)
  --organization-paid-accounts: oneof<nothing, bool> # Whether or not to include paid account information in the returned workspace objects (default: false)
  --organization-memberships: string # Comma-seperated list of: `me`, `normal`, `admin`, `active`, `deactivated` (default: none)
]: nothing -> record<id: string, name: string, displayName: string, logoHash: string, logoUrl: string, prefs: record<ssoOnly: bool, signup: record<banner: string, bannerHtml: string>, mandatoryTransferDate: string, brandingColor: string, autoJoinOrganizations: bool, notifications: record, maxMembers: float>, organizationPrefs: record<boardVisibilityRestrict: record, boardDeleteRestrict: record, attachmentRestrictions: list<string>, permissionLevel: string>, ssoActivationFailed: bool, idAdmins: list<string>, enterpriseDomains: list<string>, isRealEnterprise: bool, pluginWhitelistingEnabled: list<string>, idOrganizations: list<string>, products: list<float>, licenses: record<maxMembers: float, totalMembers: float, relatedEnterprises: list<record>>, domains: list<string>, dateOrganizationPrefsLastUpdated: string, idp: record<requestSigned: bool, certificate: string, loginUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "member_filter" $member_filter "scalar") (serialize-qp "member_sort" $member_sort "scalar") (serialize-qp "member_sortBy" $member_sortBy "scalar") (serialize-qp "member_sortOrder" $member_sortOrder "scalar") (serialize-qp "member_startIndex" $member_startIndex "scalar") (serialize-qp "member_count" $member_count "scalar") (serialize-qp "organizations" $organizations "scalar") (serialize-qp "organization_fields" $organization_fields "scalar") (serialize-qp "organization_paid_accounts" $organization_paid_accounts "scalar") (serialize-qp "organization_memberships" $organization_memberships "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enterprises/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get auditlog data for an Enterprise
#
# GET /enterprises/{id}/auditlog
# operationId: get-enterprises-id-auditlog
export def "enterprises-auditlog get-enterprises-id-auditlog" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<idAction: string, type: string, date: string, memberCreator: record<id: string, username: string, fullName: string>, organization: record<enterpriseJoinRequest: record, id: string, name: string>, member: record<id: string, username: string, fullName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enterprises/($id)/auditlog")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Enterprise admin Members
#
# GET /enterprises/{id}/admins
# operationId: get-enterprises-id-admins
export def "enterprises-admins get-enterprises-id-admins" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Any valid value that the [nested member field resource]() accepts. (default: fullName, userName)
]: nothing -> record<id: string, fullName: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enterprises/($id)/admins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get signupUrl for Enterprise
#
# GET /enterprises/{id}/signupUrl
# operationId: get-enterprises-id-signupurl
export def "enterprises-signup-url get-enterprises-id-signupurl" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authenticate: oneof<nothing, bool> # default: false
  --confirmationAccepted: oneof<nothing, bool> # default: false
  --returnUrl: string # Any valid URL. (nullable, format: url)
  --tosAccepted: oneof<nothing, bool> # Designates whether the user has seen/consented to the Trello ToS prior to being redirected to the enterprise signup page/their IdP. (default: false)
]: nothing -> record<signupUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "authenticate" $authenticate "scalar") (serialize-qp "confirmationAccepted" $confirmationAccepted "scalar") (serialize-qp "returnUrl" $returnUrl "scalar") (serialize-qp "tosAccepted" $tosAccepted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enterprises/($id)/signupUrl" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Users of an Enterprise
#
# GET /enterprises/{id}/members/query
# operationId: get-users-id
export def "enterprises-members-query get-users-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --licensed: oneof<nothing, bool> # When true, returns members who possess a license for the corresponding Trello Enterprise; when false, returns members who do not. If unspecified, both licensed and unlicensed members will be returned. (default: false)
  --deactivated: oneof<nothing, bool> # When true, returns members who have been deactivated for the corresponding Trello Enterprise; when false, returns members who have not. If unspecified, both active and deactivated members will be returned. (default: false)
  --collaborator: oneof<nothing, bool> # When true, returns members who are guests on one or more boards in the corresponding Trello Enterprise (but do not possess a license); when false, returns members who are not. If unspecified, both guests and non-guests will be returned. (default: false)
  --managed: oneof<nothing, bool> # When true, returns members who are managed by the corresponding Trello Enterprise; when false, returns members who are not. If unspecified, both managed and unmanaged members will be returned. (default: none)
  --admin: oneof<nothing, bool> # When true, returns members who are administrators of the corresponding Trello Enterprise; when false, returns members who are not. If unspecified, both admin and non-admin members will be returned. (default: false)
  --activeSince: string # Returns only Trello users active since this date (inclusive). (default: none)
  --inactiveSince: string # Returns only Trello users active since this date (inclusive). (default: none)
  --search: string # Returns members with email address or full name that start with the search value. (default: none)
  --cursor: string # Cursor to return next set of results, use cursor returned in the response to query the next batch. (default: none)
]: nothing -> table<managed: bool, licensed: bool, admin: bool, deactivated: bool, collaborator: bool, member: record<id: string, fullname: string, username: string, dateLastImpression: string, email: string, initials: string, avatarURL: string, memberType: string, confirmed: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "licensed" $licensed "scalar") (serialize-qp "deactivated" $deactivated "scalar") (serialize-qp "collaborator" $collaborator "scalar") (serialize-qp "managed" $managed "scalar") (serialize-qp "admin" $admin "scalar") (serialize-qp "activeSince" $activeSince "scalar") (serialize-qp "inactiveSince" $inactiveSince "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enterprises/($id)/members/query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Members of Enterprise
#
# GET /enterprises/{id}/members
# operationId: get-enterprises-id-members
export def "enterprises-members get-enterprises-id-members" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # A comma-seperated list of valid [member fields](/cloud/trello/guides/rest-api/object-definitions/#member-object). (default: avatarHash, fullName, initials, username)
  --filter: string # Pass a SCIM-style query to filter members. This takes precedence over the all/normal/admins value of members. If any of the below member_* args are set, the member array will be paginated. (nullable)
  --qp-sort: string # This parameter expects a SCIM-style sorting value prefixed by a `-` to sort descending. If no `-` is prefixed, it will be sorted ascending. Note that the members array returned will be paginated if `members` is 'normal' or 'admins'. Pagination can be controlled with member_startIndex, etc, but the API response will not contain the total available result count or pagination status data.
  --sortBy: string # Deprecated: Please use `sort` instead. This parameter expects a SCIM-style sorting value. Note that the members array returned will be paginated if `members` is 'normal' or 'admins'. Pagination can be controlled with member_startIndex, etc, but the API response will not contain the total available result count or pagination status data.
  --sortOrder: string@sortOrder-completer # Deprecated: Please use `sort` instead. One of: `ascending`, `descending`, `asc`, `desc`. (nullable)
  --startIndex: int # Any integer between 0 and 9999. (format: int32)
  --count: string # SCIM-style filter. (default: none)
  --organization-fields: string # Any valid value that the [nested organization field resource](/cloud/trello/guides/rest-api/nested-resources/) accepts. (default: displayName)
  --board-fields: string # Any valid value that the [nested board resource](/cloud/trello/guides/rest-api/nested-resources/) accepts. (default: name)
]: nothing -> table<id: string, activityBlocked: bool, avatarHash: string, avatarUrl: string, bio: string, bioData: record<emoji: record>, confirmed: bool, fullName: string, idEnterprise: string, idEnterprisesDeactivated: list<string>, idMemberReferrer: string, idPremOrgsAdmin: list<string>, initials: string, memberType: string, nonPublic: record<fullName: string, initials: string, avatarUrl: string, avatarHash: string>, nonPublicAvailable: bool, products: list<int>, url: string, username: string, status: string, aaEmail: string, aaEnrolledDate: string, aaId: string, avatarSource: string, email: string, gravatarHash: string, idBoards: list<string>, idOrganizations: list<string>, idEnterprisesAdmin: list<string>, limits: record<status: string, disableAt: float, warnAt: float>, loginTypes: list<string>, marketingOptIn: record<optedIn: bool, date: string>, messagesDismissed: record<name: string, count: string, lastDismissed: string, _id: string>, oneTimeMessagesDismissed: list<string>, prefs: record<timezoneInfo: record, privacy: record, sendSummaries: bool, minutesBetweenSummaries: int, minutesBeforeDeadlineToNotify: int, colorBlind: bool, locale: string, timezone: string, twoFactor: record>, trophies: list<string>, uploadedAvatarHash: string, uploadedAvatarUrl: string, premiumFeatures: list<string>, isAaMastered: bool, ixUpdate: float, idBoardsPinned: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "organization_fields" $organization_fields "scalar") (serialize-qp "board_fields" $board_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enterprises/($id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Member of Enterprise
#
# GET /enterprises/{id}/members/{idMember}
# operationId: get-enterprises-id-members-idmember
export def "enterprises-members get-enterprises-id-members-idmember" [
  id: string
  idMember: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # A comma separated list of any valid values that the [nested member field resource]() accepts. (default: avatarHash, fullName, initials, username)
  --organization-fields: string # Any valid value that the [nested organization field resource](/cloud/trello/guides/rest-api/nested-resources/) accepts. (default: displayName)
  --board-fields: string # Any valid value that the [nested board resource](/cloud/trello/guides/rest-api/nested-resources/) accepts. (default: name)
]: nothing -> record<id: string, activityBlocked: bool, avatarHash: string, avatarUrl: string, bio: string, bioData: record<emoji: record>, confirmed: bool, fullName: string, idEnterprise: string, idEnterprisesDeactivated: list<string>, idMemberReferrer: string, idPremOrgsAdmin: list<string>, initials: string, memberType: string, nonPublic: record<fullName: string, initials: string, avatarUrl: string, avatarHash: string>, nonPublicAvailable: bool, products: list<int>, url: string, username: string, status: string, aaEmail: string, aaEnrolledDate: string, aaId: string, avatarSource: string, email: string, gravatarHash: string, idBoards: list<string>, idOrganizations: list<string>, idEnterprisesAdmin: list<string>, limits: record<status: string, disableAt: float, warnAt: float>, loginTypes: list<string>, marketingOptIn: record<optedIn: bool, date: string>, messagesDismissed: record<name: string, count: string, lastDismissed: string, _id: string>, oneTimeMessagesDismissed: list<string>, prefs: record<timezoneInfo: record<offsetCurrent: int, timezoneCurrent: string, offsetNext: int, dateNext: string, timezoneNext: string>, privacy: record<fullName: string, avatar: string>, sendSummaries: bool, minutesBetweenSummaries: int, minutesBeforeDeadlineToNotify: int, colorBlind: bool, locale: string, timezone: string, twoFactor: record<enabled: bool, needsNewBackups: bool>>, trophies: list<string>, uploadedAvatarHash: string, uploadedAvatarUrl: string, premiumFeatures: list<string>, isAaMastered: bool, ixUpdate: float, idBoardsPinned: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "organization_fields" $organization_fields "scalar") (serialize-qp "board_fields" $board_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enterprises/($id)/members/($idMember)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get whether an organization can be transferred to an enterprise.
#
# GET /enterprises/{id}/transferrable/organization/{idOrganization}
# operationId: get-enterprises-id-transferrable-organization-idOrganization
export def "enterprises-transferrable-organization get-enterprises-id-transferrable-organization-idOrganization" [
  id: string
  idOrganization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transferrable: bool, newBillableMembers: table<id: string, fullName: string, username: string, initials: string, avatarHash: string>, restrictedMembers: table<id: string, fullName: string, username: string, initials: string, avatarHash: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enterprises/($id)/transferrable/organization/($idOrganization)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a bulk list of organizations that can be transferred to an enterprise.
#
# GET /enterprises/{id}/transferrable/bulk/{idOrganizations}
# operationId: get-enterprises-id-transferrable-bulk-idOrganizations
export def "enterprises-transferrable-bulk get-enterprises-id-transferrable-bulk-idOrganizations" [
  id: string
  idOrganizations: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enterprises/($id)/transferrable/bulk/($idOrganizations)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Decline enterpriseJoinRequests from one organization or a bulk list of organizations.
#
# PUT /enterprises/${id}/enterpriseJoinRequest/bulk
# operationId: put-enterprises-id-enterpriseJoinRequest-bulk
export def "enterprises-id-enterprise-join-request-bulk put-enterprises-id-enterpriseJoinRequest-bulk" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idOrganizations: list # An array of IDs of an Organization resource.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "idOrganizations" $idOrganizations "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/enterprises/$($id)/enterpriseJoinRequest/bulk" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get ClaimableOrganizations of an Enterprise
#
# GET /enterprises/{id}/claimableOrganizations
# operationId: get-enterprises-id-claimableOrganizations
export def "enterprises-claimable-organizations get-enterprises-id-claimableOrganizations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limits the number of workspaces to be sorted
  --cursor: string # Specifies the sort order to return matching documents
  --name: string # Name of the enterprise to retrieve workspaces for
  --activeSince: string # Date in YYYY-MM-DD format indicating the date to search up to for activeness of workspace
  --inactiveSince: string # Date in YYYY-MM-DD format indicating the date to search up to for inactiveness of workspace
]: nothing -> record<organizations: table<name: string, displayName: string, activeMembershipCount: float, idActiveAdmins: list, products: list, id: string, logoUrl: string, dateLastActive: string>, claimableCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "activeSince" $activeSince "scalar") (serialize-qp "inactiveSince" $inactiveSince "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enterprises/($id)/claimableOrganizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get PendingOrganizations of an Enterprise
#
# GET /enterprises/{id}/pendingOrganizations
# operationId: get-enterprises-id-pendingOrganizations
export def "enterprises-pending-organizations get-enterprises-id-pendingOrganizations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --activeSince: string # Date in YYYY-MM-DD format indicating the date to search up to for activeness of workspace
  --inactiveSince: string # Date in YYYY-MM-DD format indicating the date to search up to for inactiveness of workspace
]: nothing -> table<id: string, idMember: string, memberRequestor: record<id: string, fullName: string>, date: string, displayName: string, membershipCount: float, logoUrl: string, transferability: record<transferrable: bool, newBillableMembers: list, restrictedMembers: list>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "activeSince" $activeSince "scalar") (serialize-qp "inactiveSince" $inactiveSince "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enterprises/($id)/pendingOrganizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an auth Token for an Enterprise.
#
# POST /enterprises/{id}/tokens
# operationId: post-enterprises-id-tokens
export def "enterprises-tokens post-enterprises-id-tokens" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # One of: `1hour`, `1day`, `30days`, `never` (default: none)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enterprises/($id)/tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Organizations of an Enterprise
#
# GET /enterprises/{id}/organizations
# operationId: get-enterprises-id-organizations
export def "enterprises-organizations get-enterprises-id-organizations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer-3 # comma-separated list of organization [fields](/cloud/trello/guides/rest-api/object-definitions/)
  --filter: string # default: all
  --startIndex: int # Any integer greater than and equal to 1. (format: int32)
  --count: int # Any integer between 0 and 100. (format: int32)
]: nothing -> table<id: string, name: string, displayName: string, dateLastActivity: string, prefs: record<boardVisibilityRestrict: record, boardDeleteRestrict: record, attachmentRestrictions: list, permissionLevel: string>, idEnterprise: string, offering: string, url: string, idBoards: list<string>, memberships: list<string>, premiumFeatures: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enterprises/($id)/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Transfer an Organization to an Enterprise.
#
# PUT /enterprises/{id}/organizations
# operationId: put-enterprises-id-organizations
export def "enterprises-organizations put-enterprises-id-organizations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idOrganization: string # ID of Organization to be transferred to Enterprise.
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "idOrganization" $idOrganization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enterprises/($id)/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Member's licensed status
#
# PUT /enterprises/{id}/members/{idMember}/licensed
# operationId: put-enterprises-id-members-idmember-licensed
export def "enterprises-members-licensed put-enterprises-id-members-idmember-licensed" [
  id: string
  idMember: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: oneof<nothing, bool> # Boolean value to determine whether the user should be given an Enterprise license (true) or not (false).
]: nothing -> record<id: string, activityBlocked: bool, avatarHash: string, avatarUrl: string, bio: string, bioData: record<emoji: record>, confirmed: bool, fullName: string, idEnterprise: string, idEnterprisesDeactivated: list<string>, idMemberReferrer: string, idPremOrgsAdmin: list<string>, initials: string, memberType: string, nonPublic: record<fullName: string, initials: string, avatarUrl: string, avatarHash: string>, nonPublicAvailable: bool, products: list<int>, url: string, username: string, status: string, aaEmail: string, aaEnrolledDate: string, aaId: string, avatarSource: string, email: string, gravatarHash: string, idBoards: list<string>, idOrganizations: list<string>, idEnterprisesAdmin: list<string>, limits: record<status: string, disableAt: float, warnAt: float>, loginTypes: list<string>, marketingOptIn: record<optedIn: bool, date: string>, messagesDismissed: record<name: string, count: string, lastDismissed: string, _id: string>, oneTimeMessagesDismissed: list<string>, prefs: record<timezoneInfo: record<offsetCurrent: int, timezoneCurrent: string, offsetNext: int, dateNext: string, timezoneNext: string>, privacy: record<fullName: string, avatar: string>, sendSummaries: bool, minutesBetweenSummaries: int, minutesBeforeDeadlineToNotify: int, colorBlind: bool, locale: string, timezone: string, twoFactor: record<enabled: bool, needsNewBackups: bool>>, trophies: list<string>, uploadedAvatarHash: string, uploadedAvatarUrl: string, premiumFeatures: list<string>, isAaMastered: bool, ixUpdate: float, idBoardsPinned: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enterprises/($id)/members/($idMember)/licensed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deactivate a Member of an Enterprise.
#
# PUT /enterprises/{id}/members/{idMember}/deactivated
# operationId: enterprises-id-members-idMember-deactivated
export def "enterprises-members-deactivated enterprises-id-members-idMember-deactivated" [
  id: string
  idMember: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: oneof<nothing, bool> # Determines whether the user is deactivated or not.
  --qp-fields: string@fields-completer-2 # A comma separated list of any valid values that the [nested member field resource]() accepts.
  --organization-fields: string@organization-fields-completer # Any valid value that the [nested organization resource](/cloud/trello/guides/rest-api/nested-resources/) accepts.
  --board-fields: string@board-fields-completer # Any valid value that the [nested board resource](/cloud/trello/guides/rest-api/nested-resources/) accepts.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "organization_fields" $organization_fields "scalar") (serialize-qp "board_fields" $board_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enterprises/($id)/members/($idMember)/deactivated" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Member to be admin of Enterprise
#
# PUT /enterprises/{id}/admins/{idMember}
# operationId: put-enterprises-id-admins-idmember
export def "enterprises-admins put-enterprises-id-admins-idmember" [
  id: string
  idMember: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enterprises/($id)/admins/($idMember)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a Member as admin from Enterprise.
#
# DELETE /enterprises/{id}/admins/{idMember}
# operationId: enterprises-id-organizations-idmember
export def "enterprises-admins enterprises-id-organizations-idmember" [
  id: string
  idMember: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enterprises/($id)/admins/($idMember)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Organization from an Enterprise.
#
# DELETE /enterprises/{id}/organizations/{idOrg}
# operationId: delete-enterprises-id-organizations-idorg
export def "enterprises-organizations delete-enterprises-id-organizations-idorg" [
  id: string
  idOrg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enterprises/($id)/organizations/($idOrg)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk accept a set of organizations to an Enterprise.
#
# GET /enterprises/{id}/organizations/bulk/{idOrganizations}
# operationId: get-enterprises-id-organizations-bulk-idOrganizations
export def "enterprises-organizations-bulk get-enterprises-id-organizations-bulk-idOrganizations" [
  id: string
  idOrganizations: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enterprises/($id)/organizations/bulk/($idOrganizations)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Label
#
# GET /labels/{id}
# operationId: get-labels-id
export def "labels get-labels-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # all or a comma-separated list of [fields](/cloud/trello/guides/rest-api/object-definitions/) (default: all)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/labels/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Label
#
# PUT /labels/{id}
# operationId: put-labels-id
export def "labels put-labels-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name for the label
  --color: string@color-completer # The new color for the label. See: [fields](/cloud/trello/guides/rest-api/object-definitions/) for color options (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "color" $color "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/labels/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Label
#
# DELETE /labels/{id}
# operationId: delete-labels-id
export def "labels delete-labels-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/labels/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a field on a label
#
# PUT /labels/{id}/{field}
# operationId: put-labels-id-field
export def "labels put-labels-id-field" [
  id: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # The new value for the field. (e.g. 5abbe4b7ddc1b351ef961414)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/labels/($id)/($field)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Label
#
# POST /labels
# operationId: post-labels
export def "labels post-labels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name for the label
  --color: string@color-completer # The color for the label. (nullable)
  --idBoard: string # The ID of the Board to create the Label on.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "color" $color "scalar") (serialize-qp "idBoard" $idBoard "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/labels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a List
#
# GET /lists/{id}
# operationId: get-lists-id
export def "lists get-lists-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # `all` or a comma separated list of List field names. (default: name,closed,idBoard,pos)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a List
#
# PUT /lists/{id}
# operationId: put-lists-id
export def "lists put-lists-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # New name for the list
  --closed: oneof<nothing, bool> # Whether the list should be closed (archived)
  --idBoard: string # ID of a board the list should be moved to (e.g. 5abbe4b7ddc1b351ef961414)
  --pos: string # New position for the list: `top`, `bottom`, or a positive floating point number
  --subscribed: oneof<nothing, bool> # Whether the active member is subscribed to this list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "closed" $closed "scalar") (serialize-qp "idBoard" $idBoard "scalar") (serialize-qp "pos" $pos "scalar") (serialize-qp "subscribed" $subscribed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new List
#
# POST /lists
# operationId: post-lists
export def "lists post-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name for the list
  --idBoard: string # The long ID of the board the list should be created on (e.g. 5abbe4b7ddc1b351ef961414)
  --idListSource: string # ID of the List to copy into the new List (e.g. 5abbe4b7ddc1b351ef961414)
  --pos: string # Position of the list. `top`, `bottom`, or a positive floating point number
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "idBoard" $idBoard "scalar") (serialize-qp "idListSource" $idListSource "scalar") (serialize-qp "pos" $pos "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive all Cards in List
#
# POST /lists/{id}/archiveAllCards
# operationId: post-lists-id-archiveallcards
export def "lists-archive-all-cards post-lists-id-archiveallcards" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($id)/archiveAllCards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Move all Cards in List
#
# POST /lists/{id}/moveAllCards
# operationId: post-lists-id-moveallcards
export def "lists-move-all-cards post-lists-id-moveallcards" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idBoard: string # The ID of the board the cards should be moved to (e.g. 5abbe4b7ddc1b351ef961414)
  --idList: string # The ID of the list that the cards should be moved to (e.g. 5abbe4b7ddc1b351ef961414)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "idBoard" $idBoard "scalar") (serialize-qp "idList" $idList "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($id)/moveAllCards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive or unarchive a list
#
# PUT /lists/{id}/closed
# operationId: put-lists-id-closed
export def "lists-closed put-lists-id-closed" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # Set to true to close (archive) the list (e.g. 5abbe4b7ddc1b351ef961414)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($id)/closed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Move List to Board
#
# PUT /lists/{id}/idBoard
# operationId: put-id-idboard
export def "lists-id-board put-id-idboard" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # The ID of the board to move the list to (e.g. 5abbe4b7ddc1b351ef961414)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($id)/idBoard" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a field on a List
#
# PUT /lists/{id}/{field}
# operationId: put-lists-id-field
export def "lists put-lists-id-field" [
  id: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # The new value for the field
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($id)/($field)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Actions for a List
#
# GET /lists/{id}/actions
# operationId: get-lists-id-actions
export def "lists-actions get-lists-id-actions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # A comma-separated list of [action types](https://developer.atlassian.com/cloud/trello/guides/rest-api/action-types/).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($id)/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Board a List is on
#
# GET /lists/{id}/board
# operationId: get-lists-id-board
export def "lists-board get-lists-id-board" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # `all` or a comma-separated list of board [fields](/cloud/trello/guides/rest-api/object-definitions/#board-object) (default: all)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($id)/board" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Cards in a List
#
# GET /lists/{id}/cards
# operationId: get-lists-id-cards
export def "lists-cards get-lists-id-cards" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, address: string, badges: record<attachmentsByType: record, location: bool, votes: int, viewingMemberVoted: bool, subscribed: bool, fogbugz: string, checkItems: int, checkItemsChecked: int, comments: int, attachments: int, description: bool, due: string, start: string, dueComplete: bool>, cardRole: string, checkItemStates: list<any>, closed: bool, coordinates: string, creationMethod: string, dateLastActivity: string, desc: string, descData: record<emoji: record>, due: string, dueReminder: string, idBoard: string, idChecklists: list<any>, idLabels: list<any>, idList: string, idMembers: list<any>, idMembersVoted: list<any>, idShort: int, idAttachmentCover: string, labels: list<any>, limits: record<attachments: record>, locationName: string, manualCoverAttachment: bool, mirrorSourceId: string, name: string, pos: float, shortLink: string, shortUrl: string, subscribed: bool, url: string, cover: record<idAttachment: string, color: string, idUploadedBackground: bool, size: string, brightness: string, isTemplate: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($id)/cards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Member
#
# GET /members/{id}
# operationId: get-members=id
@deprecated --flag paid-account
export def "members get-membersid" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # See the [Actions Nested Resource](/cloud/trello/guides/rest-api/nested-resources/#actions-nested-resource)
  --boards: string # See the [Boards Nested Resource](/cloud/trello/guides/rest-api/nested-resources/#boards-nested-resource)
  --boardBackgrounds: string@boardBackgrounds-completer # One of: `all`, `custom`, `default`, `none`, `premium` (default: none)
  --boardsInvited: string@boardsInvited-completer # `all` or a comma-separated list of: closed, members, open, organization, pinned, public, starred, unpinned
  --boardsInvited-fields: string@boardsInvited-fields-completer # `all` or a comma-separated list of board [fields](/cloud/trello/guides/rest-api/object-definitions/)
  --boardStars: oneof<nothing, bool> # Whether to return the boardStars or not (default: false)
  --cards: string # See the [Cards Nested Resource](/cloud/trello/guides/rest-api/nested-resources/#cards-nested-resource) for additional options (default: none)
  --customBoardBackgrounds: string@customBoardBackgrounds-completer # `all` or `none` (default: none)
  --customEmoji: string@customEmoji-completer # `all` or `none` (default: none)
  --customStickers: string@customStickers-completer # `all` or `none` (default: none)
  --qp-fields: string@fields-completer-2 # `all` or a comma-separated list of member [fields](/cloud/trello/guides/rest-api/object-definitions/)
  --notifications: string # See the [Notifications Nested Resource](/cloud/trello/guides/rest-api/nested-resources/#notifications-nested-resource)
  --organizations: string@organizations-completer # One of: `all`, `members`, `none`, `public` (default: none)
  --organization-fields: string@organization-fields-completer # `all` or a comma-separated list of organization [fields](/cloud/trello/guides/rest-api/object-definitions/)
  --organization-paid-account: oneof<nothing, bool> # Whether or not to include paid account information in the returned workspace object (default: false)
  --organizationsInvited: string@organizationsInvited-completer # One of: `all`, `members`, `none`, `public` (default: none)
  --organizationsInvited-fields: string@organizationsInvited-fields-completer # `all` or a comma-separated list of organization [fields](/cloud/trello/guides/rest-api/object-definitions/)
  --paid-account: oneof<nothing, bool> # Whether or not to include paid account information in the returned member object (DEPRECATED, default: false)
  --savedSearches: oneof<nothing, bool> # default: false
  --tokens: string@tokens-completer # `all` or `none` (default: none)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar") (serialize-qp "boards" $boards "scalar") (serialize-qp "boardBackgrounds" $boardBackgrounds "scalar") (serialize-qp "boardsInvited" $boardsInvited "scalar") (serialize-qp "boardsInvited_fields" $boardsInvited_fields "scalar") (serialize-qp "boardStars" $boardStars "scalar") (serialize-qp "cards" $cards "scalar") (serialize-qp "customBoardBackgrounds" $customBoardBackgrounds "scalar") (serialize-qp "customEmoji" $customEmoji "scalar") (serialize-qp "customStickers" $customStickers "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "notifications" $notifications "scalar") (serialize-qp "organizations" $organizations "scalar") (serialize-qp "organization_fields" $organization_fields "scalar") (serialize-qp "organization_paid_account" $organization_paid_account "scalar") (serialize-qp "organizationsInvited" $organizationsInvited "scalar") (serialize-qp "organizationsInvited_fields" $organizationsInvited_fields "scalar") (serialize-qp "paid_account" $paid_account "scalar") (serialize-qp "savedSearches" $savedSearches "scalar") (serialize-qp "tokens" $tokens "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Member
#
# PUT /members/{id}
# operationId: put-members-id
export def "members put-members-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fullName: string # New name for the member. Cannot begin or end with a space.
  --initials: string # New initials for the member. 1-4 characters long.
  --username: string # New username for the member. At least 3 characters long, only lowercase letters, underscores, and numbers. Must be unique.
  --bio: string
  --avatarSource: string@avatarSource-completer # One of: `gravatar`, `none`, `upload`
  --prefscolorBlind: oneof<nothing, bool>
  --prefslocale: string
  --prefsminutesBetweenSummaries: int # `-1` for disabled, `1`, or `60` (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fullName" $fullName "scalar") (serialize-qp "initials" $initials "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "bio" $bio "scalar") (serialize-qp "avatarSource" $avatarSource "scalar") (serialize-qp "prefs/colorBlind" $prefscolorBlind "scalar") (serialize-qp "prefs/locale" $prefslocale "scalar") (serialize-qp "prefs/minutesBetweenSummaries" $prefsminutesBetweenSummaries "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a field on a Member
#
# GET /members/{id}/{field}
# operationId: get-members-id-field
export def "members get-members-id-field" [
  id: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)/($field)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Member's Actions
#
# GET /members/{id}/actions
# operationId: get-members-id-actions
export def "members-actions get-members-id-actions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # A comma-separated list of [action types](https://developer.atlassian.com/cloud/trello/guides/rest-api/action-types/).
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Member's custom Board backgrounds
#
# GET /members/{id}/boardBackgrounds
# operationId: get-members-id-boardbackgrounds
export def "members-board-backgrounds get-members-id-boardbackgrounds" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-4 # One of: `all`, `custom`, `default`, `none`, `premium` (default: all)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/boardBackgrounds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload new boardBackground for Member
#
# POST /members/{id}/boardBackgrounds
# operationId: post-members-id-boardbackgrounds-1
export def "members-board-backgrounds post-members-id-boardbackgrounds-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # format: binary
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file" $file "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/boardBackgrounds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a boardBackground of a Member
#
# GET /members/{id}/boardBackgrounds/{idBackground}
# operationId: get-members-id-boardbackgrounds-idbackground
export def "members-board-backgrounds get-members-id-boardbackgrounds-idbackground" [
  id: string
  idBackground: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer-7 # `all` or a comma-separated list of: `brightness`, `fullSizeUrl`, `scaled`, `tile` (default: all)
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/boardBackgrounds/($idBackground)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Member's custom Board background
#
# PUT /members/{id}/boardBackgrounds/{idBackground}
# operationId: put-members-id-boardbackgrounds-idbackground
export def "members-board-backgrounds put-members-id-boardbackgrounds-idbackground" [
  id: string
  idBackground: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --brightness: string@brightness-completer # One of: `dark`, `light`, `unknown`
  --tile: oneof<nothing, bool> # Whether the background should be tiled
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "brightness" $brightness "scalar") (serialize-qp "tile" $tile "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/boardBackgrounds/($idBackground)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Member's custom Board background
#
# DELETE /members/{id}/boardBackgrounds/{idBackground}
# operationId: delete-members-id-boardbackgrounds-idbackground
export def "members-board-backgrounds delete-members-id-boardbackgrounds-idbackground" [
  id: string
  idBackground: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)/boardBackgrounds/($idBackground)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Member's boardStars
#
# GET /members/{id}/boardStars
# operationId: get-members-id-boardstars
export def "members-board-stars get-members-id-boardstars" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)/boardStars")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Star for Board
#
# POST /members/{id}/boardStars
# operationId: post-members-id-boardstars
export def "members-board-stars post-members-id-boardstars" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idBoard: string # The ID of the board to star (e.g. 5abbe4b7ddc1b351ef961414)
  --pos: string # The position of the newly starred board. `top`, `bottom`, or a positive float.
]: nothing -> table<id: string, idBoard: string, pos: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "idBoard" $idBoard "scalar") (serialize-qp "pos" $pos "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/boardStars" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a boardStar of Member
#
# GET /members/{id}/boardStars/{idStar}
# operationId: get-members-id-boardstars-idstar
export def "members-board-stars get-members-id-boardstars-idstar" [
  id: string
  idStar: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, idBoard: string, pos: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)/boardStars/($idStar)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the position of a boardStar of Member
#
# PUT /members/{id}/boardStars/{idStar}
# operationId: put-members-id-boardstars-idstar
export def "members-board-stars put-members-id-boardstars-idstar" [
  id: string
  idStar: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pos: string # New position for the starred board. `top`, `bottom`, or a positive float.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pos" $pos "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/boardStars/($idStar)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Star for Board
#
# DELETE /members/{id}/boardStars/{idStar}
# operationId: delete-members-id-boardstars-idstar
export def "members-board-stars delete-members-id-boardstars-idstar" [
  id: string
  idStar: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)/boardStars/($idStar)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Boards that Member belongs to
#
# GET /members/{id}/boards
# operationId: get-members-id-boards
export def "members-boards get-members-id-boards" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-5 # `all` or a comma-separated list of: `closed`, `members`, `open`, `organization`, `public`, `starred` (default: all)
  --qp-fields: string@fields-completer # `all` or a comma-separated list of board [fields](/cloud/trello/guides/rest-api/object-definitions/)
  --lists: string@lists-completer # Which lists to include with the boards. One of: `all`, `closed`, `none`, `open` (default: none)
  --organization: oneof<nothing, bool> # Whether to include the Organization object with the Boards (default: false)
  --organization-fields: string@organization-fields-completer # `all` or a comma-separated list of organization [fields](/cloud/trello/guides/rest-api/object-definitions/)
]: nothing -> table<id: string, name: string, desc: string, descData: string, closed: bool, idMemberCreator: string, idOrganization: string, pinned: bool, url: string, shortUrl: string, prefs: record<permissionLevel: string, hideVotes: bool, voting: string, comments: string, invitations: any, selfJoin: bool, cardCovers: bool, isTemplate: bool, cardAging: string, calendarFeedEnabled: bool, background: string, backgroundImage: string, backgroundImageScaled: list, backgroundTile: bool, backgroundBrightness: string, backgroundBottomColor: string, backgroundTopColor: string, canBePublic: bool, canBeEnterprise: bool, canBeOrg: bool, canBePrivate: bool, canInvite: bool>, labelNames: record<green: string, yellow: string, orange: string, red: string, purple: string, blue: string, sky: string, lime: string, pink: string, black: string>, limits: record<attachments: record>, starred: bool, memberships: string, shortLink: string, subscribed: bool, powerUps: string, dateLastActivity: string, dateLastView: string, idTags: string, datePluginDisable: string, creationMethod: string, ixUpdate: int, templateGallery: string, enterpriseOwned: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lists" $lists "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "organization_fields" $organization_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/boards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Boards the Member has been invited to
#
# GET /members/{id}/boardsInvited
# operationId: get-members-id-boardsinvited
export def "members-boards-invited get-members-id-boardsinvited" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer # `all` or a comma-separated list of board [fields](/cloud/trello/guides/rest-api/object-definitions/)
]: nothing -> table<id: string, name: string, desc: string, descData: string, closed: bool, idMemberCreator: string, idOrganization: string, pinned: bool, url: string, shortUrl: string, prefs: record<permissionLevel: string, hideVotes: bool, voting: string, comments: string, invitations: any, selfJoin: bool, cardCovers: bool, isTemplate: bool, cardAging: string, calendarFeedEnabled: bool, background: string, backgroundImage: string, backgroundImageScaled: list, backgroundTile: bool, backgroundBrightness: string, backgroundBottomColor: string, backgroundTopColor: string, canBePublic: bool, canBeEnterprise: bool, canBeOrg: bool, canBePrivate: bool, canInvite: bool>, labelNames: record<green: string, yellow: string, orange: string, red: string, purple: string, blue: string, sky: string, lime: string, pink: string, black: string>, limits: record<attachments: record>, starred: bool, memberships: string, shortLink: string, subscribed: bool, powerUps: string, dateLastActivity: string, dateLastView: string, idTags: string, datePluginDisable: string, creationMethod: string, ixUpdate: int, templateGallery: string, enterpriseOwned: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/boardsInvited" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Cards the Member is on
#
# GET /members/{id}/cards
# operationId: get-members-id-cards
export def "members-cards get-members-id-cards" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-6 # One of: `all`, `closed`, `complete`, `incomplete`, `none`, `open`, `visible` (default: visible)
]: nothing -> table<id: string, address: string, badges: record<attachmentsByType: record, location: bool, votes: int, viewingMemberVoted: bool, subscribed: bool, fogbugz: string, checkItems: int, checkItemsChecked: int, comments: int, attachments: int, description: bool, due: string, start: string, dueComplete: bool>, cardRole: string, checkItemStates: list<any>, closed: bool, coordinates: string, creationMethod: string, dateLastActivity: string, desc: string, descData: record<emoji: record>, due: string, dueReminder: string, idBoard: string, idChecklists: list<any>, idLabels: list<any>, idList: string, idMembers: list<any>, idMembersVoted: list<any>, idShort: int, idAttachmentCover: string, labels: list<any>, limits: record<attachments: record>, locationName: string, manualCoverAttachment: bool, mirrorSourceId: string, name: string, pos: float, shortLink: string, shortUrl: string, subscribed: bool, url: string, cover: record<idAttachment: string, color: string, idUploadedBackground: bool, size: string, brightness: string, isTemplate: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/cards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Member's custom Board Backgrounds
#
# GET /members/{id}/customBoardBackgrounds
# operationId: get-members-id-customboardbackgrounds
export def "members-custom-board-backgrounds get-members-id-customboardbackgrounds" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)/customBoardBackgrounds")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new custom Board Background
#
# POST /members/{id}/customBoardBackgrounds
# operationId: membersidcustomboardbackgrounds-1
export def "members-custom-board-backgrounds membersidcustomboardbackgrounds-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # format: binary
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file" $file "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/customBoardBackgrounds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get custom Board Background of Member
#
# GET /members/{id}/customBoardBackgrounds/{idBackground}
# operationId: get-members-id-customboardbackgrounds-idbackground
export def "members-custom-board-backgrounds get-members-id-customboardbackgrounds-idbackground" [
  id: string
  idBackground: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)/customBoardBackgrounds/($idBackground)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update custom Board Background of Member
#
# PUT /members/{id}/customBoardBackgrounds/{idBackground}
# operationId: put-members-id-customboardbackgrounds-idbackground
export def "members-custom-board-backgrounds put-members-id-customboardbackgrounds-idbackground" [
  id: string
  idBackground: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --brightness: string@brightness-completer # One of: `dark`, `light`, `unknown`
  --tile: oneof<nothing, bool> # Whether to tile the background
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "brightness" $brightness "scalar") (serialize-qp "tile" $tile "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/customBoardBackgrounds/($idBackground)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete custom Board Background of Member
#
# DELETE /members/{id}/customBoardBackgrounds/{idBackground}
# operationId: delete-members-id-customboardbackgrounds-idbackground
export def "members-custom-board-backgrounds delete-members-id-customboardbackgrounds-idbackground" [
  id: string
  idBackground: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)/customBoardBackgrounds/($idBackground)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Member's customEmojis
#
# GET /members/{id}/customEmoji
# operationId: get-members-id-customemoji
export def "members-custom-emoji get-members-id-customemoji" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, url: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)/customEmoji")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create custom Emoji for Member
#
# POST /members/{id}/customEmoji
# operationId: post-members-id-customemoji
export def "members-custom-emoji post-members-id-customemoji" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # format: binary
  --name: string # Name for the emoji. 2 - 64 characters
]: nothing -> record<id: string, url: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file" $file "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/customEmoji" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Member's custom Emoji
#
# GET /members/{id}/customEmoji/{idEmoji}
# operationId: membersidcustomemojiidemoji
export def "members-custom-emoji membersidcustomemojiidemoji" [
  id: string
  idEmoji: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer-8 # `all` or a comma-separated list of `name`, `url` (default: all)
]: nothing -> record<id: string, url: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/customEmoji/($idEmoji)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Member's custom Stickers
#
# GET /members/{id}/customStickers
# operationId: get-members-id-customstickers
export def "members-custom-stickers get-members-id-customstickers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, url: string, scaled: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)/customStickers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create custom Sticker for Member
#
# POST /members/{id}/customStickers
# operationId: post-members-id-customstickers
export def "members-custom-stickers post-members-id-customstickers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # format: binary
]: nothing -> record<id: string, url: string, scaled: table<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file" $file "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/customStickers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Member's custom Sticker
#
# GET /members/{id}/customStickers/{idSticker}
# operationId: get-members-id-customstickers-idsticker
export def "members-custom-stickers get-members-id-customstickers-idsticker" [
  id: string
  idSticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer-9 # `all` or a comma-separated list of `scaled`, `url` (default: all)
]: nothing -> record<id: string, url: string, scaled: table<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/customStickers/($idSticker)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Member's custom Sticker
#
# DELETE /members/{id}/customStickers/{idSticker}
# operationId: delete-members-id-customstickers-idsticker
export def "members-custom-stickers delete-members-id-customstickers-idsticker" [
  id: string
  idSticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)/customStickers/($idSticker)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Member's Notifications
#
# GET /members/{id}/notifications
# operationId: get-members-id-notifications
export def "members-notifications get-members-id-notifications" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: oneof<nothing, bool> # default: false
  --display: oneof<nothing, bool> # default: false
  --filter: string # default: all
  --read-filter: string # One of: `all`, `read`, `unread` (default: all)
  --qp-fields: string # `all` or a comma-separated list of notification [fields](/cloud/trello/guides/rest-api/object-definitions/) (default: all)
  --limit: int # Max 1000 (format: int32, default: 50)
  --page: int # Max 100 (format: int32, default: 0)
  --before: string # A notification ID
  --since: string # A notification ID
  --memberCreator: oneof<nothing, bool> # default: true
  --memberCreator-fields: string # `all` or a comma-separated list of member [fields](/cloud/trello/guides/rest-api/object-definitions/) (default: avatarHash,fullName,initials,username)
]: nothing -> table<id: string, unread: bool, type: string, date: string, dateRead: string, data: string, card: record<id: string, address: string, badges: record, cardRole: string, checkItemStates: list, closed: bool, coordinates: string, creationMethod: string, dateLastActivity: string, desc: string, descData: record, due: string, dueReminder: string, idBoard: string, idChecklists: list, idLabels: list, idList: string, idMembers: list, idMembersVoted: list, idShort: int, idAttachmentCover: string, labels: list, limits: record, locationName: string, manualCoverAttachment: bool, mirrorSourceId: string, name: string, pos: float, shortLink: string, shortUrl: string, subscribed: bool, url: string, cover: record>, board: record<id: string, name: string, desc: string, descData: string, closed: bool, idMemberCreator: string, idOrganization: string, pinned: bool, url: string, shortUrl: string, prefs: record, labelNames: record, limits: record, starred: bool, memberships: string, shortLink: string, subscribed: bool, powerUps: string, dateLastActivity: string, dateLastView: string, idTags: string, datePluginDisable: string, creationMethod: string, ixUpdate: int, templateGallery: string, enterpriseOwned: bool>, idMemberCreator: string, idAction: string, reactions: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entities" $entities "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "read_filter" $read_filter "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "memberCreator" $memberCreator "scalar") (serialize-qp "memberCreator_fields" $memberCreator_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/notifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Member's Organizations
#
# GET /members/{id}/organizations
# operationId: get-members-id-organizations
export def "members-organizations get-members-id-organizations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-7 # One of: `all`, `members`, `none`, `public` (Note: `members` filters to only private Workspaces) (default: all)
  --qp-fields: string@fields-completer-3 # `all` or a comma-separated list of organization [fields](/cloud/trello/guides/rest-api/object-definitions/)
  --paid-account: oneof<nothing, bool> # Whether or not to include paid account information in the returned workspace object (default: false)
]: nothing -> table<id: string, name: string, displayName: string, dateLastActivity: string, prefs: record<boardVisibilityRestrict: record, boardDeleteRestrict: record, attachmentRestrictions: list, permissionLevel: string>, idEnterprise: string, offering: string, url: string, idBoards: list<string>, memberships: list<string>, premiumFeatures: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "paid_account" $paid_account "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Organizations a Member has been invited to
#
# GET /members/{id}/organizationsInvited
# operationId: get-members-id-organizationsinvited
export def "members-organizations-invited get-members-id-organizationsinvited" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer-3 # `all` or a comma-separated list of organization [fields](/cloud/trello/guides/rest-api/object-definitions/)
]: nothing -> table<id: string, name: string, displayName: string, dateLastActivity: string, prefs: record<boardVisibilityRestrict: record, boardDeleteRestrict: record, attachmentRestrictions: list, permissionLevel: string>, idEnterprise: string, offering: string, url: string, idBoards: list<string>, memberships: list<string>, premiumFeatures: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/organizationsInvited" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Member's saved searched
#
# GET /members/{id}/savedSearches
# operationId: get-members-id-savedsearches
export def "members-saved-searches get-members-id-savedsearches" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, query: string, pos: any> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)/savedSearches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create saved Search for Member
#
# POST /members/{id}/savedSearches
# operationId: post-members-id-savedsearches
export def "members-saved-searches post-members-id-savedsearches" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name for the saved search
  --qp-query: string # The search query
  --pos: string # The position of the saved search. `top`, `bottom`, or a positive float.
]: nothing -> record<id: string, name: string, query: string, pos: any> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "pos" $pos "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/savedSearches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a saved search
#
# GET /members/{id}/savedSearches/{idSearch}
# operationId: get-members-id-savedsearches-idsearch
export def "members-saved-searches get-members-id-savedsearches-idsearch" [
  id: string
  idSearch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, query: string, pos: any> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)/savedSearches/($idSearch)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a saved search
#
# PUT /members/{id}/savedSearches/{idSearch}
# operationId: put-members-id-savedsearches-idsearch
export def "members-saved-searches put-members-id-savedsearches-idsearch" [
  id: string
  idSearch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name for the saved search
  --qp-query: string # The new search query
  --pos: string # New position for saves search. `top`, `bottom`, or a positive float.
]: nothing -> record<id: string, name: string, query: string, pos: any> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "pos" $pos "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/savedSearches/($idSearch)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a saved search
#
# DELETE /members/{id}/savedSearches/{idSearch}
# operationId: delete-members-id-savedsearches-idsearch
export def "members-saved-searches delete-members-id-savedsearches-idsearch" [
  id: string
  idSearch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)/savedSearches/($idSearch)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Member's Tokens
#
# GET /members/{id}/tokens
# operationId: get-members-id-tokens
export def "members-tokens get-members-id-tokens" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --webhooks: oneof<nothing, bool> # Whether to include webhooks (default: false)
]: nothing -> table<id: string, identifier: string, idMember: string, dateCreated: string, dateExpires: string, permissions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "webhooks" $webhooks "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Avatar for Member
#
# POST /members/{id}/avatar
# operationId: membersidavatar
export def "members-avatar membersidavatar" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # format: binary
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file" $file "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/avatar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Dismiss a message for Member
#
# POST /members/{id}/oneTimeMessagesDismissed
# operationId: post-members-id-onetimemessagesdismissed
export def "members-one-time-messages-dismissed post-members-id-onetimemessagesdismissed" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # The message to dismiss (e.g. 5abbe4b7ddc1b351ef961414)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/oneTimeMessagesDismissed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Member's notification channel settings
#
# GET /members/{id}/notificationsChannelSettings
# operationId: get-members-id-notificationChannelSettings
export def "members-notifications-channel-settings get-members-id-notificationChannelSettings" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, idMember: string, blockedKeys: list<string>, channel: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)/notificationsChannelSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update blocked notification keys of Member on a channel
#
# PUT /members/{id}/notificationsChannelSettings
# operationId: put-members-id-notificationChannelSettings-channel-blockedKeys
export def "members-notifications-channel-settings put-members-id-notificationChannelSettings-channel-blockedKeys-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channel: string@channel-completer # e.g. email
  blockedKeys: any # Blocked key or array of blocked keys.
]: any -> record<id: string, idMember: string, blockedKeys: list<string>, channel: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)/notificationsChannelSettings")
  let body = {channel: $channel, blockedKeys: $blockedKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get blocked notification keys of Member on this channel
#
# GET /members/{id}/notificationsChannelSettings/{channel}
# operationId: get-members-id-notificationChannelSettings-channel
export def "members-notifications-channel-settings get-members-id-notificationChannelSettings-channel" [
  id: string
  channel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, idMember: string, blockedKeys: list<string>, channel: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)/notificationsChannelSettings/($channel)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update blocked notification keys of Member on a channel
#
# PUT /members/{id}/notificationsChannelSettings/{channel}
# operationId: put-members-id-notificationChannelSettings-channel-blockedKeys
export def "members-notifications-channel-settings put-members-id-notificationChannelSettings-channel-blockedKeys-by-id-channel" [
  id: string
  channel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  blockedKeys: any # Singular key or array of notification keys
]: any -> record<id: string, idMember: string, blockedKeys: list<string>, channel: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)/notificationsChannelSettings/($channel)")
  let body = {blockedKeys: $blockedKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update blocked notification keys of Member on a channel
#
# PUT /members/{id}/notificationsChannelSettings/{channel}/{blockedKeys}
# operationId: put-members-id-notificationChannelSettings-channel-blockedKeys
export def "members-notifications-channel-settings put-members-id-notificationChannelSettings-channel-blockedKeys-by-id-channel-blockedKeys" [
  id: string
  channel: string
  blockedKeys: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, idMember: string, blockedKeys: list<string>, channel: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)/notificationsChannelSettings/($channel)/($blockedKeys)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Notification
#
# GET /notifications/{id}
# operationId: get-notifications-id
export def "notifications get-notifications-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --board: oneof<nothing, bool> # Whether to include the board object (default: false)
  --board-fields: string@board-fields-completer # `all` or a comma-separated list of board [fields](/cloud/trello/guides/rest-api/object-definitions/)
  --card: oneof<nothing, bool> # Whether to include the card object (default: false)
  --card-fields: string@card-fields-completer # `all` or a comma-separated list of card [fields](/cloud/trello/guides/rest-api/object-definitions/)
  --display: oneof<nothing, bool> # Whether to include the display object with the results (default: false)
  --entities: oneof<nothing, bool> # Whether to include the entities object with the results (default: false)
  --qp-fields: string@fields-completer-10 # `all` or a comma-separated list of notification [fields](/cloud/trello/guides/rest-api/object-definitions/)
  --list: oneof<nothing, bool> # Whether to include the list object (default: false)
  --member: oneof<nothing, bool> # Whether to include the member object (default: true)
  --member-fields: string@member-fields-completer # `all` or a comma-separated list of member [fields](/cloud/trello/guides/rest-api/object-definitions/)
  --memberCreator: oneof<nothing, bool> # Whether to include the member object of the creator (default: true)
  --memberCreator-fields: string@memberCreator-fields-completer # `all` or a comma-separated list of member [fields](/cloud/trello/guides/rest-api/object-definitions/)
  --organization: oneof<nothing, bool> # Whether to include the organization object (default: false)
  --organization-fields: string@organization-fields-completer # `all` or a comma-separated list of organization [fields](/cloud/trello/guides/rest-api/object-definitions/)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "board" $board "scalar") (serialize-qp "board_fields" $board_fields "scalar") (serialize-qp "card" $card "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "entities" $entities "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "list" $list "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "memberCreator" $memberCreator "scalar") (serialize-qp "memberCreator_fields" $memberCreator_fields "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "organization_fields" $organization_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/notifications/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Notification's read status
#
# PUT /notifications/{id}
# operationId: put-notifications-id
export def "notifications put-notifications-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --unread: oneof<nothing, bool> # Whether the notification should be marked as read or not
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unread" $unread "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/notifications/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a field of a Notification
#
# GET /notifications/{id}/{field}
# operationId: get-notifications-id-field
export def "notifications get-notifications-id-field" [
  id: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/($id)/($field)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Mark all Notifications as read
#
# POST /notifications/all/read
# operationId: post-notifications-all-read
export def "notifications-all-read post-notifications-all-read" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --read: oneof<nothing, bool> # Boolean to specify whether to mark as read or unread (defaults to `true`, marking as read) (default: true)
  --ids: list # A comma-seperated list of IDs. Allows specifying an array of notification IDs to change the read state for. This will become useful as we add grouping of notifications to the UI, with a single button to mark all notifications in the group as read/unread.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "read" $read "scalar") (serialize-qp "ids" $ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/all/read" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Notification's read status
#
# PUT /notifications/{id}/unread
# operationId: put-notifications-id-unread
export def "notifications-unread put-notifications-id-unread" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/notifications/($id)/unread" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Board a Notification is on
#
# GET /notifications/{id}/board
# operationId: get-notifications-id-board
export def "notifications-board get-notifications-id-board" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer # `all` or a comma-separated list of board[fields](/cloud/trello/guides/rest-api/object-definitions/)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/notifications/($id)/board" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Card a Notification is on
#
# GET /notifications/{id}/card
# operationId: get-notifications-id-card
export def "notifications-card get-notifications-id-card" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer-1 # `all` or a comma-separated list of card [fields](/cloud/trello/guides/rest-api/object-definitions/)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/notifications/($id)/card" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the List a Notification is on
#
# GET /notifications/{id}/list
# operationId: get-notifications-id-list
export def "notifications-list get-notifications-id-list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer-2 # `all` or a comma-separated list of list [fields](/cloud/trello/guides/rest-api/object-definitions/)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/notifications/($id)/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Member a Notification is about (not the creator)
#
# GET /notifications/{id}/member
# operationId: notificationsidmember
export def "notifications-member notificationsidmember" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer-2 # `all` or a comma-separated list of member [fields](/cloud/trello/guides/rest-api/object-definitions/)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/notifications/($id)/member" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Member who created the Notification
#
# GET /notifications/{id}/memberCreator
# operationId: get-notifications-id-membercreator
export def "notifications-member-creator get-notifications-id-membercreator" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer-2 # `all` or a comma-separated list of member [fields](/cloud/trello/guides/rest-api/object-definitions/)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/notifications/($id)/memberCreator" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Notification's associated Organization
#
# GET /notifications/{id}/organization
# operationId: get-notifications-id-organization
export def "notifications-organization get-notifications-id-organization" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer-3 # `all` or a comma-separated list of organization [fields](/cloud/trello/guides/rest-api/object-definitions/)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/notifications/($id)/organization" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Organization
#
# POST /organizations
# operationId: post-organizations
export def "organizations post-organizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string # The name to display for the Organization
  --desc: string # The description for the organizations
  --name: string # A string with a length of at least 3. Only lowercase letters, underscores, and numbers are allowed. If the name contains invalid characters, they will be removed. If the name conflicts with an existing name, a new name will be substituted.
  --website: string # A URL starting with `http://` or `https://` (format: url)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "displayName" $displayName "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "website" $website "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an Organization
#
# GET /organizations/{id}
# operationId: get-organizations-id
export def "organizations get-organizations-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, displayName: string, dateLastActivity: string, prefs: record<boardVisibilityRestrict: record, boardDeleteRestrict: record, attachmentRestrictions: list<string>, permissionLevel: string>, idEnterprise: string, offering: string, url: string, idBoards: list<string>, memberships: list<string>, premiumFeatures: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Organization
#
# PUT /organizations/{id}
# operationId: put-organizations-id
export def "organizations put-organizations-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A new name for the organization. At least 3 lowercase letters, underscores, and numbers. Must be unique
  --displayName: string # A new displayName for the organization. Must be at least 1 character long and not begin or end with a space.
  --desc: string # A new description for the organization
  --website: string # A URL starting with `http://`, `https://`, or `null`
  --prefsassociatedDomain: string # The Google Apps domain to link this org to.
  --prefsexternalMembersDisabled: oneof<nothing, bool> # Whether non-workspace members can be added to boards inside the Workspace
  --prefsgoogleAppsVersion: int # `1` or `2` (format: int32)
  --prefsboardVisibilityRestrictorg: string # Who on the Workspace can make Workspace visible boards. One of `admin`, `none`, `org`
  --prefsboardVisibilityRestrictprivate: string # Who can make private boards. One of: `admin`, `none`, `org`
  --prefsboardVisibilityRestrictpublic: string # Who on the Workspace can make public boards. One of: `admin`, `none`, `org`
  --prefsorgInviteRestrict: string # An email address with optional wildcard characters. (E.g. `subdomain.*.trello.com`)
  --prefspermissionLevel: string # Whether the Workspace page is publicly visible. One of: `private`, `public`
]: nothing -> record<id: string, name: string, displayName: string, dateLastActivity: string, prefs: record<boardVisibilityRestrict: record, boardDeleteRestrict: record, attachmentRestrictions: list<string>, permissionLevel: string>, idEnterprise: string, offering: string, url: string, idBoards: list<string>, memberships: list<string>, premiumFeatures: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "displayName" $displayName "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "website" $website "scalar") (serialize-qp "prefs/associatedDomain" $prefsassociatedDomain "scalar") (serialize-qp "prefs/externalMembersDisabled" $prefsexternalMembersDisabled "scalar") (serialize-qp "prefs/googleAppsVersion" $prefsgoogleAppsVersion "scalar") (serialize-qp "prefs/boardVisibilityRestrict/org" $prefsboardVisibilityRestrictorg "scalar") (serialize-qp "prefs/boardVisibilityRestrict/private" $prefsboardVisibilityRestrictprivate "scalar") (serialize-qp "prefs/boardVisibilityRestrict/public" $prefsboardVisibilityRestrictpublic "scalar") (serialize-qp "prefs/orgInviteRestrict" $prefsorgInviteRestrict "scalar") (serialize-qp "prefs/permissionLevel" $prefspermissionLevel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Organization
#
# DELETE /organizations/{id}
# operationId: delete-organizations-id
export def "organizations delete-organizations-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get field on Organization
#
# GET /organizations/{id}/{field}
# operationId: get-organizations-id-field
export def "organizations get-organizations-id-field" [
  id: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, displayName: string, dateLastActivity: string, prefs: record<boardVisibilityRestrict: record, boardDeleteRestrict: record, attachmentRestrictions: list<string>, permissionLevel: string>, idEnterprise: string, offering: string, url: string, idBoards: list<string>, memberships: list<string>, premiumFeatures: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/($field)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Actions for Organization
#
# GET /organizations/{id}/actions
# operationId: get-organizations-id-actions
export def "organizations-actions get-organizations-id-actions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, idMemberCreator: string, data: record<text: string, card: record, board: record, list: record>, type: string, date: string, limits: record<reactions: record>, display: record<translationKey: string, entities: record>, memberCreator: record<id: string, activityBlocked: bool, avatarHash: string, avatarUrl: string, fullName: string, idMemberReferrer: string, initials: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/actions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Boards in an Organization
#
# GET /organizations/{id}/boards
# operationId: get-organizations-id-boards
export def "organizations-boards get-organizations-id-boards" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-8 # `all` or a comma-separated list of: `open`, `closed`, `members`, `organization`, `public` (default: all)
  --qp-fields: string@fields-completer # `all` or a comma-separated list of board [fields](/cloud/trello/guides/rest-api/object-definitions/)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/boards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Export for Organizations
#
# POST /organizations/{id}/exports
# operationId: post-organizations-id-exports
export def "organizations-exports post-organizations-id-exports" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachments: oneof<nothing, bool> # Whether the CSV should include attachments or not. (default: true)
]: nothing -> record<id: string, status: record<attempts: float, finished: bool, stage: string>, startedAt: string, size: string, exportUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attachments" $attachments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/exports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Organization's Exports
#
# GET /organizations/{id}/exports
# operationId: get-organizations-id-exports
export def "organizations-exports get-organizations-id-exports" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, status: record<attempts: float, finished: bool, stage: string>, startedAt: string, size: string, exportUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/exports")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Members of an Organization
#
# GET /organizations/{id}/members
# operationId: get-organizations-id-members
export def "organizations-members get-organizations-id-members" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/members")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Organization's Members
#
# PUT /organizations/{id}/members
# operationId: put-organizations-id-members
export def "organizations-members put-organizations-id-members" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # An email address (format: email)
  --fullName: string # Name for the member, at least 1 character not beginning or ending with a space
  --type: string@type-completer-2 # One of: `admin`, `normal` (default: normal)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "fullName" $fullName "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Memberships of an Organization
#
# GET /organizations/{id}/memberships
# operationId: get-organizations-id-memberships
export def "organizations-memberships get-organizations-id-memberships" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-9 # `all` or a comma-separated list of: `active`, `admin`, `deactivated`, `me`, `normal` (default: all)
  --member: oneof<nothing, bool> # Whether to include the Member objects with the Memberships (default: false)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "member" $member "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Membership of an Organization
#
# GET /organizations/{id}/memberships/{idMembership}
# operationId: get-organizations-id-memberships-idmembership
export def "organizations-memberships get-organizations-id-memberships-idmembership" [
  id: string
  idMembership: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --member: oneof<nothing, bool> # Whether to include the Member object in the response (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "member" $member "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/memberships/($idMembership)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the pluginData Scoped to Organization
#
# GET /organizations/{id}/pluginData
# operationId: get-organizations-id-plugindata
export def "organizations-plugin-data get-organizations-id-plugindata" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/pluginData")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tags of an Organization
#
# GET /organizations/{id}/tags
# operationId: get-organizations-id-tags
export def "organizations-tags get-organizations-id-tags" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Tag in Organization
#
# POST /organizations/{id}/tags
# operationId: post-organizations-id-tags
export def "organizations-tags post-organizations-id-tags" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Member of an Organization
#
# PUT /organizations/{id}/members/{idMember}
# operationId: put-organizations-id-members-idmember
export def "organizations-members put-organizations-id-members-idmember" [
  id: string
  idMember: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-2 # One of: `admin`, `normal`
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/members/($idMember)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a Member from an Organization
#
# DELETE /organizations/{id}/members/{idMember}
# operationId: delete-organizations-id-members
export def "organizations-members delete-organizations-id-members" [
  id: string
  idMember: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/members/($idMember)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deactivate or reactivate a member of an Organization
#
# PUT /organizations/{id}/members/{idMember}/deactivated
# operationId: put-organizations-id-members-idmember-deactivated
export def "organizations-members-deactivated put-organizations-id-members-idmember-deactivated" [
  id: string
  idMember: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: oneof<nothing, bool>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/members/($idMember)/deactivated" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update logo for an Organization
#
# POST /organizations/{id}/logo
# operationId: post-organizations-id-logo
export def "organizations-logo post-organizations-id-logo" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # Image file for the logo (format: binary)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file" $file "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/logo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Logo for Organization
#
# DELETE /organizations/{id}/logo
# operationId: delete-organizations-id-logo
export def "organizations-logo delete-organizations-id-logo" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/logo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a Member from an Organization and all Organization Boards
#
# DELETE /organizations/{id}/members/{idMember}/all
# operationId: organizations-id-members-idmember-all
export def "organizations-members-all organizations-id-members-idmember-all" [
  id: string
  idMember: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/members/($idMember)/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove the associated Google Apps domain from a Workspace
#
# DELETE /organizations/{id}/prefs/associatedDomain
# operationId: delete-organizations-id-prefs-associateddomain
export def "organizations-prefs-associated-domain delete-organizations-id-prefs-associateddomain" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/prefs/associatedDomain")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the email domain restriction on who can be invited to the Workspace
#
# DELETE /organizations/{id}/prefs/orgInviteRestrict
# operationId: delete-organizations-id-prefs-orginviterestrict
export def "organizations-prefs-org-invite-restrict delete-organizations-id-prefs-orginviterestrict" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/prefs/orgInviteRestrict")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Organization's Tag
#
# DELETE /organizations/{id}/tags/{idTag}
# operationId: delete-organizations-id-tags-idtag
export def "organizations-tags delete-organizations-id-tags-idtag" [
  id: string
  idTag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/tags/($idTag)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Organizations new billable guests
#
# GET /organizations/{id}/newBillableGuests/{idBoard}
# operationId: get-organizations-id-newbillableguests-idboard
export def "organizations-new-billable-guests get-organizations-id-newbillableguests-idboard" [
  id: string
  idBoard: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/newBillableGuests/($idBoard)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Plugin
#
# GET /plugins/{id}/
# operationId: get-plugins-id
export def "plugins get-plugins-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plugins/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Plugin
#
# PUT /plugins/{id}/
# operationId: put-plugins-id
export def "plugins put-plugins-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plugins/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Listing for Plugin
#
# POST /plugins/{idPlugin}/listing
# operationId: post-plugins-idplugin-listing
export def "plugins-listing post-plugins-idplugin-listing" [
  idPlugin: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description to show for the given locale
  --locale: string # The locale that this listing should be displayed for.
  --overview: string # The overview to show for the given locale.
  --name: string # The name to use for the given locale.
]: any -> record<id: string, name: string, locale: string, description: string, overview: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plugins/($idPlugin)/listing")
  let body = {description: $description, locale: $locale, overview: $overview, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Plugin's Member privacy compliance
#
# GET /plugins/{id}/compliance/memberPrivacy
# operationId: get-plugins-id-compliance-memberprivacy
export def "plugins-compliance-member-privacy get-plugins-id-compliance-memberprivacy" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plugins/($id)/compliance/memberPrivacy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updating Plugin's Listing
#
# PUT /plugins/{idPlugin}/listings/{idListing}
# operationId: put-plugins-idplugin-listings-idlisting
export def "plugins-listings put-plugins-idplugin-listings-idlisting" [
  idPlugin: string
  idListing: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description to show for the given locale
  --locale: string # The locale that this listing should be displayed for.
  --overview: string # The overview to show for the given locale.
  --name: string # The name to use for the given locale.
]: any -> record<id: string, name: string, locale: string, description: string, overview: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plugins/($idPlugin)/listings/($idListing)")
  let body = {description: $description, locale: $locale, overview: $overview, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search Trello
#
# GET /search
# operationId: get-search
export def "search get-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # The search query with a length of 1 to 16384 characters
  --idBoards: string # `mine` or a comma-separated list of Board IDs
  --idOrganizations: string # A comma-separated list of Organization IDs
  --idCards: string # A comma-separated list of Card IDs
  --modelTypes: string # What type or types of Trello objects you want to search. all or a comma-separated list of: `actions`, `boards`, `cards`, `members`, `organizations` (default: all)
  --board-fields: string # all or a comma-separated list of: `closed`, `dateLastActivity`, `dateLastView`, `desc`, `descData`, `idOrganization`, `invitations`, `invited`, `labelNames`, `memberships`, `name`, `pinned`, `powerUps`, `prefs`, `shortLink`, `shortUrl`, `starred`, `subscribed`, `url` (default: name,idOrganization)
  --boards-limit: int # The maximum number of boards returned. Maximum: 1000 (default: 10)
  --board-organization: oneof<nothing, bool> # Whether to include the parent organization with board results (default: false)
  --card-fields: string # all or a comma-separated list of: `badges`, `checkItemStates`, `closed`, `dateLastActivity`, `desc`, `descData`, `due`, `idAttachmentCover`, `idBoard`, `idChecklists`, `idLabels`, `idList`, `idMembers`, `idMembersVoted`, `idShort`, `labels`, `manualCoverAttachment`, `name`, `pos`, `shortLink`, `shortUrl`, `subscribed`, `url` (default: all)
  --cards-limit: int # The maximum number of cards to return. Maximum: 1000 (default: 10)
  --cards-page: float # The page of results for cards. Maximum: 100 (default: 0)
  --card-board: oneof<nothing, bool> # Whether to include the parent board with card results (default: false)
  --card-list: oneof<nothing, bool> # Whether to include the parent list with card results (default: false)
  --card-members: oneof<nothing, bool> # Whether to include member objects with card results (default: false)
  --card-stickers: oneof<nothing, bool> # Whether to include sticker objects with card results (default: false)
  --card-attachments: string # Whether to include attachment objects with card results. A boolean value (true or false) or cover for only card cover attachments. (default: false)
  --organization-fields: string # all or a comma-separated list of billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url, website (default: name,displayName)
  --organizations-limit: int # The maximum number of Workspaces to return. Maximum 1000 (format: int32, default: 10)
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url, username (default: avatarHash,fullName,initials,username,confirmed)
  --members-limit: int # The maximum number of members to return. Maximum 1000 (format: int32, default: 10)
  --partial: oneof<nothing, bool> # By default, Trello searches for each word in your query against exactly matching words within Member content. Specifying partial to be true means that we will look for content that starts with any of the words in your query.  If you are looking for a Card titled "My Development Status Report", by default you would need to search for "Development". If you have partial enabled, you will be able to search for "dev" but not "velopment". (default: false)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "idBoards" $idBoards "scalar") (serialize-qp "idOrganizations" $idOrganizations "scalar") (serialize-qp "idCards" $idCards "scalar") (serialize-qp "modelTypes" $modelTypes "scalar") (serialize-qp "board_fields" $board_fields "scalar") (serialize-qp "boards_limit" $boards_limit "scalar") (serialize-qp "board_organization" $board_organization "scalar") (serialize-qp "card_fields" $card_fields "scalar") (serialize-qp "cards_limit" $cards_limit "scalar") (serialize-qp "cards_page" $cards_page "scalar") (serialize-qp "card_board" $card_board "scalar") (serialize-qp "card_list" $card_list "scalar") (serialize-qp "card_members" $card_members "scalar") (serialize-qp "card_stickers" $card_stickers "scalar") (serialize-qp "card_attachments" $card_attachments "scalar") (serialize-qp "organization_fields" $organization_fields "scalar") (serialize-qp "organizations_limit" $organizations_limit "scalar") (serialize-qp "member_fields" $member_fields "scalar") (serialize-qp "members_limit" $members_limit "scalar") (serialize-qp "partial" $partial "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for Members
#
# GET /search/members/
# operationId: get-search-members
export def "search-members get-search-members" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Search query 1 to 16384 characters long
  --limit: int # The maximum number of results to return. Maximum of 20. (format: int32, default: 8)
  --idBoard: string # e.g. 5abbe4b7ddc1b351ef961414
  --idOrganization: string # e.g. 5abbe4b7ddc1b351ef961414
  --onlyOrgMembers: oneof<nothing, bool> # default: false
]: nothing -> table<id: string, activityBlocked: bool, avatarHash: string, avatarUrl: string, bio: string, bioData: record<emoji: record>, confirmed: bool, fullName: string, idEnterprise: string, idEnterprisesDeactivated: list<string>, idMemberReferrer: string, idPremOrgsAdmin: list<string>, initials: string, memberType: string, nonPublic: record<fullName: string, initials: string, avatarUrl: string, avatarHash: string>, nonPublicAvailable: bool, products: list<int>, url: string, username: string, status: string, aaEmail: string, aaEnrolledDate: string, aaId: string, avatarSource: string, email: string, gravatarHash: string, idBoards: list<string>, idOrganizations: list<string>, idEnterprisesAdmin: list<string>, limits: record<status: string, disableAt: float, warnAt: float>, loginTypes: list<string>, marketingOptIn: record<optedIn: bool, date: string>, messagesDismissed: record<name: string, count: string, lastDismissed: string, _id: string>, oneTimeMessagesDismissed: list<string>, prefs: record<timezoneInfo: record, privacy: record, sendSummaries: bool, minutesBetweenSummaries: int, minutesBeforeDeadlineToNotify: int, colorBlind: bool, locale: string, timezone: string, twoFactor: record>, trophies: list<string>, uploadedAvatarHash: string, uploadedAvatarUrl: string, premiumFeatures: list<string>, isAaMastered: bool, ixUpdate: float, idBoardsPinned: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "idBoard" $idBoard "scalar") (serialize-qp "idOrganization" $idOrganization "scalar") (serialize-qp "onlyOrgMembers" $onlyOrgMembers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/members/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Token
#
# GET /tokens/{token}
# operationId: get-tokens-token
export def "tokens get-tokens-token" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer-11 # `all` or a comma-separated list of `dateCreated`, `dateExpires`, `idMember`, `identifier`, `permissions`
  --webhooks: oneof<nothing, bool> # Determines whether to include webhooks. (default: false)
]: nothing -> record<id: string, identifier: string, idMember: string, dateCreated: string, dateExpires: string, permissions: table<idModel: any, modelType: string, read: bool, write: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "webhooks" $webhooks "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tokens/($token)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Token's Member
#
# GET /tokens/{token}/member
# operationId: get-tokens-token-member
export def "tokens-member get-tokens-token-member" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string@fields-completer-2 # `all` or a comma-separated list of valid fields for [Member Object](/cloud/trello/guides/rest-api/object-definitions/).
]: nothing -> record<id: string, activityBlocked: bool, avatarHash: string, avatarUrl: string, bio: string, bioData: record<emoji: record>, confirmed: bool, fullName: string, idEnterprise: string, idEnterprisesDeactivated: list<string>, idMemberReferrer: string, idPremOrgsAdmin: list<string>, initials: string, memberType: string, nonPublic: record<fullName: string, initials: string, avatarUrl: string, avatarHash: string>, nonPublicAvailable: bool, products: list<int>, url: string, username: string, status: string, aaEmail: string, aaEnrolledDate: string, aaId: string, avatarSource: string, email: string, gravatarHash: string, idBoards: list<string>, idOrganizations: list<string>, idEnterprisesAdmin: list<string>, limits: record<status: string, disableAt: float, warnAt: float>, loginTypes: list<string>, marketingOptIn: record<optedIn: bool, date: string>, messagesDismissed: record<name: string, count: string, lastDismissed: string, _id: string>, oneTimeMessagesDismissed: list<string>, prefs: record<timezoneInfo: record<offsetCurrent: int, timezoneCurrent: string, offsetNext: int, dateNext: string, timezoneNext: string>, privacy: record<fullName: string, avatar: string>, sendSummaries: bool, minutesBetweenSummaries: int, minutesBeforeDeadlineToNotify: int, colorBlind: bool, locale: string, timezone: string, twoFactor: record<enabled: bool, needsNewBackups: bool>>, trophies: list<string>, uploadedAvatarHash: string, uploadedAvatarUrl: string, premiumFeatures: list<string>, isAaMastered: bool, ixUpdate: float, idBoardsPinned: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tokens/($token)/member" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Webhooks for Token
#
# GET /tokens/{token}/webhooks
# operationId: get-tokens-token-webhooks
export def "tokens-webhooks get-tokens-token-webhooks" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, description: string, idModel: string, callbackURL: string, active: bool, consecutiveFailures: float, firstConsecutiveFailDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tokens/($token)/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Webhooks for Token
#
# POST /tokens/{token}/webhooks
# operationId: post-tokens-token-webhooks
export def "tokens-webhooks post-tokens-token-webhooks" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A description to be displayed when retrieving information about the webhook.
  --callbackURL: string # The URL that the webhook should POST information to. (format: url)
  --idModel: string # ID of the object to create a webhook on. (e.g. 5abbe4b7ddc1b351ef961414)
]: nothing -> record<id: string, description: string, idModel: string, callbackURL: string, active: bool, consecutiveFailures: float, firstConsecutiveFailDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "description" $description "scalar") (serialize-qp "callbackURL" $callbackURL "scalar") (serialize-qp "idModel" $idModel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tokens/($token)/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Webhook belonging to a Token
#
# GET /tokens/{token}/webhooks/{idWebhook}
# operationId: get-tokens-token-webhooks-idwebhook
export def "tokens-webhooks get-tokens-token-webhooks-idwebhook" [
  token: string
  idWebhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, description: string, idModel: string, callbackURL: string, active: bool, consecutiveFailures: float, firstConsecutiveFailDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tokens/($token)/webhooks/($idWebhook)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Webhook created by Token
#
# DELETE /tokens/{token}/webhooks/{idWebhook}
# operationId: delete-tokens-token-webhooks-idwebhook
export def "tokens-webhooks delete-tokens-token-webhooks-idwebhook" [
  token: string
  idWebhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tokens/($token)/webhooks/($idWebhook)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Webhook created by Token
#
# PUT /tokens/{token}/webhooks/{idWebhook}
# operationId: tokenstokenwebhooks-1
export def "tokens-webhooks tokenstokenwebhooks-1" [
  token: string
  idWebhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A description to be displayed when retrieving information about the webhook.
  --callbackURL: string # The URL that the webhook should `POST` information to. (format: url)
  --idModel: string # ID of the object that the webhook is on. (e.g. 5abbe4b7ddc1b351ef961414)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "description" $description "scalar") (serialize-qp "callbackURL" $callbackURL "scalar") (serialize-qp "idModel" $idModel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tokens/($token)/webhooks/($idWebhook)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Token
#
# DELETE /tokens/{token}/
# operationId: delete-token
export def "tokens delete-token" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tokens/($token)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Webhook
#
# POST /webhooks/
# operationId: post-webhooks
export def "webhooks post-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A string with a length from `0` to `16384`.
  --callbackURL: string # A valid URL that is reachable with a `HEAD` and `POST` request. (format: url)
  --idModel: string # ID of the model to be monitored (e.g. 5abbe4b7ddc1b351ef961414)
  --active: oneof<nothing, bool> # Determines whether the webhook is active and sending `POST` requests.
]: nothing -> record<id: string, description: string, idModel: string, callbackURL: string, active: bool, consecutiveFailures: float, firstConsecutiveFailDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "description" $description "scalar") (serialize-qp "callbackURL" $callbackURL "scalar") (serialize-qp "idModel" $idModel "scalar") (serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Webhook
#
# GET /webhooks/{id}
# operationId: get-webhooks-id
export def "webhooks get-webhooks-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, description: string, idModel: string, callbackURL: string, active: bool, consecutiveFailures: float, firstConsecutiveFailDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Webhook
#
# PUT /webhooks/{id}
# operationId: put-webhooks-id
export def "webhooks put-webhooks-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A string with a length from `0` to `16384`.
  --callbackURL: string # A valid URL that is reachable with a `HEAD` and `POST` request. (format: url)
  --idModel: string # ID of the model to be monitored (e.g. 5abbe4b7ddc1b351ef961414)
  --active: oneof<nothing, bool> # Determines whether the webhook is active and sending `POST` requests.
]: nothing -> record<id: string, description: string, idModel: string, callbackURL: string, active: bool, consecutiveFailures: float, firstConsecutiveFailDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "description" $description "scalar") (serialize-qp "callbackURL" $callbackURL "scalar") (serialize-qp "idModel" $idModel "scalar") (serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Webhook
#
# DELETE /webhooks/{id}
# operationId: delete-webhooks-id
export def "webhooks delete-webhooks-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a field on a Webhook
#
# GET /webhooks/{id}/{field}
# operationId: webhooksidfield
export def "webhooks webhooksidfield" [
  id: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($id)/($field)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
