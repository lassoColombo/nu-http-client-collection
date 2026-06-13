# Auto-generated client for Flat API v2.13.0
# Source: https://api.apis.guru/v2/specs/flat.io/2.13.0/openapi.json
# Auth: --token flag or $env.FLAT_API_TOKEN

const BASE_URL = "https://api.flat.io/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FLAT_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.flat.io/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def state-completer [] { ["active" "archived" "inactive"] }
def assigneeMode-completer [] { ["everyone" "selected"] }
def state-completer-1 [] { ["active" "draft"] }
def type-completer [] { ["newScore" "none" "performance" "scoreTemplate" "sharedWriting" "worksheet"] }
def sort-completer [] { ["creationDate" "title"] }
def direction-completer [] { ["asc" "desc"] }
def privacy-completer [] { ["private"] }
def sort-completer-1 [] { ["creationDate" "modificationDate" "title"] }
def source-completer [] { ["clever" "googleClassroom" "microsoftGraph"] }
def role-completer [] { ["admin" "teacher" "user"] }
def organizationRole-completer [] { ["admin" "billing" "teacher" "user"] }
def lms-completer [] { ["blackboard" "canvas" "desire2learn" "moodle" "other" "sakai" "schoolbox" "schoology"] }
def locale-completer [] { ["de" "en" "en-GB" "es" "fr" "it" "ja" "ko" "nl" "pl" "pt" "pt-BR" "ro" "ru" "sv" "tr" "zh-Hans"] }
def dataEncoding-completer [] { ["base64"] }
def privacy-completer-1 [] { ["organizationPublic" "private" "privateLink" "public"] }
def creationType-completer [] { ["arrangement" "original" "other"] }
def license-completer [] { ["cc-by" "cc-by-nc" "cc-by-nc-nd" "cc-by-nc-sa" "cc-by-nd" "cc-by-sa" "cc0" "copyright"] }
def type-completer-1 [] { ["document" "inline"] }
def sort-completer-2 [] { ["date"] }
def accept-completer [] { ["application/json" "application/vnd.recordare.musicxml" "application/vnd.recordare.musicxml+xml" "audio/midi" "audio/mp3" "audio/wav" "image/png"] }
def state-completer-2 [] { ["completed" "deleted" "draft"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "classes listClasses" } } | get name | first)
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

# List the classes available for the current user
#
# GET /classes
# operationId: listClasses
export def "classes listClasses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer # Filter the classes by state (default: active)
]: nothing -> table<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/classes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new class
#
# POST /classes
# operationId: createClass
export def "classes createClass" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the new class
  --section: string # The section of the new class
]: any -> record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classes")
  let body = {name: $name, section: $section} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Join a class
#
# POST /classes/enroll/{enrollmentCode}
# operationId: enrollClass
export def "classes-enroll enrollClass" [
  enrollmentCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/enroll/($enrollmentCode)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the details of a single class
#
# GET /classes/{class}
# operationId: getClass
export def "classes get" [
  class: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the class
#
# PUT /classes/{class}
# operationId: updateClass
export def "classes updateClass" [
  class: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the class
  --section: string # The section of the class
]: any -> record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)")
  let body = {name: $name, section: $section} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Activate the class
#
# POST /classes/{class}/activate
# operationId: activateClass
export def "classes-activate activateClass" [
  class: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/activate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unarchive the class
#
# DELETE /classes/{class}/archive
# operationId: unarchiveClass
export def "classes-archive unarchiveClass" [
  class: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/archive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive the class
#
# POST /classes/{class}/archive
# operationId: archiveClass
export def "classes-archive archiveClass" [
  class: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/archive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assignments listing
#
# GET /classes/{class}/assignments
# operationId: listAssignments
export def "classes-assignments listAssignments" [
  class: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attachments: list<record>, canvas: record<alternateLink: string, id: string>, classroom: string, cover: string, coverFile: string, creationDate: string, creator: string, description: string, dueDate: string, googleClassroom: record<alternateLink: string, id: string, state: string, topicId: string>, lti: record<id: string>, maxPoints: float, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<alternateLink: string, categories: list, id: string, state: string>, scheduledDate: string, state: string, submissions: list<record>, title: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/assignments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assignment creation
#
# POST /classes/{class}/assignments
# operationId: createAssignment
# --attachments item shape: {googleDriveFileId?: string, lockScoreTemplate?: bool, score?: string, sharingMode?: "read"|"write"|"copy"|"performance", type?: "flat"|"link"|"googleDrive"|"worksheet", url?: string, worksheet?: string}
# --googleClassroom shape: {topicId?: string}
# --microsoftGraph shape: {categories?: list}
export def "classes-assignments createAssignment" [
  class: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignedStudents: list # Identifiers for the students that have access to the assignment
  --assigneeMode: string@assigneeMode-completer # Possible modes of assigning assignments
  --attachments: list # item shape: {googleDriveFileId?: string, lockScoreTemplate?: bool, score?: string, sharingMode?: "read"|"write"|"copy"|"performance", type?: "flat"|"link"|"googleDrive"|"worksheet", url?: string, worksheet?: string}
  --cover: string # The URL of the cover to display (nullable)
  --coverFile: string # The id of the cover to display (nullable)
  --description: string # Description and content of the assignment
  --dueDate: string # The due date of this assignment, late submissions will be marked as paste due. If not set, the assignment won't have a due date.  (nullable, format: date-time)
  --googleClassroom: record # Google Classroom options for this assignment — shape: {topicId?: string}
  --maxPoints: float # If set, the grading will be enabled for the assignement with this value as the maximum of points  (nullable)
  --microsoftGraph: record # Microsoft Graph options for this assignment — shape: {categories?: list}
  --nbPlaybackAuthorized: float # The number of playback authorized on the scores of the assignment. (nullable)
  --scheduledDate: string # The publication (scheduled) date of the assignment. If this one is specified, the assignment will only be listed to the teachers of the class.  (nullable, format: date-time)
  --state: string@state-completer-1 # State of the assignment
  --title: string # Title of the assignment
  --toolset: string # The id of the associated toolset (nullable)
  --type: string@type-completer # Type of the assignment
]: any -> record<attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, canvas: record<alternateLink: string, id: string>, classroom: string, cover: string, coverFile: string, creationDate: string, creator: string, description: string, dueDate: string, googleClassroom: record<alternateLink: string, id: string, state: string, topicId: string>, lti: record<id: string>, maxPoints: float, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<alternateLink: string, categories: list<string>, id: string, state: string>, scheduledDate: string, state: string, submissions: table<assignment: string, attachments: list, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record, grade: float, id: string, maxPoints: float, microsoftGraph: record, returnCreator: string, returnDate: string, state: string, submissionDate: string>, title: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/assignments")
  let body = {assignedStudents: $assignedStudents, assigneeMode: $assigneeMode, attachments: $attachments, cover: $cover, coverFile: $coverFile, description: $description, dueDate: $dueDate, googleClassroom: $googleClassroom, maxPoints: $maxPoints, microsoftGraph: $microsoftGraph, nbPlaybackAuthorized: $nbPlaybackAuthorized, scheduledDate: $scheduledDate, state: $state, title: $title, toolset: $toolset, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unarchive the assignment.
#
# DELETE /classes/{class}/assignments/{assignment}/archive
# operationId: unarchiveAssignment
export def "classes-assignments-archive unarchiveAssignment" [
  class: string
  assignment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, canvas: record<alternateLink: string, id: string>, classroom: string, cover: string, coverFile: string, creationDate: string, creator: string, description: string, dueDate: string, googleClassroom: record<alternateLink: string, id: string, state: string, topicId: string>, lti: record<id: string>, maxPoints: float, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<alternateLink: string, categories: list<string>, id: string, state: string>, scheduledDate: string, state: string, submissions: table<assignment: string, attachments: list, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record, grade: float, id: string, maxPoints: float, microsoftGraph: record, returnCreator: string, returnDate: string, state: string, submissionDate: string>, title: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/assignments/($assignment)/archive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive the assignment
#
# POST /classes/{class}/assignments/{assignment}/archive
# operationId: archiveAssignment
export def "classes-assignments-archive archiveAssignment" [
  class: string
  assignment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, canvas: record<alternateLink: string, id: string>, classroom: string, cover: string, coverFile: string, creationDate: string, creator: string, description: string, dueDate: string, googleClassroom: record<alternateLink: string, id: string, state: string, topicId: string>, lti: record<id: string>, maxPoints: float, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<alternateLink: string, categories: list<string>, id: string, state: string>, scheduledDate: string, state: string, submissions: table<assignment: string, attachments: list, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record, grade: float, id: string, maxPoints: float, microsoftGraph: record, returnCreator: string, returnDate: string, state: string, submissionDate: string>, title: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/assignments/($assignment)/archive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Copy an assignment
#
# POST /classes/{class}/assignments/{assignment}/copy
# operationId: copyAssignment
export def "classes-assignments-copy copyAssignment" [
  class: string
  assignment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-assignment: string # An optional destination assignment where the original assignement will be copied. Must be a draft.
  --classroom: string # The destination classroom where the assignment will be copied
  --scheduledDate: string # The publication (scheduled) date of the assignment. If this one is specified, the assignment will only be listed to the teachers of the class. Alternatively the existing `scheduledDate` from the copied assignment will be used.  (format: date-time)
]: any -> record<attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, canvas: record<alternateLink: string, id: string>, classroom: string, cover: string, coverFile: string, creationDate: string, creator: string, description: string, dueDate: string, googleClassroom: record<alternateLink: string, id: string, state: string, topicId: string>, lti: record<id: string>, maxPoints: float, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<alternateLink: string, categories: list<string>, id: string, state: string>, scheduledDate: string, state: string, submissions: table<assignment: string, attachments: list, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record, grade: float, id: string, maxPoints: float, microsoftGraph: record, returnCreator: string, returnDate: string, state: string, submissionDate: string>, title: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/assignments/($assignment)/copy")
  let body = {assignment: $body_assignment, classroom: $classroom, scheduledDate: $scheduledDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the students' submissions
#
# GET /classes/{class}/assignments/{assignment}/submissions
# operationId: getSubmissions
export def "classes-assignments-submissions list" [
  class: string
  assignment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<assignment: string, attachments: list<record>, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record<alternateLink: string, id: string, state: string>, grade: float, id: string, maxPoints: float, microsoftGraph: record<alternateLink: string, id: string, state: string>, returnCreator: string, returnDate: string, state: string, submissionDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/assignments/($assignment)/submissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or edit a submission
#
# PUT /classes/{class}/assignments/{assignment}/submissions
# operationId: createSubmission
# --attachments item shape: {googleDriveFileId?: string, lockScoreTemplate?: bool, score?: string, sharingMode?: "read"|"write"|"copy"|"performance", type?: "flat"|"link"|"googleDrive"|"worksheet", url?: string, worksheet?: string}
# --comments shape: {total?: float, unread?: float}
export def "classes-assignments-submissions createSubmission" [
  class: string
  assignment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachments: list # item shape: {googleDriveFileId?: string, lockScoreTemplate?: bool, score?: string, sharingMode?: "read"|"write"|"copy"|"performance", type?: "flat"|"link"|"googleDrive"|"worksheet", url?: string, worksheet?: string}
  --comments: record # shape: {total?: float, unread?: float}
  --draftGrade: float # Optional grade. If unset, no grade was set. This value is only visible by the teacher, and we will be set to `grade` once the teacher returns the submission (nullable)
  --grade: float # Optional grade. If unset, no grade was set. (nullable)
  --body-return: oneof<nothing, bool> # If `true`, the submission will be marked as done
  --submit: oneof<nothing, bool> # If `true`, the submission will be marked as done
]: any -> record<assignment: string, attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record<alternateLink: string, id: string, state: string>, grade: float, id: string, maxPoints: float, microsoftGraph: record<alternateLink: string, id: string, state: string>, returnCreator: string, returnDate: string, state: string, submissionDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/assignments/($assignment)/submissions")
  let body = {attachments: $attachments, comments: $comments, draftGrade: $draftGrade, grade: $grade, return: $body_return, submit: $submit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# CSV Grades exports
#
# GET /classes/{class}/assignments/{assignment}/submissions/csv
# operationId: exportSubmissionsReviewsAsCsv
export def "classes-assignments-submissions-csv exportSubmissionsReviewsAsCsv" [
  class: string
  assignment: string
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
  let full_url = (build-url $base $"/classes/($class)/assignments/($assignment)/submissions/csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Excel Grades exports
#
# GET /classes/{class}/assignments/{assignment}/submissions/excel
# operationId: exportSubmissionsReviewsAsExcel
export def "classes-assignments-submissions-excel exportSubmissionsReviewsAsExcel" [
  class: string
  assignment: string
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
  let full_url = (build-url $base $"/classes/($class)/assignments/($assignment)/submissions/excel")
  let accept_val = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a submission
#
# DELETE /classes/{class}/assignments/{assignment}/submissions/{submission}
# operationId: deleteSubmission
export def "classes-assignments-submissions delete" [
  class: string
  assignment: string
  submission: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, id: string, message: string, param: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/assignments/($assignment)/submissions/($submission)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a student submission
#
# GET /classes/{class}/assignments/{assignment}/submissions/{submission}
# operationId: getSubmission
export def "classes-assignments-submissions get" [
  class: string
  assignment: string
  submission: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignment: string, attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record<alternateLink: string, id: string, state: string>, grade: float, id: string, maxPoints: float, microsoftGraph: record<alternateLink: string, id: string, state: string>, returnCreator: string, returnDate: string, state: string, submissionDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/assignments/($assignment)/submissions/($submission)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a submission
#
# PUT /classes/{class}/assignments/{assignment}/submissions/{submission}
# operationId: editSubmission
# --attachments item shape: {googleDriveFileId?: string, lockScoreTemplate?: bool, score?: string, sharingMode?: "read"|"write"|"copy"|"performance", type?: "flat"|"link"|"googleDrive"|"worksheet", url?: string, worksheet?: string}
# --comments shape: {total?: float, unread?: float}
export def "classes-assignments-submissions editSubmission" [
  class: string
  assignment: string
  submission: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachments: list # item shape: {googleDriveFileId?: string, lockScoreTemplate?: bool, score?: string, sharingMode?: "read"|"write"|"copy"|"performance", type?: "flat"|"link"|"googleDrive"|"worksheet", url?: string, worksheet?: string}
  --comments: record # shape: {total?: float, unread?: float}
  --draftGrade: float # Optional grade. If unset, no grade was set. This value is only visible by the teacher, and we will be set to `grade` once the teacher returns the submission (nullable)
  --grade: float # Optional grade. If unset, no grade was set. (nullable)
  --body-return: oneof<nothing, bool> # If `true`, the submission will be marked as done
  --submit: oneof<nothing, bool> # If `true`, the submission will be marked as done
]: any -> record<assignment: string, attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record<alternateLink: string, id: string, state: string>, grade: float, id: string, maxPoints: float, microsoftGraph: record<alternateLink: string, id: string, state: string>, returnCreator: string, returnDate: string, state: string, submissionDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/assignments/($assignment)/submissions/($submission)")
  let body = {attachments: $attachments, comments: $comments, draftGrade: $draftGrade, grade: $grade, return: $body_return, submit: $submit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the feedback comments of a submission
#
# GET /classes/{class}/assignments/{assignment}/submissions/{submission}/comments
# operationId: getSubmissionComments
export def "classes-assignments-submissions-comments get" [
  class: string
  assignment: string
  submission: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<comment: string, date: string, id: string, modificationDate: string, submission: string, unread: bool, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/assignments/($assignment)/submissions/($submission)/comments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a feedback comment to a submission
#
# POST /classes/{class}/assignments/{assignment}/submissions/{submission}/comments
# operationId: postSubmissionComment
export def "classes-assignments-submissions-comments post" [
  class: string
  assignment: string
  submission: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  comment: string # The comment text
]: any -> record<comment: string, date: string, id: string, modificationDate: string, submission: string, unread: bool, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/assignments/($assignment)/submissions/($submission)/comments")
  let body = {comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a feedback comment to a submission
#
# DELETE /classes/{class}/assignments/{assignment}/submissions/{submission}/comments/{comment}
# operationId: deleteSubmissionComment
export def "classes-assignments-submissions-comments delete" [
  class: string
  assignment: string
  submission: string
  comment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, id: string, message: string, param: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/assignments/($assignment)/submissions/($submission)/comments/($comment)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a feedback comment to a submission
#
# PUT /classes/{class}/assignments/{assignment}/submissions/{submission}/comments/{comment}
# operationId: updateSubmissionComment
export def "classes-assignments-submissions-comments updateSubmissionComment" [
  class: string
  assignment: string
  submission: string
  comment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-comment: string # The comment text
]: any -> record<comment: string, date: string, id: string, modificationDate: string, submission: string, unread: bool, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/assignments/($assignment)/submissions/($submission)/comments/($comment)")
  let body = {comment: $body_comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the history of the submission
#
# GET /classes/{class}/assignments/{assignment}/submissions/{submission}/history
# operationId: getSubmissionHistory
export def "classes-assignments-submissions-history get" [
  class: string
  assignment: string
  submission: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attachment: record<revision: string, score: string>, date: string, draftGrade: float, grade: float, maxPoints: float, state: string, users: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/assignments/($assignment)/submissions/($submission)/history")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the submissions for a student
#
# GET /classes/{class}/students/{user}/submissions
# operationId: listClassStudentSubmissions
export def "classes-students-submissions listClassStudentSubmissions" [
  class: string
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<assignment: string, attachments: list<record>, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record<alternateLink: string, id: string, state: string>, grade: float, id: string, maxPoints: float, microsoftGraph: record<alternateLink: string, id: string, state: string>, returnCreator: string, returnDate: string, state: string, submissionDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/students/($user)/submissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a user from the class
#
# DELETE /classes/{class}/users/{user}
# operationId: deleteClassUser
export def "classes-users delete" [
  class: string
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, id: string, message: string, param: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/users/($user)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a user to the class
#
# PUT /classes/{class}/users/{user}
# operationId: addClassUser
export def "classes-users addClassUser" [
  class: string
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, id: string, message: string, param: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classes/($class)/users/($user)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the collections
#
# GET /collections
# operationId: listCollections
export def "collections listCollections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --parent: string # List the collection contained in this `parent` collection.  This option doesn't provide a complete multi-level collection support. When sharing a collection with someone, this one will have as `parent` `sharedWithMe`.  (default: root)
  --qp-sort: string@sort-completer # Sort
  --direction: string@direction-completer # Sort direction
  --limit: int # This is the maximum number of objects that may be returned (default: 25)
  --next: string # An opaque string cursor to fetch the next page of data. The paginated API URLs are returned in the `Link` header when requesting the API. These URLs will contain a `next` and `previous` cursor based on the available data.
  --previous: string # An opaque string cursor to fetch the previous page of data. The paginated API URLs are returned in the `Link` header when requesting the API. These URLs will contain a `next` and `previous` cursor based on the available data.
]: nothing -> table<app: string, capabilities: record<canAddScores: bool, canDelete: bool, canDeleteScores: bool, canEdit: bool, canShare: bool>, collaborators: list<record>, collections: list<string>, creationDate: string, htmlUrl: string, id: string, privacy: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, sharingKey: string, title: string, type: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent" $parent "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "next" $next "scalar") (serialize-qp "previous" $previous "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/collections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new collection
#
# POST /collections
# operationId: createCollection
export def "collections createCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  privacy: string@privacy-completer # The collection main privacy mode. - `private`: The collection is private and can be only accessed, modified and administred by specified collaborators users.
  title: string # The title of the collection
]: any -> record<app: string, capabilities: record<canAddScores: bool, canDelete: bool, canDeleteScores: bool, canEdit: bool, canShare: bool>, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, creationDate: string, htmlUrl: string, id: string, privacy: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, sharingKey: string, title: string, type: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collections")
  let body = {privacy: $privacy, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the collection
#
# DELETE /collections/{collection}
# operationId: deleteCollection
export def "collections delete" [
  collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, id: string, message: string, param: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collection)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get collection details
#
# GET /collections/{collection}
# operationId: getCollection
export def "collections get" [
  collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharingKey: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> record<app: string, capabilities: record<canAddScores: bool, canDelete: bool, canDeleteScores: bool, canEdit: bool, canShare: bool>, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, creationDate: string, htmlUrl: string, id: string, privacy: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, sharingKey: string, title: string, type: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sharingKey" $sharingKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a collection's metadata
#
# PUT /collections/{collection}
# operationId: editCollection
export def "collections editCollection" [
  collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --privacy: string@privacy-completer # The collection main privacy mode. - `private`: The collection is private and can be only accessed, modified and administred by specified collaborators users.
  --title: string # The title of the collection
]: any -> record<app: string, capabilities: record<canAddScores: bool, canDelete: bool, canDeleteScores: bool, canEdit: bool, canShare: bool>, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, creationDate: string, htmlUrl: string, id: string, privacy: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, sharingKey: string, title: string, type: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collection)")
  let body = {privacy: $privacy, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the scores contained in a collection
#
# GET /collections/{collection}/scores
# operationId: listCollectionScores
export def "collections-scores listCollectionScores" [
  collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharingKey: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
  --qp-sort: string@sort-completer-1 # Sort
  --direction: string@direction-completer # Sort direction
  --limit: int # This is the maximum number of objects that may be returned (default: 25)
  --next: string # An opaque string cursor to fetch the next page of data. The paginated API URLs are returned in the `Link` header when requesting the API. These URLs will contain a `next` and `previous` cursor based on the available data.
  --previous: string # An opaque string cursor to fetch the previous page of data. The paginated API URLs are returned in the `Link` header when requesting the API. These URLs will contain a `next` and `previous` cursor based on the available data.
]: nothing -> table<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: list<record>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sharingKey" $sharingKey "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "next" $next "scalar") (serialize-qp "previous" $previous "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection)/scores" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a score from the collection
#
# DELETE /collections/{collection}/scores/{score}
# operationId: deleteScoreFromCollection
export def "collections-scores delete" [
  collection: string
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharingKey: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> record<code: string, id: string, message: string, param: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sharingKey" $sharingKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection)/scores/($score)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a score to the collection
#
# PUT /collections/{collection}/scores/{score}
# operationId: addScoreToCollection
export def "collections-scores addScoreToCollection" [
  collection: string
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharingKey: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> record<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sharingKey" $sharingKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection)/scores/($score)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Untrash a collection
#
# POST /collections/{collection}/untrash
# operationId: untrashCollection
export def "collections-untrash untrashCollection" [
  collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, id: string, message: string, param: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collection)/untrash")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get group information
#
# GET /groups/{group}
# operationId: getGroupDetails
export def "groups get" [
  group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List group's scores
#
# GET /groups/{group}/scores
# operationId: getGroupScores
export def "groups-scores get" [
  group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --parent: string # Filter the score forked from the score id `parent`
]: nothing -> table<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: list<record>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent" $parent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group)/scores" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List group's users
#
# GET /groups/{group}/users
# operationId: listGroupUsers
export def "groups-users listGroupUsers" [
  group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-source: string@source-completer # Filter the users by their source
]: nothing -> table<bio: string, coverPicture: string, followersCount: int, followingCount: int, instruments: list<string>, likedScoresCount: int, ownedPublicScoresCount: int, profileTheme: string, registrationDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get current user profile
#
# GET /me
# operationId: getAuthenticatedUser
export def "me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --onlyId: oneof<nothing, bool> # Only return the user id (default: false)
]: nothing -> record<coverPictureFile: string, id: string, locale: string, pictureFile: string, privateProfile: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "onlyId" $onlyId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the organization invitations
#
# GET /organizations/invitations
# operationId: listOrganizationInvitations
export def "organizations-invitations listOrganizationInvitations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # Filter users by role
  --limit: int # This is the maximum number of objects that may be returned (default: 50)
  --next: string # An opaque string cursor to fetch the next page of data. The paginated API URLs are returned in the `Link` header when requesting the API. These URLs will contain a `next` and `previous` cursor based on the available data.
  --previous: string # An opaque string cursor to fetch the previous page of data. The paginated API URLs are returned in the `Link` header when requesting the API. These URLs will contain a `next` and `previous` cursor based on the available data.
]: nothing -> table<customCode: string, email: string, id: string, invitedBy: string, organization: string, organizationRole: string, usedBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "next" $next "scalar") (serialize-qp "previous" $previous "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizations/invitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new invitation to join the organization
#
# POST /organizations/invitations
# operationId: createOrganizationInvitation
export def "organizations-invitations createOrganizationInvitation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address you want to send the invitation to
  --organizationRole: string@organizationRole-completer # User's Organization Role (for Edu users only)
]: any -> record<customCode: string, email: string, id: string, invitedBy: string, organization: string, organizationRole: string, usedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizations/invitations")
  let body = {email: $email, organizationRole: $organizationRole} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an organization invitation
#
# DELETE /organizations/invitations/{invitation}
# operationId: removeOrganizationInvitation
export def "organizations-invitations removeOrganizationInvitation" [
  invitation: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, id: string, message: string, param: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/invitations/($invitation)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List LTI 1.x credentials
#
# GET /organizations/lti/credentials
# operationId: listLtiCredentials
export def "organizations-lti-credentials listLtiCredentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<consumerKey: string, consumerSecret: string, creationDate: string, creator: string, id: string, lastUsage: string, lms: string, name: string, organization: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizations/lti/credentials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new couple of LTI 1.x credentials
#
# POST /organizations/lti/credentials
# operationId: createLtiCredentials
export def "organizations-lti-credentials createLtiCredentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  lms: string@lms-completer # LMS name
  name: string # Name of the couple of credentials
]: any -> record<consumerKey: string, consumerSecret: string, creationDate: string, creator: string, id: string, lastUsage: string, lms: string, name: string, organization: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizations/lti/credentials")
  let body = {lms: $lms, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke LTI 1.x credentials
#
# DELETE /organizations/lti/credentials/{credentials}
# operationId: revokeLtiCredentials
export def "organizations-lti-credentials revokeLtiCredentials" [
  credentials: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, id: string, message: string, param: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/lti/credentials/($credentials)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the organization users
#
# GET /organizations/users
# operationId: listOrganizationUsers
export def "organizations-users listOrganizationUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # The order to sort the user list
  --direction: string@direction-completer # Sort direction
  --next: string # An opaque string cursor to fetch the next page of data. The paginated API URLs are returned in the `Link` header when requesting the API. These URLs will contain a `next` and `previous` cursor based on the available data.
  --previous: string # An opaque string cursor to fetch the previous page of data. The paginated API URLs are returned in the `Link` header when requesting the API. These URLs will contain a `next` and `previous` cursor based on the available data.
  --role: list # Filter users by role
  --q: string # The query to search
  --group: list # Filter users by group
  --noActiveLicense: oneof<nothing, bool> # Filter users who don't have an active license
  --licenseExpirationDate: list # Filter users by license expiration date or `active` / `notActive`
  --onlyIds: oneof<nothing, bool> # Return only user ids
  --limit: int # This is the maximum number of objects that may be returned (default: 25)
]: nothing -> table<email: string, lastActivityDate: string, license: record<active: bool, expirationDate: string, id: string, mode: string, source: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "next" $next "scalar") (serialize-qp "previous" $previous "scalar") (serialize-qp "role" $role "multi") (serialize-qp "q" $q "scalar") (serialize-qp "group" $group "multi") (serialize-qp "noActiveLicense" $noActiveLicense "scalar") (serialize-qp "licenseExpirationDate" $licenseExpirationDate "multi") (serialize-qp "onlyIds" $onlyIds "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizations/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new user account
#
# POST /organizations/users
# operationId: createOrganizationUser
export def "organizations-users createOrganizationUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email of the new account (format: email)
  --firstname: string # First name of the user
  --lastname: string # Last name of the user
  --locale: string@locale-completer # The user language (default: en)
  password: string # Password of the new account (format: password)
  username: string # Username of the new account
]: any -> record<email: string, lastActivityDate: string, license: record<active: bool, expirationDate: string, id: string, mode: string, source: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizations/users")
  let body = {email: $email, firstname: $firstname, lastname: $lastname, locale: $locale, password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Count the organization users using the provided filters
#
# GET /organizations/users/count
# operationId: countOrgaUsers
export def "organizations-users-count countOrgaUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: list # Filter users by role
  --q: string # The query to search
  --group: list # Filter users by group
  --noActiveLicense: oneof<nothing, bool> # Filter users who don't have an active license
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "multi") (serialize-qp "q" $q "scalar") (serialize-qp "group" $group "multi") (serialize-qp "noActiveLicense" $noActiveLicense "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizations/users/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove an account from Flat
#
# DELETE /organizations/users/{user}
# operationId: removeOrganizationUser
export def "organizations-users removeOrganizationUser" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --convertToIndividual: oneof<nothing, bool> # If `true`, the account will be only removed from the organization and converted into an individual account on our public website, https://flat.io. This operation will remove the education-related data from the account. Before realizing this operation, you need to be sure that the user is at least 13 years old and that this one has read and agreed to the Individual Terms of Services of Flat available on https://flat.io/legal.
]: nothing -> record<code: string, id: string, message: string, param: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "convertToIndividual" $convertToIndividual "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/users/($user)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update account information
#
# PUT /organizations/users/{user}
# operationId: updateOrganizationUser
export def "organizations-users updateOrganizationUser" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email of the account (format: email)
  --firstname: string # First name of the user
  --lastname: string # Last name of the user
  --organizationRole: string@organizationRole-completer # User's Organization Role (for Edu users only)
  --password: string # Password of the account (format: password)
  --username: string # Username of the account
]: any -> record<email: string, lastActivityDate: string, license: record<active: bool, expirationDate: string, id: string, mode: string, source: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/users/($user)")
  let body = {email: $email, firstname: $firstname, lastname: $lastname, organizationRole: $organizationRole, password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new score
#
# POST /scores
# operationId: createScore
# --source shape: {googleDrive?: string}
export def "scores createScore" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --collection: string # Unique identifier of a collection where the score will be created. If no collection identifier is provided, the score will be stored in the `root` directory.
  --data: string # The data of the score file. It must be a MusicXML 3 file (`vnd.recordare.musicxml` or `vnd.recordare.musicxml+xml`), a MIDI file (`audio/midi`) or a Flat.json (aka Adagio.json) file. Binary payloads (`vnd.recordare.musicxml` and `audio/midi`) can be encoded in Base64, in this case the `dataEncoding` property must match the encoding used for the API request.  (e.g. <score-partwise version="3.0"></score-partwise>)
  --dataEncoding: string@dataEncoding-completer # The optional encoding of the score data. This property must match the encoding used for the `data` property.
  --filename: string # If this is an imported file, its filename
  --googleDriveFolder: string # If the user uses Google Drive and this properties is specified, the file will be created in this directory. The currently user creating the file must be granted to write in this directory.
  privacy: string@privacy-completer-1 # The score main privacy mode.  - `public`: The score is public on the Internet. This one can be accessible at the url `https://flat.io/score/{score}` and can be modified and administred by specified collaborators users. - `private`: The score is private and can be only accessed, modified and administred by specified collaborators users. - `privateLink`: The score is private but can be accessed using a private link `htmlUrl` or the private key in the property `sharingKey`. - `organizationPublic`: _Available only with [Flat for Education](https://flat.io/edu)._ The score is public in the organization: users of the same organization can access to this one. The score can be modified and administred by specified collaborators users.  The score can also be individually shared to a set of users or groups using the different collaborators API methods.  When a file is synchronized from an external source (e.g. Google Drive) and the sharing options are changed on the source, Flat will chose the best privacy mode for the file.  When using a [Flat for Education](https://flat.io/edu) account, some of the modes may not be available if disabled by an administrator of the organization (e.g. by default the `public` mode is not available).
  --body-source: record # e.g. {googleDrive: 0B-0000000000000001} — shape: {googleDrive?: string}
  --title: string # The title of the new score. If the title is too long, the API may trim this one.  If this title is not specified, the API will try to (in this order):   - Use the title contained in the file (e.g. [`movement-title`](https://usermanuals.musicxml.com/MusicXML/Content/EL-MusicXML-movement-title.htm) or [`credit-words`](https://usermanuals.musicxml.com/MusicXML/Content/EL-MusicXML-credit-words.htm) for [MusicXML](http://www.musicxml.com/) files).   - Use the name of the file for files from a specified `source` (e.g. Google Drive) or the one in the `filename` property   - Set a default title (e.g. "New Music Score")
]: any -> record<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scores")
  let body = {collection: $collection, data: $data, dataEncoding: $dataEncoding, filename: $filename, googleDriveFolder: $googleDriveFolder, privacy: $privacy, source: $body_source, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a score
#
# DELETE /scores/{score}
# operationId: deleteScore
export def "scores delete" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --now: oneof<nothing, bool> # If `true`, the score deletion will be scheduled to be done ASAP (default: false)
]: nothing -> record<code: string, id: string, message: string, param: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "now" $now "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scores/($score)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a score's metadata
#
# GET /scores/{score}
# operationId: getScore
export def "scores get" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharingKey: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> record<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sharingKey" $sharingKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scores/($score)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a score's metadata
#
# PUT /scores/{score}
# operationId: editScore
export def "scores editScore" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --arranger: string # The arranger of the score
  --composer: string # The composer of the score
  --creationType: string@creationType-completer # The type of creation (an orginal, an arrangement)
  --description: string # Description of the creation
  --license: string@license-completer # License of the creation. Read more about the Creative Commons licenses on https://creativecommons.org/licenses/
  --licenseText: string # The rights info written on the score
  --lyricist: string # The lyricist of the score
  --privacy: string@privacy-completer-1 # The score main privacy mode.  - `public`: The score is public on the Internet. This one can be accessible at the url `https://flat.io/score/{score}` and can be modified and administred by specified collaborators users. - `private`: The score is private and can be only accessed, modified and administred by specified collaborators users. - `privateLink`: The score is private but can be accessed using a private link `htmlUrl` or the private key in the property `sharingKey`. - `organizationPublic`: _Available only with [Flat for Education](https://flat.io/edu)._ The score is public in the organization: users of the same organization can access to this one. The score can be modified and administred by specified collaborators users.  The score can also be individually shared to a set of users or groups using the different collaborators API methods.  When a file is synchronized from an external source (e.g. Google Drive) and the sharing options are changed on the source, Flat will chose the best privacy mode for the file.  When using a [Flat for Education](https://flat.io/edu) account, some of the modes may not be available if disabled by an administrator of the organization (e.g. by default the `public` mode is not available).
  --sharingKey: string # When using the `privacy` mode `privateLink`, this property can be used to set a custom sharing key, otherwise a new key will be generated.
  --subtitle: string # The subtitle of the score
  --tags: list # Tags describing the score
  --title: string # The title of the score
]: any -> record<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scores/($score)")
  let body = {arranger: $arranger, composer: $composer, creationType: $creationType, description: $description, license: $license, licenseText: $licenseText, lyricist: $lyricist, privacy: $privacy, sharingKey: $sharingKey, subtitle: $subtitle, tags: $tags, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the collaborators
#
# GET /scores/{score}/collaborators
# operationId: getScoreCollaborators
export def "scores-collaborators list" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharingKey: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, id: string, invited: bool, score: string, user: record<bio: string, coverPicture: string, followersCount: int, followingCount: int, instruments: list, likedScoresCount: int, ownedPublicScoresCount: int, profileTheme: string, registrationDate: string>, userEmail: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sharingKey" $sharingKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scores/($score)/collaborators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new collaborator
#
# POST /scores/{score}/collaborators
# operationId: addScoreCollaborator
export def "scores-collaborators addScoreCollaborator" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --aclAdmin: oneof<nothing, bool> # `True` if the related user can can manage the current document, i.e. changing the document permissions and deleting the document  (default: false)
  --aclRead: oneof<nothing, bool> # `True` if the related user can read the score. (probably true if the user has a permission on the document).  (default: true)
  --aclWrite: oneof<nothing, bool> # `True` if the related user can modify the score.  (default: false)
  --group: string # The unique identifier of a Flat group
  --user: string # The unique identifier of a Flat user
  --userEmail: string # Fill this field to invite an individual user by email.
  --userToken: string # Token received in an invitation to join the score.
]: any -> record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, id: string, invited: bool, score: string, user: record<bio: string, coverPicture: string, followersCount: int, followingCount: int, instruments: list<string>, likedScoresCount: int, ownedPublicScoresCount: int, profileTheme: string, registrationDate: string>, userEmail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scores/($score)/collaborators")
  let body = {aclAdmin: $aclAdmin, aclRead: $aclRead, aclWrite: $aclWrite, group: $group, user: $user, userEmail: $userEmail, userToken: $userToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a collaborator
#
# DELETE /scores/{score}/collaborators/{collaborator}
# operationId: removeScoreCollaborator
export def "scores-collaborators removeScoreCollaborator" [
  score: string
  collaborator: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, id: string, message: string, param: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scores/($score)/collaborators/($collaborator)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a collaborator
#
# GET /scores/{score}/collaborators/{collaborator}
# operationId: getScoreCollaborator
export def "scores-collaborators get" [
  score: string
  collaborator: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharingKey: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, id: string, invited: bool, score: string, user: record<bio: string, coverPicture: string, followersCount: int, followingCount: int, instruments: list<string>, likedScoresCount: int, ownedPublicScoresCount: int, profileTheme: string, registrationDate: string>, userEmail: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sharingKey" $sharingKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scores/($score)/collaborators/($collaborator)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List comments
#
# GET /scores/{score}/comments
# operationId: getScoreComments
export def "scores-comments get" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharingKey: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
  --type: string@type-completer-1 # Filter the comments by type
  --qp-sort: string@sort-completer-2 # Sort
  --direction: string@direction-completer # Sort direction
]: nothing -> table<comment: string, context: record<measureUuids: list, partUuid: string, staffIdx: float, staffUuid: string, startDpq: float, startTimePos: float, stopDpq: float, stopTimePos: float>, date: string, id: string, mentions: list<string>, modificationDate: string, rawComment: string, replyTo: string, resolved: bool, resolvedBy: string, revision: string, score: string, spam: bool, type: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sharingKey" $sharingKey "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scores/($score)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post a new comment
#
# POST /scores/{score}/comments
# operationId: postScoreComment
# --context shape: {measureUuids: list, partUuid: string, staffIdx?: float, staffUuid?: string, startDpq: float, startTimePos: float, stopDpq: float, stopTimePos: float}
export def "scores-comments post" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharingKey: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
  comment: string # The comment text that can includes mentions using the following format: `@[id:username]`.
  --context: record # The context of the comment (for inline/contextualized comments). A context will include all the information related to the location of the comment (i.e. score parts, range of measure, time position).  (e.g. {measureUuids: [e6a6a60b-8710-f819-9a49-e907b19c6f1f, da83d93c-e3a6-3c73-1bbe-15e5131d6437, 056ec5eb-9213-df56-6ae8-d9b99673dc48], partUuid: 91982db7-2e6d-285e-7a19-76b4bd005b8b, staffUuid: 9395d8f3-f42b-47b6-8c5d-6ba704961ec0, startDpq: 1, startTimePos: 2, stopDpq: 1, stopTimePos: 3}) — shape: {measureUuids: list, partUuid: string, staffIdx?: float, staffUuid?: string, startDpq: float, startTimePos: float, stopDpq: float, stopTimePos: float}
  --mentions: list # The list of user identifiers mentioned in this comment
  --rawComment: string # A raw version of the comment, that can be displayed without the mentions. If you use mentions, this property must be set.
  --replyTo: string # When the comment is a reply to another comment, the unique identifier of the parent comment
  --revision: string # The unique indentifier of the revision of the score where the comment was added. If this property is unspecified or contains "last", the API will automatically take the last revision created.
]: any -> record<comment: string, context: record<measureUuids: list<string>, partUuid: string, staffIdx: float, staffUuid: string, startDpq: float, startTimePos: float, stopDpq: float, stopTimePos: float>, date: string, id: string, mentions: list<string>, modificationDate: string, rawComment: string, replyTo: string, resolved: bool, resolvedBy: string, revision: string, score: string, spam: bool, type: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sharingKey" $sharingKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scores/($score)/comments" $qp)
  let body = {comment: $comment, context: $context, mentions: $mentions, rawComment: $rawComment, replyTo: $replyTo, revision: $revision} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a comment
#
# DELETE /scores/{score}/comments/{comment}
# operationId: deleteScoreComment
export def "scores-comments delete" [
  score: string
  comment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharingKey: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> record<code: string, id: string, message: string, param: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sharingKey" $sharingKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scores/($score)/comments/($comment)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing comment
#
# PUT /scores/{score}/comments/{comment}
# operationId: updateScoreComment
# --context shape: {measureUuids: list, partUuid: string, staffIdx?: float, staffUuid?: string, startDpq: float, startTimePos: float, stopDpq: float, stopTimePos: float}
export def "scores-comments updateScoreComment" [
  score: string
  comment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharingKey: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
  --body-comment: string # The comment text that can includes mentions using the following format: `@[id:username]`.
  --context: record # The context of the comment (for inline/contextualized comments). A context will include all the information related to the location of the comment (i.e. score parts, range of measure, time position).  (e.g. {measureUuids: [e6a6a60b-8710-f819-9a49-e907b19c6f1f, da83d93c-e3a6-3c73-1bbe-15e5131d6437, 056ec5eb-9213-df56-6ae8-d9b99673dc48], partUuid: 91982db7-2e6d-285e-7a19-76b4bd005b8b, staffUuid: 9395d8f3-f42b-47b6-8c5d-6ba704961ec0, startDpq: 1, startTimePos: 2, stopDpq: 1, stopTimePos: 3}) — shape: {measureUuids: list, partUuid: string, staffIdx?: float, staffUuid?: string, startDpq: float, startTimePos: float, stopDpq: float, stopTimePos: float}
  --rawComment: string # A raw version of the comment, that can be displayed without the mentions. If you use mentions, this property must be set.
  --revision: string # The unique indentifier of the revision of the score where the comment was added. If this property is unspecified or contains "last", the API will automatically take the last revision created.
]: any -> record<comment: string, context: record<measureUuids: list<string>, partUuid: string, staffIdx: float, staffUuid: string, startDpq: float, startTimePos: float, stopDpq: float, stopTimePos: float>, date: string, id: string, mentions: list<string>, modificationDate: string, rawComment: string, replyTo: string, resolved: bool, resolvedBy: string, revision: string, score: string, spam: bool, type: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sharingKey" $sharingKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scores/($score)/comments/($comment)" $qp)
  let body = {comment: $body_comment, context: $context, rawComment: $rawComment, revision: $revision} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Mark the comment as unresolved
#
# DELETE /scores/{score}/comments/{comment}/resolved
# operationId: markScoreCommentUnresolved
export def "scores-comments-resolved markScoreCommentUnresolved" [
  score: string
  comment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharingKey: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> record<code: string, id: string, message: string, param: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sharingKey" $sharingKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scores/($score)/comments/($comment)/resolved" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Mark the comment as resolved
#
# PUT /scores/{score}/comments/{comment}/resolved
# operationId: markScoreCommentResolved
export def "scores-comments-resolved markScoreCommentResolved" [
  score: string
  comment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharingKey: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> record<code: string, id: string, message: string, param: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sharingKey" $sharingKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scores/($score)/comments/($comment)/resolved" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fork a score
#
# POST /scores/{score}/fork
# operationId: forkScore
export def "scores-fork forkScore" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharingKey: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
  --collection: string # Unique identifier of a collection where the score will be copied. If no collection identifier is provided, the score will be stored in the `root` directory.  (default: root)
]: any -> record<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sharingKey" $sharingKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scores/($score)/fork" $qp)
  let body = {collection: $collection} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the revisions
#
# GET /scores/{score}/revisions
# operationId: getScoreRevisions
export def "scores-revisions get-by-score" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharingKey: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> table<autosave: bool, collaborators: list<string>, creationDate: string, description: string, event: string, id: string, statistics: record<additions: float, deletions: float>, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sharingKey" $sharingKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scores/($score)/revisions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new revision
#
# POST /scores/{score}/revisions
# operationId: createScoreRevision
export def "scores-revisions createScoreRevision" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --autosave: oneof<nothing, bool> # Must be set to `true` if the revision was created automatically.
  data: string # The data of the score file. It must be a MusicXML 3 file (`vnd.recordare.musicxml` or `vnd.recordare.musicxml+xml`), a MIDI file (`audio/midi`) or a Flat.json (aka Adagio.json) file. Binary payloads (`vnd.recordare.musicxml` and `audio/midi`) can be encoded in Base64, in this case the `dataEncoding` property must match the encoding used for the API request.  (e.g. <score-partwise version="3.0"></score-partwise>)
  --dataEncoding: string@dataEncoding-completer # The optional encoding of the score data. This property must match the encoding used for the `data` property.
  --description: string # A description associated to the revision
]: any -> record<autosave: bool, collaborators: list<string>, creationDate: string, description: string, event: string, id: string, statistics: record<additions: float, deletions: float>, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scores/($score)/revisions")
  let body = {autosave: $autosave, data: $data, dataEncoding: $dataEncoding, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a score revision
#
# GET /scores/{score}/revisions/{revision}
# operationId: getScoreRevision
export def "scores-revisions get-by-score-revision" [
  score: string
  revision: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharingKey: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> record<autosave: bool, collaborators: list<string>, creationDate: string, description: string, event: string, id: string, statistics: record<additions: float, deletions: float>, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sharingKey" $sharingKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scores/($score)/revisions/($revision)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a score revision data
#
# GET /scores/{score}/revisions/{revision}/{format}
# operationId: getScoreRevisionData
export def "scores-revisions get-by-score-revision-format" [
  score: string
  revision: string
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --sharingKey: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
  --parts: string # An optional a set of parts uuid to be exported. This parameter must be composed of parts uuids separated by commas. For example "59df645f-bb1c-f1b4-b573-d2afc4491f94,34ef645f-1aef-f3bc-1564-34cca4492b87".
  --onlyCached: oneof<nothing, bool> # Only return files already generated and cached in Flat's production cache. If the file is not availabe, a 404 will be returned
  --qp-url: oneof<nothing, bool> # Returns a json with the `url` in it instead of redirecting
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sharingKey" $sharingKey "scalar") (serialize-qp "parts" $parts "scalar") (serialize-qp "onlyCached" $onlyCached "scalar") (serialize-qp "url" $qp_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scores/($score)/revisions/($revision)/($format)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List submissions related to the score
#
# GET /scores/{score}/submissions
# operationId: getScoreSubmissions
export def "scores-submissions get" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<assignment: string, attachments: list<record>, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record<alternateLink: string, id: string, state: string>, grade: float, id: string, maxPoints: float, microsoftGraph: record<alternateLink: string, id: string, state: string>, returnCreator: string, returnDate: string, state: string, submissionDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scores/($score)/submissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the audio or video tracks linked to a score
#
# GET /scores/{score}/tracks
# operationId: listScoreTracks
export def "scores-tracks listScoreTracks" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharingKey: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
  --assignment: string # An assignment id with which all the tracks returned will be related to
  --listAutoTrack: oneof<nothing, bool> # If true, and if available, return last automatically synchronized Flat's mp3 export as an additional track
]: nothing -> table<creationDate: string, creator: string, default: bool, id: string, mediaId: string, modificationDate: string, score: string, state: string, synchronizationPoints: list<record>, title: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sharingKey" $sharingKey "scalar") (serialize-qp "assignment" $assignment "scalar") (serialize-qp "listAutoTrack" $listAutoTrack "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scores/($score)/tracks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new video or audio track to the score
#
# POST /scores/{score}/tracks
# operationId: addScoreTrack
# --synchronizationPoints item shape: {measureUuid?: string, time: float, type: "measure"|"end"}
export def "scores-tracks addScoreTrack" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default: oneof<nothing, bool> # True if the track should be used as default audio source
  --state: string@state-completer-2 # State of the track (default: draft)
  --synchronizationPoints: list # item shape: {measureUuid?: string, time: float, type: "measure"|"end"}
  --title: string # Title of the track
  --body-url: string # The URL of the track
]: any -> record<creationDate: string, creator: string, default: bool, id: string, mediaId: string, modificationDate: string, score: string, state: string, synchronizationPoints: table<measureUuid: string, time: float, type: string>, title: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scores/($score)/tracks")
  let body = {default: $default, state: $state, synchronizationPoints: $synchronizationPoints, title: $title, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an audio or video track linked to the score
#
# DELETE /scores/{score}/tracks/{track}
# operationId: deleteScoreTrack
export def "scores-tracks delete" [
  score: string
  track: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, id: string, message: string, param: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scores/($score)/tracks/($track)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the details of an audio or video track linked to a score
#
# GET /scores/{score}/tracks/{track}
# operationId: getScoreTrack
export def "scores-tracks get" [
  score: string
  track: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharingKey: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> record<creationDate: string, creator: string, default: bool, id: string, mediaId: string, modificationDate: string, score: string, state: string, synchronizationPoints: table<measureUuid: string, time: float, type: string>, title: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sharingKey" $sharingKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scores/($score)/tracks/($track)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an audio or video track linked to a score
#
# PUT /scores/{score}/tracks/{track}
# operationId: updateScoreTrack
# --synchronizationPoints item shape: {measureUuid?: string, time: float, type: "measure"|"end"}
export def "scores-tracks updateScoreTrack" [
  score: string
  track: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default: oneof<nothing, bool> # True if the track should be used as default audio source
  --state: string@state-completer-2 # State of the track (default: draft)
  --synchronizationPoints: list # item shape: {measureUuid?: string, time: float, type: "measure"|"end"}
  --title: string # Title of the track
]: any -> record<creationDate: string, creator: string, default: bool, id: string, mediaId: string, modificationDate: string, score: string, state: string, synchronizationPoints: table<measureUuid: string, time: float, type: string>, title: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scores/($score)/tracks/($track)")
  let body = {default: $default, state: $state, synchronizationPoints: $synchronizationPoints, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Untrash a score
#
# POST /scores/{score}/untrash
# operationId: untrashScore
export def "scores-untrash untrashScore" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, id: string, message: string, param: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scores/($score)/untrash")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a public user profile
#
# GET /users/{user}
# operationId: getUser
export def "users get" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bio: string, coverPicture: string, followersCount: int, followingCount: int, instruments: list<string>, likedScoresCount: int, ownedPublicScoresCount: int, profileTheme: string, registrationDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List liked scores
#
# GET /users/{user}/likes
# operationId: gerUserLikes
export def "users-likes gerUserLikes" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: oneof<nothing, bool> # Return only the identifiers of the scores
]: nothing -> table<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: list<record>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user)/likes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List user's scores
#
# GET /users/{user}/scores
# operationId: getUserScores
export def "users-scores get" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --parent: string # Filter the score forked from the score id `parent`
]: nothing -> table<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: list<record>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent" $parent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user)/scores" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
