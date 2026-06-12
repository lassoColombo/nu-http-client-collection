# Auto-generated client for Redmine API v1.7.1+redmine.6.1
# Source: https://raw.githubusercontent.com/d-yoshi/redmine-openapi/main/openapi.yaml
# Auth: --token flag or $env.REDMINE_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o REDMINE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "x-redmine-api-key" => { {headers: {X-Redmine-API-Key: $token_val}, query: ""} }
    "query-key" => { {headers: {}, query: $"key=($token_val)"} }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["basic" "x-redmine-api-key" "query-key" "bearer"] }

# Completers for enum parameters
def nometa-completer [] { ["1"] }
def X-Redmine-Nometa-completer [] { ["1"] }
def builtin-completer [] { ["1"] }
def scope-completer [] { ["all" "bookmarks" "my_projects" "subprojects"] }
def issues-completer [] { ["1"] }
def news-completer [] { ["1"] }
def wiki-pages-completer [] { ["1"] }
def projects-completer [] { ["1"] }
def documents-completer [] { ["1"] }
def changesets-completer [] { ["1"] }
def messages-completer [] { ["1"] }
def attachments-completer [] { ["0" "1" "only"] }
def scope-completer-1 [] { ["subprojects"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "issues-format get" } } | get name | first)
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

# List issues
#
# GET /issues.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Issues#Listing-issues
# operationId: getIssues
export def "issues-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int
  --limit: int
  --nometa: int@nometa-completer
  --qp-sort: string # Sort order. Comma-separated list of `field` or `field:desc`. Default direction is ascending. Examples: `id:desc`, `status:desc,id` (e.g. id:desc)
  --include: list # Comma-separated list of associated data to include for each issue. Values: `attachments` (file attachments), `relations` (issue relations)
  --issue-id: string # Filter by issue ID. Format: `[operator]value` Operators: `=` (default), `>=`, `<=`, `><` (between, pipe-separated), `*` (any), `!*` (none) Examples: `1`, `>=100`, `><1|100`
  --project-id: string # Filter by project. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Special values: `mine` (projects where current user is a member), `bookmarks` (bookmarked projects) Examples: `1|2`, `mine`, `!mine`
  --subproject-id: string # Filter by subproject. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Examples: `1|2`, `*`, `!*`
  --tracker-id: string # Filter by tracker. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `ev` (has ever been), `!ev` (has never been), `cf` (changed from) Examples: `1|2`, `!3`
  --status-id: string # Filter by issue status. Format: `[operator]value[|value2|...]` Operators: `o` (open), `=` (default), `!` (not equal), `c` (closed), `*` (any), `ev` (has ever been), `!ev` (has never been), `cf` (changed from) Examples: `o`, `1|2`, `c`, `!3`
  --priority-id: string # Filter by priority. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `ev` (has ever been), `!ev` (has never been), `cf` (changed from) Examples: `1|2`, `!3`
  --assigned-to-id: string # Filter by assignee. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none), `ev` (has ever been), `!ev` (has never been), `cf` (changed from) Special values: `me` (current user) Examples: `1`, `me`, `!*`, `!me`
  --author-id: string # Filter by author. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Special values: `me` (current user) Examples: `1`, `me`, `!me`
  --authorgroup: string # Filter by author's group. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Examples: `1|2`
  --authorrole: string # Filter by author's role. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Examples: `1|2`
  --member-of-group: string # Filter by assignee's group membership. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Examples: `1`, `*`
  --assigned-to-role: string # Filter by assignee's role. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Examples: `1`, `*`
  --fixed-version-id: string # Filter by target version. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none), `ev` (has ever been), `!ev` (has never been), `cf` (changed from) Examples: `1|2`, `!*`
  --fixed-versiondue-date: string # Filter by target version's due date. Format: `<operator>[value]` Operators: `=` (on date), `>=` (on or after), `<=` (on or before), `><` (between, pipe-separated), `t` (today), `ld` (yesterday), `nd` (tomorrow), `w` (this week), `lw` (last week), `l2w` (last 2 weeks), `nw` (next week), `m` (this month), `lm` (last month), `nm` (next month), `y` (this year), `t-` (n days ago), `>t-` (less than n days ago), `<t-` (more than n days ago), `><t-` (between n1 and n2 days ago), `t+` (in n days), `>t+` (in more than n days), `<t+` (in less than n days), `><t+` (between n1 and n2 days from now), `*` (any), `!*` (none) Examples: `>=2024-01-01`, `t`, `>t-7`
  --fixed-versionstatus: string # Filter by target version's status. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Values: `open`, `locked`, `closed` Examples: `open`, `open|locked`, `!closed`
  --category-id: string # Filter by category. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none), `ev` (has ever been), `!ev` (has never been), `cf` (changed from) Examples: `1|2`, `!*`
  --parent-id: string # Filter by parent issue. Format: `[operator]value` Operators: `=` (exact parent ID), `~` (descendant of, subtree search), `*` (any, i.e. is a subtask), `!*` (none, i.e. is a root issue) Examples: `123`, `~123`, `*`, `!*`
  --child-id: string # Filter by child issue. Format: `[operator]value` Operators: `=` (exact child ID), `~` (ancestor of, subtree search), `*` (any, i.e. has subtasks), `!*` (none, i.e. is a leaf issue) Examples: `123`, `~123`, `*`, `!*`
  --cf-x: record # Filter by custom field value. Replace `x` with the custom field ID (e.g., `cf_1`, `cf_12`). Format and operators depend on the custom field type (string, int, date, list, etc.) and follow the same conventions as other filter parameters. Examples: `cf_1=~keyword`, `cf_5=1|2`, `cf_10=>=2024-01-01` (e.g. {cf_0: string})
  --subject: string # Filter by subject. Format: `<operator>value` Operators: `~` (contains), `!~` (not contains), `*~` (contains any word), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~keyword`, `^prefix`
  --description: string # Filter by description. Format: `<operator>value` Operators: `~` (contains), `!~` (not contains), `*~` (contains any word), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~keyword`, `!~excluded`
  --notes: string # Filter by journal notes. Format: `<operator>value` Operators: `~` (contains), `!~` (not contains), `*~` (contains any word), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~keyword`
  --created-on: string # Filter by creation date. Format: `<operator>[value]` Operators: `=` (on date), `>=` (on or after), `<=` (on or before), `><` (between, pipe-separated), `t` (today), `ld` (yesterday), `w` (this week), `lw` (last week), `l2w` (last 2 weeks), `m` (this month), `lm` (last month), `y` (this year), `t-` (n days ago), `>t-` (less than n days ago), `<t-` (more than n days ago), `><t-` (between n1 and n2 days ago), `*` (any), `!*` (none) Examples: `>=2024-01-01`, `t`, `>t-7`, `lm`
  --updated-on: string # Filter by last updated date. Format: `<operator>[value]` Operators: `=` (on date), `>=` (on or after), `<=` (on or before), `><` (between, pipe-separated), `t` (today), `ld` (yesterday), `w` (this week), `lw` (last week), `l2w` (last 2 weeks), `m` (this month), `lm` (last month), `y` (this year), `t-` (n days ago), `>t-` (less than n days ago), `<t-` (more than n days ago), `><t-` (between n1 and n2 days ago), `*` (any), `!*` (none) Examples: `>=2024-01-01`, `t`, `>t-7`, `lm`
  --closed-on: string # Filter by closed date. Format: `<operator>[value]` Operators: `=` (on date), `>=` (on or after), `<=` (on or before), `><` (between, pipe-separated), `t` (today), `ld` (yesterday), `w` (this week), `lw` (last week), `l2w` (last 2 weeks), `m` (this month), `lm` (last month), `y` (this year), `t-` (n days ago), `>t-` (less than n days ago), `<t-` (more than n days ago), `><t-` (between n1 and n2 days ago), `*` (any), `!*` (none) Examples: `>=2024-01-01`, `t`, `>t-7`, `lm`
  --start-date: string # Filter by start date. Format: `<operator>[value]` Operators: `=` (on date), `>=` (on or after), `<=` (on or before), `><` (between, pipe-separated), `t` (today), `ld` (yesterday), `nd` (tomorrow), `w` (this week), `lw` (last week), `l2w` (last 2 weeks), `nw` (next week), `m` (this month), `lm` (last month), `nm` (next month), `y` (this year), `t-` (n days ago), `>t-` (less than n days ago), `<t-` (more than n days ago), `><t-` (between n1 and n2 days ago), `t+` (in n days), `>t+` (in more than n days), `<t+` (in less than n days), `><t+` (between n1 and n2 days from now), `*` (any), `!*` (none) Examples: `>=2024-01-01`, `t`, `>t-7`
  --due-date: string # Filter by due date. Format: `<operator>[value]` Operators: `=` (on date), `>=` (on or after), `<=` (on or before), `><` (between, pipe-separated), `t` (today), `ld` (yesterday), `nd` (tomorrow), `w` (this week), `lw` (last week), `l2w` (last 2 weeks), `nw` (next week), `m` (this month), `lm` (last month), `nm` (next month), `y` (this year), `t-` (n days ago), `>t-` (less than n days ago), `<t-` (more than n days ago), `><t-` (between n1 and n2 days ago), `t+` (in n days), `>t+` (in more than n days), `<t+` (in less than n days), `><t+` (between n1 and n2 days from now), `*` (any), `!*` (none) Examples: `>=2024-01-01`, `t`, `>t-7`
  --estimated-hours: string # Filter by estimated hours. Format: `[operator]value` Operators: `=` (default), `>=`, `<=`, `><` (between, pipe-separated), `*` (any), `!*` (none) Examples: `>=5`, `><1|10`, `!*`
  --spent-time: string # Filter by total spent time. Format: `[operator]value` Operators: `=` (default), `>=`, `<=`, `><` (between, pipe-separated), `*` (any), `!*` (none) Examples: `>=5`, `><1|10`, `!*`
  --done-ratio: string # Filter by done ratio (percentage). Format: `[operator]value` Operators: `=` (default), `>=`, `<=`, `><` (between, pipe-separated), `*` (any), `!*` (none) Examples: `>=50`, `><0|99`, `100`
  --is-private: string # Filter by private flag. Format: `[operator]value` Operators: `=` (default), `!` (not equal) Values: `1` (private), `0` (not private) Examples: `1`, `0`
  --attachment: string # Filter by attachment filename. Format: `<operator>value` Operators: `~` (contains), `!~` (not contains), `*~` (contains any word), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~report`, `*.pdf`
  --attachment-description: string # Filter by attachment description. Format: `<operator>value` Operators: `~` (contains), `!~` (not contains), `*~` (contains any word), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~screenshot`
  --watcher-id: string # Filter by watcher. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Special values: `me` (current user) Examples: `1`, `me`, `!me`
  --updated-by: string # Filter by user who updated the issue. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Special values: `me` (current user) Examples: `1`, `me`
  --last-updated-by: string # Filter by user who last updated the issue. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Special values: `me` (current user) Examples: `1`, `me`
  --projectstatus: string # Filter by project status. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Values: `1` (active), `5` (closed) Examples: `1`, `!5`
  --relates: string # Filter by "relates to" relation. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `=p` (same project), `=!p` (different project), `!p` (not in project), `*o` (related to open issue), `!o` (related to closed issue), `*` (any), `!*` (none) Examples: `123`, `=p`, `*o`, `*`
  --duplicates: string # Filter by "duplicates" relation. Format: `[operator]value[|value2|...]` Operators: `=`, `!`, `=p`, `=!p`, `!p`, `*o`, `!o`, `*`, `!*` Examples: `123`, `*`
  --duplicated: string # Filter by "duplicated by" relation. Format: `[operator]value[|value2|...]` Operators: `=`, `!`, `=p`, `=!p`, `!p`, `*o`, `!o`, `*`, `!*` Examples: `123`, `*`
  --blocks: string # Filter by "blocks" relation. Format: `[operator]value[|value2|...]` Operators: `=`, `!`, `=p`, `=!p`, `!p`, `*o`, `!o`, `*`, `!*` Examples: `123`, `*o`
  --blocked: string # Filter by "blocked by" relation. Format: `[operator]value[|value2|...]` Operators: `=`, `!`, `=p`, `=!p`, `!p`, `*o`, `!o`, `*`, `!*` Examples: `123`, `*o`
  --precedes: string # Filter by "precedes" relation. Format: `[operator]value[|value2|...]` Operators: `=`, `!`, `=p`, `=!p`, `!p`, `*o`, `!o`, `*`, `!*` Examples: `123`, `*`
  --follows: string # Filter by "follows" relation. Format: `[operator]value[|value2|...]` Operators: `=`, `!`, `=p`, `=!p`, `!p`, `*o`, `!o`, `*`, `!*` Examples: `123`, `*`
  --copied-to: string # Filter by "copied to" relation. Format: `[operator]value[|value2|...]` Operators: `=`, `!`, `=p`, `=!p`, `!p`, `*o`, `!o`, `*`, `!*` Examples: `123`, `*`
  --copied-from: string # Filter by "copied from" relation. Format: `[operator]value[|value2|...]` Operators: `=`, `!`, `=p`, `=!p`, `!p`, `*o`, `!o`, `*`, `!*` Examples: `123`, `*`
  --any-searchable: string # Full-text search across all searchable fields. Format: `<operator>value` Operators: `~` (contains all words), `*~` (contains any word), `!~` (not contains) Examples: `~keyword`, `*~foo bar`
  --query-id: int # ID of a saved query to apply. When specified, the saved query's filter criteria are used. Other filter parameters in the same request are ignored. Use GET /queries.json to retrieve available saved queries.
  --X-Redmine-Switch-User: string # e.g. jsmith
  --X-Redmine-Nometa: int@X-Redmine-Nometa-completer
]: nothing -> record<issues: table<id: int, project: record, tracker: record, status: record, priority: record, author: record, assigned_to: record, category: record, fixed_version: record, parent: record, subject: string, description: string, start_date: string, due_date: string, done_ratio: int, is_private: bool, estimated_hours: float, total_estimated_hours: float, spent_hours: float, total_spent_hours: float, custom_fields: list, created_on: string, updated_on: string, closed_on: string, attachments: list, relations: list>, total_count: int, offset: int, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "nometa" $nometa "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include" $include "csv") (serialize-qp "issue_id" $issue_id "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "subproject_id" $subproject_id "scalar") (serialize-qp "tracker_id" $tracker_id "scalar") (serialize-qp "status_id" $status_id "scalar") (serialize-qp "priority_id" $priority_id "scalar") (serialize-qp "assigned_to_id" $assigned_to_id "scalar") (serialize-qp "author_id" $author_id "scalar") (serialize-qp "author.group" $authorgroup "scalar") (serialize-qp "author.role" $authorrole "scalar") (serialize-qp "member_of_group" $member_of_group "scalar") (serialize-qp "assigned_to_role" $assigned_to_role "scalar") (serialize-qp "fixed_version_id" $fixed_version_id "scalar") (serialize-qp "fixed_version.due_date" $fixed_versiondue_date "scalar") (serialize-qp "fixed_version.status" $fixed_versionstatus "scalar") (serialize-qp "category_id" $category_id "scalar") (serialize-qp "parent_id" $parent_id "scalar") (serialize-qp "child_id" $child_id "scalar") (serialize-qp "cf_x" $cf_x "multi") (serialize-qp "subject" $subject "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "notes" $notes "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "updated_on" $updated_on "scalar") (serialize-qp "closed_on" $closed_on "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "due_date" $due_date "scalar") (serialize-qp "estimated_hours" $estimated_hours "scalar") (serialize-qp "spent_time" $spent_time "scalar") (serialize-qp "done_ratio" $done_ratio "scalar") (serialize-qp "is_private" $is_private "scalar") (serialize-qp "attachment" $attachment "scalar") (serialize-qp "attachment_description" $attachment_description "scalar") (serialize-qp "watcher_id" $watcher_id "scalar") (serialize-qp "updated_by" $updated_by "scalar") (serialize-qp "last_updated_by" $last_updated_by "scalar") (serialize-qp "project.status" $projectstatus "scalar") (serialize-qp "relates" $relates "scalar") (serialize-qp "duplicates" $duplicates "scalar") (serialize-qp "duplicated" $duplicated "scalar") (serialize-qp "blocks" $blocks "scalar") (serialize-qp "blocked" $blocked "scalar") (serialize-qp "precedes" $precedes "scalar") (serialize-qp "follows" $follows "scalar") (serialize-qp "copied_to" $copied_to "scalar") (serialize-qp "copied_from" $copied_from "scalar") (serialize-qp "any_searchable" $any_searchable "scalar") (serialize-qp "query_id" $query_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/issues.($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User, "X-Redmine-Nometa": $X_Redmine_Nometa} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create issue
#
# POST /issues.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Issues#Creating-an-issue
# operationId: createIssue
# --issue shape: {project_id: any, tracker_id?: int, status_id?: int, priority_id?: int, subject: string, description?: string, start_date?: string, due_date?: string, done_ratio?: int, category_id?: int, fixed_version_id?: int, assigned_to_id?: int, parent_issue_id?: int, custom_fields?: list, custom_field_values?: record, watcher_user_ids?: list, is_private?: bool, estimated_hours?: float, uploads?: list}
export def "issues-format createIssue" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  issue: record # shape: {project_id: any, tracker_id?: int, status_id?: int, priority_id?: int, subject: string, description?: string, start_date?: string, due_date?: string, done_ratio?: int, category_id?: int, fixed_version_id?: int, assigned_to_id?: int, parent_issue_id?: int, custom_fields?: list, custom_field_values?: record, watcher_user_ids?: list, is_private?: bool, estimated_hours?: float, uploads?: list}
]: any -> record<issue: record<id: int, project: record<id: int, name: string>, tracker: record<id: int, name: string>, status: record<id: int, name: string, is_closed: bool>, priority: record<id: int, name: string>, author: record<id: int, name: string>, assigned_to: record<id: int, name: string>, category: record<id: int, name: string>, fixed_version: record<id: int, name: string>, parent: record<id: int>, subject: string, description: string, start_date: string, due_date: string, done_ratio: int, is_private: bool, estimated_hours: float, total_estimated_hours: float, spent_hours: float, total_spent_hours: float, custom_fields: list<record>, created_on: string, updated_on: string, closed_on: string, attachments: list<record>, relations: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/issues.($format)")
  let body = {issue: $issue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show issue
#
# GET /issues/{issue_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Issues#Showing-an-issue
# operationId: getIssue
export def "issues get" [
  format: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Comma-separated list of associated data to include in the response. Values: `children` (child issues), `attachments` (file attachments), `relations` (issue relations), `changesets` (associated VCS changesets), `journals` (change history and notes), `watchers` (users watching the issue), `allowed_statuses` (status transitions available for the current user)
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<issue: record<id: int, project: record<id: int, name: string>, tracker: record<id: int, name: string>, status: record<id: int, name: string, is_closed: bool>, priority: record<id: int, name: string>, author: record<id: int, name: string>, assigned_to: record<id: int, name: string>, category: record<id: int, name: string>, fixed_version: record<id: int, name: string>, parent: record<id: int>, subject: string, description: string, start_date: string, due_date: string, done_ratio: int, is_private: bool, estimated_hours: float, total_estimated_hours: float, spent_hours: float, total_spent_hours: float, custom_fields: list<record>, created_on: string, updated_on: string, closed_on: string, changesets: list<record>, children: list<record>, attachments: list<record>, relations: list<record>, journals: list<record>, watchers: list<record>, allowed_statuses: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/issues/($issue_id).($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update issue
#
# PUT /issues/{issue_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Issues#Updating-an-issue
# operationId: updateIssue
# --issue shape: {project_id?: any, tracker_id?: int, status_id?: int, priority_id?: int, subject?: string, description?: string, start_date?: string, due_date?: string, done_ratio?: int, category_id?: int, fixed_version_id?: int, assigned_to_id?: int, parent_issue_id?: int, custom_fields?: list, custom_field_values?: record, is_private?: bool, estimated_hours?: float, notes?: string, private_notes?: bool, deleted_attachment_ids?: list, uploads?: list}
export def "issues updateIssue" [
  format: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  --issue: record # shape: {project_id?: any, tracker_id?: int, status_id?: int, priority_id?: int, subject?: string, description?: string, start_date?: string, due_date?: string, done_ratio?: int, category_id?: int, fixed_version_id?: int, assigned_to_id?: int, parent_issue_id?: int, custom_fields?: list, custom_field_values?: record, is_private?: bool, estimated_hours?: float, notes?: string, private_notes?: bool, deleted_attachment_ids?: list, uploads?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/issues/($issue_id).($format)")
  let body = {issue: $issue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete issue
#
# DELETE /issues/{issue_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Issues#Deleting-an-issue
# operationId: deleteIssue
export def "issues delete" [
  format: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/issues/($issue_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List issues by project
#
# GET /projects/{project_id}/issues.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Issues#Listing-issues
# operationId: getIssuesByProject
export def "projects-issues-format get" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int
  --limit: int
  --nometa: int@nometa-completer
  --qp-sort: string # Sort order. Comma-separated list of `field` or `field:desc`. Default direction is ascending. Examples: `id:desc`, `status:desc,id` (e.g. id:desc)
  --include: list # Comma-separated list of associated data to include for each issue. Values: `attachments` (file attachments), `relations` (issue relations)
  --issue-id: string # Filter by issue ID. Format: `[operator]value` Operators: `=` (default), `>=`, `<=`, `><` (between, pipe-separated), `*` (any), `!*` (none) Examples: `1`, `>=100`, `><1|100`
  --subproject-id: string # Filter by subproject. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Examples: `1|2`, `*`, `!*`
  --tracker-id: string # Filter by tracker. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `ev` (has ever been), `!ev` (has never been), `cf` (changed from) Examples: `1|2`, `!3`
  --status-id: string # Filter by issue status. Format: `[operator]value[|value2|...]` Operators: `o` (open), `=` (default), `!` (not equal), `c` (closed), `*` (any), `ev` (has ever been), `!ev` (has never been), `cf` (changed from) Examples: `o`, `1|2`, `c`, `!3`
  --priority-id: string # Filter by priority. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `ev` (has ever been), `!ev` (has never been), `cf` (changed from) Examples: `1|2`, `!3`
  --assigned-to-id: string # Filter by assignee. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none), `ev` (has ever been), `!ev` (has never been), `cf` (changed from) Special values: `me` (current user) Examples: `1`, `me`, `!*`, `!me`
  --author-id: string # Filter by author. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Special values: `me` (current user) Examples: `1`, `me`, `!me`
  --authorgroup: string # Filter by author's group. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Examples: `1|2`
  --authorrole: string # Filter by author's role. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Examples: `1|2`
  --member-of-group: string # Filter by assignee's group membership. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Examples: `1`, `*`
  --assigned-to-role: string # Filter by assignee's role. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Examples: `1`, `*`
  --fixed-version-id: string # Filter by target version. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none), `ev` (has ever been), `!ev` (has never been), `cf` (changed from) Examples: `1|2`, `!*`
  --fixed-versiondue-date: string # Filter by target version's due date. Format: `<operator>[value]` Operators: `=` (on date), `>=` (on or after), `<=` (on or before), `><` (between, pipe-separated), `t` (today), `ld` (yesterday), `nd` (tomorrow), `w` (this week), `lw` (last week), `l2w` (last 2 weeks), `nw` (next week), `m` (this month), `lm` (last month), `nm` (next month), `y` (this year), `t-` (n days ago), `>t-` (less than n days ago), `<t-` (more than n days ago), `><t-` (between n1 and n2 days ago), `t+` (in n days), `>t+` (in more than n days), `<t+` (in less than n days), `><t+` (between n1 and n2 days from now), `*` (any), `!*` (none) Examples: `>=2024-01-01`, `t`, `>t-7`
  --fixed-versionstatus: string # Filter by target version's status. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Values: `open`, `locked`, `closed` Examples: `open`, `open|locked`, `!closed`
  --category-id: string # Filter by category. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none), `ev` (has ever been), `!ev` (has never been), `cf` (changed from) Examples: `1|2`, `!*`
  --parent-id: string # Filter by parent issue. Format: `[operator]value` Operators: `=` (exact parent ID), `~` (descendant of, subtree search), `*` (any, i.e. is a subtask), `!*` (none, i.e. is a root issue) Examples: `123`, `~123`, `*`, `!*`
  --child-id: string # Filter by child issue. Format: `[operator]value` Operators: `=` (exact child ID), `~` (ancestor of, subtree search), `*` (any, i.e. has subtasks), `!*` (none, i.e. is a leaf issue) Examples: `123`, `~123`, `*`, `!*`
  --cf-x: record # Filter by custom field value. Replace `x` with the custom field ID (e.g., `cf_1`, `cf_12`). Format and operators depend on the custom field type (string, int, date, list, etc.) and follow the same conventions as other filter parameters. Examples: `cf_1=~keyword`, `cf_5=1|2`, `cf_10=>=2024-01-01` (e.g. {cf_0: string})
  --subject: string # Filter by subject. Format: `<operator>value` Operators: `~` (contains), `!~` (not contains), `*~` (contains any word), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~keyword`, `^prefix`
  --description: string # Filter by description. Format: `<operator>value` Operators: `~` (contains), `!~` (not contains), `*~` (contains any word), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~keyword`, `!~excluded`
  --notes: string # Filter by journal notes. Format: `<operator>value` Operators: `~` (contains), `!~` (not contains), `*~` (contains any word), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~keyword`
  --created-on: string # Filter by creation date. Format: `<operator>[value]` Operators: `=` (on date), `>=` (on or after), `<=` (on or before), `><` (between, pipe-separated), `t` (today), `ld` (yesterday), `w` (this week), `lw` (last week), `l2w` (last 2 weeks), `m` (this month), `lm` (last month), `y` (this year), `t-` (n days ago), `>t-` (less than n days ago), `<t-` (more than n days ago), `><t-` (between n1 and n2 days ago), `*` (any), `!*` (none) Examples: `>=2024-01-01`, `t`, `>t-7`, `lm`
  --updated-on: string # Filter by last updated date. Format: `<operator>[value]` Operators: `=` (on date), `>=` (on or after), `<=` (on or before), `><` (between, pipe-separated), `t` (today), `ld` (yesterday), `w` (this week), `lw` (last week), `l2w` (last 2 weeks), `m` (this month), `lm` (last month), `y` (this year), `t-` (n days ago), `>t-` (less than n days ago), `<t-` (more than n days ago), `><t-` (between n1 and n2 days ago), `*` (any), `!*` (none) Examples: `>=2024-01-01`, `t`, `>t-7`, `lm`
  --closed-on: string # Filter by closed date. Format: `<operator>[value]` Operators: `=` (on date), `>=` (on or after), `<=` (on or before), `><` (between, pipe-separated), `t` (today), `ld` (yesterday), `w` (this week), `lw` (last week), `l2w` (last 2 weeks), `m` (this month), `lm` (last month), `y` (this year), `t-` (n days ago), `>t-` (less than n days ago), `<t-` (more than n days ago), `><t-` (between n1 and n2 days ago), `*` (any), `!*` (none) Examples: `>=2024-01-01`, `t`, `>t-7`, `lm`
  --start-date: string # Filter by start date. Format: `<operator>[value]` Operators: `=` (on date), `>=` (on or after), `<=` (on or before), `><` (between, pipe-separated), `t` (today), `ld` (yesterday), `nd` (tomorrow), `w` (this week), `lw` (last week), `l2w` (last 2 weeks), `nw` (next week), `m` (this month), `lm` (last month), `nm` (next month), `y` (this year), `t-` (n days ago), `>t-` (less than n days ago), `<t-` (more than n days ago), `><t-` (between n1 and n2 days ago), `t+` (in n days), `>t+` (in more than n days), `<t+` (in less than n days), `><t+` (between n1 and n2 days from now), `*` (any), `!*` (none) Examples: `>=2024-01-01`, `t`, `>t-7`
  --due-date: string # Filter by due date. Format: `<operator>[value]` Operators: `=` (on date), `>=` (on or after), `<=` (on or before), `><` (between, pipe-separated), `t` (today), `ld` (yesterday), `nd` (tomorrow), `w` (this week), `lw` (last week), `l2w` (last 2 weeks), `nw` (next week), `m` (this month), `lm` (last month), `nm` (next month), `y` (this year), `t-` (n days ago), `>t-` (less than n days ago), `<t-` (more than n days ago), `><t-` (between n1 and n2 days ago), `t+` (in n days), `>t+` (in more than n days), `<t+` (in less than n days), `><t+` (between n1 and n2 days from now), `*` (any), `!*` (none) Examples: `>=2024-01-01`, `t`, `>t-7`
  --estimated-hours: string # Filter by estimated hours. Format: `[operator]value` Operators: `=` (default), `>=`, `<=`, `><` (between, pipe-separated), `*` (any), `!*` (none) Examples: `>=5`, `><1|10`, `!*`
  --spent-time: string # Filter by total spent time. Format: `[operator]value` Operators: `=` (default), `>=`, `<=`, `><` (between, pipe-separated), `*` (any), `!*` (none) Examples: `>=5`, `><1|10`, `!*`
  --done-ratio: string # Filter by done ratio (percentage). Format: `[operator]value` Operators: `=` (default), `>=`, `<=`, `><` (between, pipe-separated), `*` (any), `!*` (none) Examples: `>=50`, `><0|99`, `100`
  --is-private: string # Filter by private flag. Format: `[operator]value` Operators: `=` (default), `!` (not equal) Values: `1` (private), `0` (not private) Examples: `1`, `0`
  --attachment: string # Filter by attachment filename. Format: `<operator>value` Operators: `~` (contains), `!~` (not contains), `*~` (contains any word), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~report`, `*.pdf`
  --attachment-description: string # Filter by attachment description. Format: `<operator>value` Operators: `~` (contains), `!~` (not contains), `*~` (contains any word), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~screenshot`
  --watcher-id: string # Filter by watcher. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Special values: `me` (current user) Examples: `1`, `me`, `!me`
  --updated-by: string # Filter by user who updated the issue. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Special values: `me` (current user) Examples: `1`, `me`
  --last-updated-by: string # Filter by user who last updated the issue. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Special values: `me` (current user) Examples: `1`, `me`
  --projectstatus: string # Filter by project status. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Values: `1` (active), `5` (closed) Examples: `1`, `!5`
  --relates: string # Filter by "relates to" relation. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `=p` (same project), `=!p` (different project), `!p` (not in project), `*o` (related to open issue), `!o` (related to closed issue), `*` (any), `!*` (none) Examples: `123`, `=p`, `*o`, `*`
  --duplicates: string # Filter by "duplicates" relation. Format: `[operator]value[|value2|...]` Operators: `=`, `!`, `=p`, `=!p`, `!p`, `*o`, `!o`, `*`, `!*` Examples: `123`, `*`
  --duplicated: string # Filter by "duplicated by" relation. Format: `[operator]value[|value2|...]` Operators: `=`, `!`, `=p`, `=!p`, `!p`, `*o`, `!o`, `*`, `!*` Examples: `123`, `*`
  --blocks: string # Filter by "blocks" relation. Format: `[operator]value[|value2|...]` Operators: `=`, `!`, `=p`, `=!p`, `!p`, `*o`, `!o`, `*`, `!*` Examples: `123`, `*o`
  --blocked: string # Filter by "blocked by" relation. Format: `[operator]value[|value2|...]` Operators: `=`, `!`, `=p`, `=!p`, `!p`, `*o`, `!o`, `*`, `!*` Examples: `123`, `*o`
  --precedes: string # Filter by "precedes" relation. Format: `[operator]value[|value2|...]` Operators: `=`, `!`, `=p`, `=!p`, `!p`, `*o`, `!o`, `*`, `!*` Examples: `123`, `*`
  --follows: string # Filter by "follows" relation. Format: `[operator]value[|value2|...]` Operators: `=`, `!`, `=p`, `=!p`, `!p`, `*o`, `!o`, `*`, `!*` Examples: `123`, `*`
  --copied-to: string # Filter by "copied to" relation. Format: `[operator]value[|value2|...]` Operators: `=`, `!`, `=p`, `=!p`, `!p`, `*o`, `!o`, `*`, `!*` Examples: `123`, `*`
  --copied-from: string # Filter by "copied from" relation. Format: `[operator]value[|value2|...]` Operators: `=`, `!`, `=p`, `=!p`, `!p`, `*o`, `!o`, `*`, `!*` Examples: `123`, `*`
  --any-searchable: string # Full-text search across all searchable fields. Format: `<operator>value` Operators: `~` (contains all words), `*~` (contains any word), `!~` (not contains) Examples: `~keyword`, `*~foo bar`
  --query-id: int # ID of a saved query to apply. When specified, the saved query's filter criteria are used. Other filter parameters in the same request are ignored. Use GET /queries.json to retrieve available saved queries.
  --X-Redmine-Switch-User: string # e.g. jsmith
  --X-Redmine-Nometa: int@X-Redmine-Nometa-completer
]: nothing -> record<issues: table<id: int, project: record, tracker: record, status: record, priority: record, author: record, assigned_to: record, category: record, fixed_version: record, parent: record, subject: string, description: string, start_date: string, due_date: string, done_ratio: int, is_private: bool, estimated_hours: float, total_estimated_hours: float, spent_hours: float, total_spent_hours: float, custom_fields: list, created_on: string, updated_on: string, closed_on: string, attachments: list, relations: list>, total_count: int, offset: int, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "nometa" $nometa "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include" $include "csv") (serialize-qp "issue_id" $issue_id "scalar") (serialize-qp "subproject_id" $subproject_id "scalar") (serialize-qp "tracker_id" $tracker_id "scalar") (serialize-qp "status_id" $status_id "scalar") (serialize-qp "priority_id" $priority_id "scalar") (serialize-qp "assigned_to_id" $assigned_to_id "scalar") (serialize-qp "author_id" $author_id "scalar") (serialize-qp "author.group" $authorgroup "scalar") (serialize-qp "author.role" $authorrole "scalar") (serialize-qp "member_of_group" $member_of_group "scalar") (serialize-qp "assigned_to_role" $assigned_to_role "scalar") (serialize-qp "fixed_version_id" $fixed_version_id "scalar") (serialize-qp "fixed_version.due_date" $fixed_versiondue_date "scalar") (serialize-qp "fixed_version.status" $fixed_versionstatus "scalar") (serialize-qp "category_id" $category_id "scalar") (serialize-qp "parent_id" $parent_id "scalar") (serialize-qp "child_id" $child_id "scalar") (serialize-qp "cf_x" $cf_x "multi") (serialize-qp "subject" $subject "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "notes" $notes "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "updated_on" $updated_on "scalar") (serialize-qp "closed_on" $closed_on "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "due_date" $due_date "scalar") (serialize-qp "estimated_hours" $estimated_hours "scalar") (serialize-qp "spent_time" $spent_time "scalar") (serialize-qp "done_ratio" $done_ratio "scalar") (serialize-qp "is_private" $is_private "scalar") (serialize-qp "attachment" $attachment "scalar") (serialize-qp "attachment_description" $attachment_description "scalar") (serialize-qp "watcher_id" $watcher_id "scalar") (serialize-qp "updated_by" $updated_by "scalar") (serialize-qp "last_updated_by" $last_updated_by "scalar") (serialize-qp "project.status" $projectstatus "scalar") (serialize-qp "relates" $relates "scalar") (serialize-qp "duplicates" $duplicates "scalar") (serialize-qp "duplicated" $duplicated "scalar") (serialize-qp "blocks" $blocks "scalar") (serialize-qp "blocked" $blocked "scalar") (serialize-qp "precedes" $precedes "scalar") (serialize-qp "follows" $follows "scalar") (serialize-qp "copied_to" $copied_to "scalar") (serialize-qp "copied_from" $copied_from "scalar") (serialize-qp "any_searchable" $any_searchable "scalar") (serialize-qp "query_id" $query_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/issues.($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User, "X-Redmine-Nometa": $X_Redmine_Nometa} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create issue under project
#
# POST /projects/{project_id}/issues.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Issues#Creating-an-issue
# operationId: createIssueUnderProject
# --issue shape: {tracker_id?: int, status_id?: int, priority_id?: int, subject: string, description?: string, start_date?: string, due_date?: string, done_ratio?: int, category_id?: int, fixed_version_id?: int, assigned_to_id?: int, parent_issue_id?: int, custom_fields?: list, custom_field_values?: record, watcher_user_ids?: list, is_private?: bool, estimated_hours?: float, uploads?: list}
export def "projects-issues-format createIssueUnderProject" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  issue: record # shape: {tracker_id?: int, status_id?: int, priority_id?: int, subject: string, description?: string, start_date?: string, due_date?: string, done_ratio?: int, category_id?: int, fixed_version_id?: int, assigned_to_id?: int, parent_issue_id?: int, custom_fields?: list, custom_field_values?: record, watcher_user_ids?: list, is_private?: bool, estimated_hours?: float, uploads?: list}
]: any -> record<issue: record<id: int, project: record<id: int, name: string>, tracker: record<id: int, name: string>, status: record<id: int, name: string, is_closed: bool>, priority: record<id: int, name: string>, author: record<id: int, name: string>, assigned_to: record<id: int, name: string>, category: record<id: int, name: string>, fixed_version: record<id: int, name: string>, parent: record<id: int>, subject: string, description: string, start_date: string, due_date: string, done_ratio: int, is_private: bool, estimated_hours: float, total_estimated_hours: float, spent_hours: float, total_spent_hours: float, custom_fields: list<record>, created_on: string, updated_on: string, closed_on: string, attachments: list<record>, relations: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/issues.($format)")
  let body = {issue: $issue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add watcher
#
# POST /issues/{issue_id}/watchers.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Issues#Adding-a-watcher
# operationId: addWatcher
export def "issues-watchers-format addWatcher" [
  format: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  user_id: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/issues/($issue_id)/watchers.($format)")
  let body = {user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove watcher
#
# DELETE /issues/{issue_id}/watchers/{user_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Issues#Removing-a-watcher
# operationId: removeWatcher
export def "issues-watchers removeWatcher" [
  format: string
  issue_id: int
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/issues/($issue_id)/watchers/($user_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List projects
#
# GET /projects.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Projects#Listing-projects
# operationId: getProjects
export def "projects-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int
  --limit: int
  --nometa: int@nometa-completer
  --include: list # Comma-separated list of associated data to include for each project. Values: `trackers` (available issue trackers), `issue_categories` (issue categories), `time_entry_activities` (time entry activity types), `enabled_modules` (enabled modules/features), `issue_custom_fields` (custom fields for issues)
  --status: string # Filter by project status. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Values: `1` (active), `5` (closed) Examples: `1`, `1|5`, `!1`
  --id: string # Filter by project ID. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Special values: `mine` (projects where current user is a member), `bookmarks` (bookmarked projects) Examples: `1|2|3`, `mine`, `!mine`, `mine|bookmarks`
  --name: string # Filter by project name. Format: `<operator>value` Operators: `~` (contains), `!~` (not contains), `*~` (contains any word), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~keyword`, `^prefix`
  --description: string # Filter by project description. Format: `<operator>value` Operators: `~` (contains), `!~` (not contains), `*~` (contains any word), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~keyword`, `!~excluded`
  --parent-id: string # Filter by parent project. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any, i.e. is a subproject), `!*` (none, i.e. is a root project) Special values: `mine` (projects where current user is a member), `bookmarks` (bookmarked projects) Examples: `1|2`, `mine`, `*`, `!*`
  --is-public: string # Filter by public/private status. Format: `[operator]value` Operators: `=` (default), `!` (not equal) Values: `1` (public), `0` (private) Examples: `1`, `!1`
  --created-on: string # Filter by creation date. Format: `<operator>[value]` Operators: `=` (on date), `>=` (on or after), `<=` (on or before), `><` (between, pipe-separated), `t` (today), `ld` (yesterday), `w` (this week), `lw` (last week), `l2w` (last 2 weeks), `m` (this month), `lm` (last month), `y` (this year), `t-` (n days ago), `>t-` (less than n days ago), `<t-` (more than n days ago), `><t-` (between n1 and n2 days ago), `*` (any), `!*` (none) Examples: `>=2024-01-01`, `><2024-01-01|2024-12-31`, `t`, `>t-7`, `lm`
  --updated-on: string # Filter by last updated date. Format: `<operator>[value]` Operators: `=` (on date), `>=` (on or after), `<=` (on or before), `><` (between, pipe-separated), `t` (today), `ld` (yesterday), `w` (this week), `lw` (last week), `l2w` (last 2 weeks), `m` (this month), `lm` (last month), `y` (this year), `t-` (n days ago), `>t-` (less than n days ago), `<t-` (more than n days ago), `><t-` (between n1 and n2 days ago), `*` (any), `!*` (none) Examples: `>=2024-01-01`, `><2024-01-01|2024-12-31`, `t`, `>t-7`, `lm`
  --X-Redmine-Switch-User: string # e.g. jsmith
  --X-Redmine-Nometa: int@X-Redmine-Nometa-completer
]: nothing -> record<projects: table<id: int, name: string, identifier: string, description: string, homepage: string, parent: record, status: int, is_public: bool, inherit_members: bool, custom_fields: list, trackers: list, issue_categories: list, time_entry_activities: list, enabled_modules: list, issue_custom_fields: list, created_on: string, updated_on: string>, total_count: int, offset: int, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "nometa" $nometa "scalar") (serialize-qp "include" $include "csv") (serialize-qp "status" $status "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "parent_id" $parent_id "scalar") (serialize-qp "is_public" $is_public "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "updated_on" $updated_on "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects.($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User, "X-Redmine-Nometa": $X_Redmine_Nometa} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create project
#
# POST /projects.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Projects#Creating-a-project
# operationId: createProject
# --project shape: {name: string, identifier: string, description?: string, homepage?: string, is_public?: bool, parent_id?: int, inherit_members?: bool, default_assigned_to_id?: int, default_version_id?: int, default_issue_query_id?: int, tracker_ids?: list, enabled_module_names?: list, issue_custom_field_ids?: list, custom_fields?: list, custom_field_values?: record}
export def "projects-format createProject" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  project: record # shape: {name: string, identifier: string, description?: string, homepage?: string, is_public?: bool, parent_id?: int, inherit_members?: bool, default_assigned_to_id?: int, default_version_id?: int, default_issue_query_id?: int, tracker_ids?: list, enabled_module_names?: list, issue_custom_field_ids?: list, custom_fields?: list, custom_field_values?: record}
]: any -> record<project: record<id: int, name: string, identifier: string, description: string, homepage: string, parent: record<id: int, name: string>, status: int, is_public: bool, inherit_members: bool, default_version: record<id: int, name: string>, default_assignee: record<id: int, name: string>, custom_fields: list<record>, trackers: list<record>, issue_categories: list<record>, time_entry_activities: list<record>, enabled_modules: list<record>, issue_custom_fields: list<record>, created_on: string, updated_on: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects.($format)")
  let body = {project: $project} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show project
#
# GET /projects/{project_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Projects#Showing-a-project
# operationId: getProject
export def "projects get" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Comma-separated list of associated data to include in the response. Values: `trackers` (available issue trackers), `issue_categories` (issue categories), `time_entry_activities` (time entry activity types), `enabled_modules` (enabled modules/features), `issue_custom_fields` (custom fields for issues)
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<project: record<id: int, name: string, identifier: string, description: string, homepage: string, parent: record<id: int, name: string>, status: int, is_public: bool, inherit_members: bool, default_version: record<id: int, name: string>, default_assignee: record<id: int, name: string>, custom_fields: list<record>, trackers: list<record>, issue_categories: list<record>, time_entry_activities: list<record>, enabled_modules: list<record>, issue_custom_fields: list<record>, created_on: string, updated_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id).($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update project
#
# PUT /projects/{project_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Projects#Updating-a-project
# operationId: updateProject
# --project shape: {identifier?: string, name?: string, description?: string, homepage?: string, is_public?: bool, parent_id?: int, inherit_members?: bool, default_assigned_to_id?: int, default_version_id?: int, default_issue_query_id?: int, tracker_ids?: list, enabled_module_names?: list, issue_custom_field_ids?: list, custom_fields?: list, custom_field_values?: record}
export def "projects updateProject" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  --project: record # shape: {identifier?: string, name?: string, description?: string, homepage?: string, is_public?: bool, parent_id?: int, inherit_members?: bool, default_assigned_to_id?: int, default_version_id?: int, default_issue_query_id?: int, tracker_ids?: list, enabled_module_names?: list, issue_custom_field_ids?: list, custom_fields?: list, custom_field_values?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id).($format)")
  let body = {project: $project} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete project
#
# DELETE /projects/{project_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Projects#Deleting-a-project
# operationId: deleteProject
export def "projects delete" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive project
#
# PUT /projects/{project_id}/archive.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Projects#Archiving-a-project
# operationId: archiveProject
export def "projects-archive-format archiveProject" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/archive.($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unarchive project
#
# PUT /projects/{project_id}/unarchive.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Projects#Unarchiving-a-project
# operationId: unarchiveProject
export def "projects-unarchive-format unarchiveProject" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/unarchive.($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List memberships
#
# GET /projects/{project_id}/memberships.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Memberships#GET
# operationId: getMemberships
export def "projects-memberships-format get" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int
  --limit: int
  --nometa: int@nometa-completer
  --X-Redmine-Switch-User: string # e.g. jsmith
  --X-Redmine-Nometa: int@X-Redmine-Nometa-completer
]: nothing -> record<memberships: table<id: int, project: record, user: record, group: record, roles: list>, total_count: int, offset: int, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "nometa" $nometa "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/memberships.($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User, "X-Redmine-Nometa": $X_Redmine_Nometa} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create membership
#
# POST /projects/{project_id}/memberships.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Memberships#POST
# operationId: createMembership
# --membership shape: {user_id: int, role_ids: list}
export def "projects-memberships-format createMembership" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  membership: record # shape: {user_id: int, role_ids: list}
]: any -> record<membership: record<id: int, project: record<id: int, name: string>, user: record<id: int, name: string>, group: record<id: int, name: string>, roles: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/memberships.($format)")
  let body = {membership: $membership} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show membership
#
# GET /memberships/{membership_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Memberships#GET-2
# operationId: getMembership
export def "memberships get" [
  format: string
  membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<membership: record<id: int, project: record<id: int, name: string>, user: record<id: int, name: string>, group: record<id: int, name: string>, roles: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/memberships/($membership_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update membership
#
# PUT /memberships/{membership_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Memberships#PUT
# operationId: updateMembership
# --membership shape: {role_ids: list}
export def "memberships updateMembership" [
  format: string
  membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  --membership: record # shape: {role_ids: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/memberships/($membership_id).($format)")
  let body = {membership: $membership} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete membership
#
# DELETE /memberships/{membership_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Memberships#DELETE
# operationId: deleteMembership
export def "memberships delete" [
  format: string
  membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/memberships/($membership_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Close project
#
# PUT /projects/{project_id}/close.{format}
# operationId: closeProject
export def "projects-close-format closeProject" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/close.($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reopen project
#
# PUT /projects/{project_id}/reopen.{format}
# operationId: reopenProject
export def "projects-reopen-format reopenProject" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/reopen.($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List users
#
# GET /users.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Users#GET
# operationId: getUsers
export def "users-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int
  --limit: int
  --nometa: int@nometa-completer
  --include: list # Comma-separated list of associated data to include for each user. Values: `auth_source` (authentication source information)
  --status: string # Filter by user status. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Values: `1` (active), `2` (registered), `3` (locked) Examples: `1`, `1|2`, `!3`
  --name: string # Filter by name, login, or email (contains search). The API always uses the `~` (contains) operator regardless of any operator prefix. Examples: `john`, `admin`
  --group-id: string # Filter by group membership (legacy parameter). Internally converted to `is_member_of_group` filter with `=` operator. Value is the group ID.
  --auth-source-id: string # Filter by authentication source. Undocumented Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Examples: `1`, `!1`
  --twofa-scheme: string # Filter by two-factor authentication scheme. Undocumented Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Only available when two-factor authentication is enabled in Redmine settings.
  --login: string # Filter by login. Undocumented Format: `[operator]value` Operators: `~` (contains, default), `*~` (contains any word), `=` (exact match), `!~` (does not contain), `!` (not equal), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~admin`, `^john`
  --firstname: string # Filter by first name. Undocumented Format: `[operator]value` Operators: `~` (contains, default), `*~` (contains any word), `=` (exact match), `!~` (does not contain), `!` (not equal), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~John`, `=John`
  --lastname: string # Filter by last name. Undocumented Format: `[operator]value` Operators: `~` (contains, default), `*~` (contains any word), `=` (exact match), `!~` (does not contain), `!` (not equal), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~Doe`, `=Doe`
  --mail: string # Filter by email address. Undocumented Format: `[operator]value` Operators: `~` (contains, default), `*~` (contains any word), `=` (exact match), `!~` (does not contain), `!` (not equal), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~example.com`, `$@example.com`
  --created-on: string # Filter by creation date. Undocumented Format: `[operator]value` Operators: `=` (on date), `>=`, `<=`, `><` (between, pipe-separated), `>t-` (more than N days ago), `<t-` (less than N days ago), `><t-` (between N and M days ago), `t-` (N days ago), `t` (today), `ld` (yesterday), `w` (this week), `lw` (last week), `l2w` (last 2 weeks), `m` (this month), `lm` (last month), `y` (this year), `*` (any), `!*` (none) Examples: `>=2024-01-01`, `>t-30`, `lm`
  --last-login-on: string # Filter by last login date. Undocumented Format: `[operator]value` Operators: `=` (on date), `>=`, `<=`, `><` (between, pipe-separated), `>t-` (more than N days ago), `<t-` (less than N days ago), `><t-` (between N and M days ago), `t-` (N days ago), `t` (today), `ld` (yesterday), `w` (this week), `lw` (last week), `l2w` (last 2 weeks), `m` (this month), `lm` (last month), `y` (this year), `*` (any), `!*` (none) Examples: `>=2024-01-01`, `>t-30`, `!*`
  --admin: string # Filter by admin privilege. Undocumented Format: `[operator]value` Operators: `=` (default), `!` (not equal) Values: `1` (admin), `0` (non-admin) Examples: `1`, `!1`
  --X-Redmine-Switch-User: string # e.g. jsmith
  --X-Redmine-Nometa: int@X-Redmine-Nometa-completer
]: nothing -> record<users: table<id: int, login: string, admin: bool, firstname: string, lastname: string, mail: string, created_on: string, updated_on: string, last_login_on: string, passwd_changed_on: string, avatar_url: string, twofa_scheme: string, status: int, auth_source: record, custom_fields: list>, total_count: int, offset: int, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "nometa" $nometa "scalar") (serialize-qp "include" $include "csv") (serialize-qp "status" $status "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "auth_source_id" $auth_source_id "scalar") (serialize-qp "twofa_scheme" $twofa_scheme "scalar") (serialize-qp "login" $login "scalar") (serialize-qp "firstname" $firstname "scalar") (serialize-qp "lastname" $lastname "scalar") (serialize-qp "mail" $mail "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "last_login_on" $last_login_on "scalar") (serialize-qp "admin" $admin "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users.($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User, "X-Redmine-Nometa": $X_Redmine_Nometa} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create user
#
# POST /users.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Users#POST
# operationId: createUser
# --user shape: {login: string, admin?: bool, password?: string, firstname: string, lastname: string, mail: string, language?: string, auth_source_id?: int, mail_notification?: "all"|"selected"|"only_my_events"|"only_assigned"|"only_owner"|"none", notified_project_ids?: list, must_change_passwd?: bool, generate_password?: bool, status?: int, custom_fields?: list, custom_field_values?: record}
# --pref shape: {hide_mail?: bool, time_zone?: string, comments_sorting?: "asc"|"desc", warn_on_leaving_unsaved?: bool, no_self_notified?: bool, notify_about_high_priority_issues?: bool, textarea_font?: "monospace"|"proportional", recently_used_projects?: int, history_default_tab?: "notes"|"history"|"properties"|"time_entries"|"changesets"|"last_tab_visited", toolbar_language_options?: string, default_issue_query?: int, default_project_query?: int, auto_watch_on?: list}
export def "users-format createUser" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  user: record # shape: {login: string, admin?: bool, password?: string, firstname: string, lastname: string, mail: string, language?: string, auth_source_id?: int, mail_notification?: "all"|"selected"|"only_my_events"|"only_assigned"|"only_owner"|"none", notified_project_ids?: list, must_change_passwd?: bool, generate_password?: bool, status?: int, custom_fields?: list, custom_field_values?: record}
  --send-information: oneof<nothing, bool> # Set to true to send an account information email to the user. Not stored; only triggers email delivery.
  --pref: record # shape: {hide_mail?: bool, time_zone?: string, comments_sorting?: "asc"|"desc", warn_on_leaving_unsaved?: bool, no_self_notified?: bool, notify_about_high_priority_issues?: bool, textarea_font?: "monospace"|"proportional", recently_used_projects?: int, history_default_tab?: "notes"|"history"|"properties"|"time_entries"|"changesets"|"last_tab_visited", toolbar_language_options?: string, default_issue_query?: int, default_project_query?: int, auto_watch_on?: list}
]: any -> record<user: record<id: int, login: string, admin: bool, firstname: string, lastname: string, mail: string, created_on: string, updated_on: string, last_login_on: string, passwd_changed_on: string, avatar_url: string, twofa_scheme: string, api_key: string, status: int, custom_fields: list<record>, auth_source: record<id: int, name: string>, groups: list<record>, memberships: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users.($format)")
  let body = {user: $user, send_information: $send_information, pref: $pref} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show user
#
# GET /users/{user_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Users#GET-2
# operationId: getUser
export def "users get" [
  format: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Comma-separated list of associated data to include in the response. Values: `memberships` (project memberships with roles), `groups` (groups the user belongs to), `auth_source` (authentication source information)
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<user: record<id: int, login: string, admin: bool, firstname: string, lastname: string, mail: string, created_on: string, updated_on: string, last_login_on: string, passwd_changed_on: string, avatar_url: string, twofa_scheme: string, api_key: string, status: int, custom_fields: list<record>, auth_source: record<id: int, name: string>, groups: list<record>, memberships: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id).($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user
#
# PUT /users/{user_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Users#PUT
# operationId: updateUser
# --user shape: {login?: string, admin?: bool, password?: string, firstname?: string, lastname?: string, mail?: string, language?: string, auth_source_id?: int, mail_notification?: "all"|"selected"|"only_my_events"|"only_assigned"|"only_owner"|"none", notified_project_ids?: list, must_change_passwd?: bool, generate_password?: bool, status?: int, custom_fields?: list, custom_field_values?: record, group_ids?: list}
# --pref shape: {hide_mail?: bool, time_zone?: string, comments_sorting?: "asc"|"desc", warn_on_leaving_unsaved?: bool, no_self_notified?: bool, notify_about_high_priority_issues?: bool, textarea_font?: "monospace"|"proportional", recently_used_projects?: int, history_default_tab?: "notes"|"history"|"properties"|"time_entries"|"changesets"|"last_tab_visited", toolbar_language_options?: string, default_issue_query?: int, default_project_query?: int, auto_watch_on?: list}
export def "users updateUser" [
  format: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  --user: record # shape: {login?: string, admin?: bool, password?: string, firstname?: string, lastname?: string, mail?: string, language?: string, auth_source_id?: int, mail_notification?: "all"|"selected"|"only_my_events"|"only_assigned"|"only_owner"|"none", notified_project_ids?: list, must_change_passwd?: bool, generate_password?: bool, status?: int, custom_fields?: list, custom_field_values?: record, group_ids?: list}
  --send-information: oneof<nothing, bool> # Set to true to send an account information email to the user. Not stored; only triggers email delivery.
  --pref: record # shape: {hide_mail?: bool, time_zone?: string, comments_sorting?: "asc"|"desc", warn_on_leaving_unsaved?: bool, no_self_notified?: bool, notify_about_high_priority_issues?: bool, textarea_font?: "monospace"|"proportional", recently_used_projects?: int, history_default_tab?: "notes"|"history"|"properties"|"time_entries"|"changesets"|"last_tab_visited", toolbar_language_options?: string, default_issue_query?: int, default_project_query?: int, auto_watch_on?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id).($format)")
  let body = {user: $user, send_information: $send_information, pref: $pref} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete user
#
# DELETE /users/{user_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Users#DELETE
# operationId: deleteUser
export def "users delete" [
  format: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show current user
#
# GET /users/current.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Users#GET-2
# operationId: getCurrentUser
export def "users-current-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Comma-separated list of associated data to include in the response. Values: `memberships` (project memberships with roles), `groups` (groups the user belongs to), `auth_source` (authentication source information)
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<user: record<id: int, login: string, admin: bool, firstname: string, lastname: string, mail: string, created_on: string, updated_on: string, last_login_on: string, passwd_changed_on: string, avatar_url: string, twofa_scheme: string, api_key: string, status: int, custom_fields: list<record>, auth_source: record<id: int, name: string>, groups: list<record>, memberships: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/current.($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List time entries
#
# GET /time_entries.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_TimeEntries#Listing-time-entries
# operationId: getTimeEntries
export def "time-entries-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int
  --limit: int
  --nometa: int@nometa-completer
  --user-id: string # Filter by user. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Special values: `me` (current user) Examples: `1`, `me`, `!*`
  --project-id: string # Filter by project. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Special values: `mine` (projects where current user is a member), `bookmarks` (bookmarked projects) Examples: `1|2`, `mine`, `!mine`
  --spent-on: string # Filter by date spent. Format: `[operator]value` Operators: `=` (on date), `>=`, `<=`, `><` (between, pipe-separated), `>t-` (more than N days ago), `<t-` (less than N days ago), `><t-` (between N and M days ago), `t-` (N days ago), `t` (today), `ld` (yesterday), `w` (this week), `lw` (last week), `l2w` (last 2 weeks), `m` (this month), `lm` (last month), `y` (this year), `*` (any), `!*` (none) Examples: `=2024-01-01`, `>=2024-01-01`, `><2024-01-01|2024-12-31`, `>t-7`, `t`, `lw`
  --qp-from: string # Shortcut for `spent_on` filter. When used with `to`, filters as between (`>=from` and `<=to`). When used alone, filters as `>=from`. Format: `YYYY-MM-DD` (format: date)
  --qp-to: string # Shortcut for `spent_on` filter. When used with `from`, filters as between (`>=from` and `<=to`). When used alone, filters as `<=to`. Format: `YYYY-MM-DD` (format: date)
  --subproject-id: string # Filter by subproject. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Examples: `1|2`, `*`, `!*`
  --issue-id: string # Filter by issue. Format: `[operator]value` Operators: `=` (exact match), `~` (issue and its subtasks), `*` (any), `!*` (none) Examples: `=1`, `~1`, `*`, `!*`
  --issuetracker-id: string # Filter by issue's tracker. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Examples: `1|2`, `!3`
  --issuestatus-id: string # Filter by issue's status. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Examples: `1|2`, `!3`
  --issuefixed-version-id: string # Filter by issue's target version. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Examples: `1|2`, `!3`
  --issueparent-id: string # Filter by issue's parent. Format: `[operator]value` Operators: `=` (exact match), `~` (issue and its subtasks), `*` (any), `!*` (none) Examples: `=1`, `~1`, `*`, `!*`
  --issuecategory-id: string # Filter by issue's category. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Examples: `1|2`, `!*`
  --issuesubject: string # Filter by issue's subject. Format: `[operator]value` Operators: `~` (contains, default), `*~` (contains any word), `!~` (does not contain), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~keyword`, `^prefix`, `$suffix`
  --usergroup: string # Filter by user's group. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Examples: `1|2`, `*`
  --userrole: string # Filter by user's role. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Examples: `1|2`, `*`
  --author-id: string # Filter by author. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Special values: `me` (current user) Examples: `1`, `me`, `!*`
  --activity-id: string # Filter by activity. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Examples: `1|2`, `!3`
  --projectstatus: string # Filter by project's status. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Values: `1` (active), `5` (closed) Examples: `1`, `!5`
  --comments: string # Filter by comments. Format: `[operator]value` Operators: `~` (contains, default), `*~` (contains any word), `!~` (does not contain), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~keyword`, `^prefix`
  --hours: string # Filter by hours. Format: `[operator]value` Operators: `=` (default), `>=`, `<=`, `><` (between, pipe-separated), `*` (any), `!*` (none) Examples: `=8`, `>=4`, `><1|8`
  --qp-sort: string # Sort order. Comma-separated list of `field` or `field:desc`. Default direction is ascending. Examples: `spent_on:desc`, `hours:desc,spent_on` (e.g. spent_on:desc)
  --X-Redmine-Switch-User: string # e.g. jsmith
  --X-Redmine-Nometa: int@X-Redmine-Nometa-completer
]: nothing -> record<time_entries: table<id: int, project: record, issue: record, user: record, activity: record, hours: float, comments: string, spent_on: string, created_on: string, updated_on: string, custom_fields: list>, total_count: int, offset: int, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "nometa" $nometa "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "spent_on" $spent_on "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "subproject_id" $subproject_id "scalar") (serialize-qp "issue_id" $issue_id "scalar") (serialize-qp "issue.tracker_id" $issuetracker_id "scalar") (serialize-qp "issue.status_id" $issuestatus_id "scalar") (serialize-qp "issue.fixed_version_id" $issuefixed_version_id "scalar") (serialize-qp "issue.parent_id" $issueparent_id "scalar") (serialize-qp "issue.category_id" $issuecategory_id "scalar") (serialize-qp "issue.subject" $issuesubject "scalar") (serialize-qp "user.group" $usergroup "scalar") (serialize-qp "user.role" $userrole "scalar") (serialize-qp "author_id" $author_id "scalar") (serialize-qp "activity_id" $activity_id "scalar") (serialize-qp "project.status" $projectstatus "scalar") (serialize-qp "comments" $comments "scalar") (serialize-qp "hours" $hours "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/time_entries.($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User, "X-Redmine-Nometa": $X_Redmine_Nometa} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create time entry
#
# POST /time_entries.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_TimeEntries#Creating-a-time-entry
# operationId: createTimeEntry
# --time_entry shape: {issue_id?: int, project_id?: int, spent_on?: string, hours: float, activity_id?: int, comments?: string, user_id?: int, custom_fields?: list, custom_field_values?: record}
export def "time-entries-format createTimeEntry" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  time_entry: record # shape: {issue_id?: int, project_id?: int, spent_on?: string, hours: float, activity_id?: int, comments?: string, user_id?: int, custom_fields?: list, custom_field_values?: record}
]: any -> record<time_entry: record<id: int, project: record<id: int, name: string>, issue: record<id: int>, user: record<id: int, name: string>, activity: record<id: int, name: string>, hours: float, comments: string, spent_on: string, created_on: string, updated_on: string, custom_fields: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/time_entries.($format)")
  let body = {time_entry: $time_entry} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show time entry
#
# GET /time_entries/{time_entry_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_TimeEntries#Showing-a-time-entry
# operationId: getTimeEntry
export def "time-entries get" [
  format: string
  time_entry_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<time_entry: record<id: int, project: record<id: int, name: string>, issue: record<id: int>, user: record<id: int, name: string>, activity: record<id: int, name: string>, hours: float, comments: string, spent_on: string, created_on: string, updated_on: string, custom_fields: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/time_entries/($time_entry_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update time entry
#
# PUT /time_entries/{time_entry_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_TimeEntries#Updating-a-time-entry
# operationId: updateTimeEntry
# --time_entry shape: {issue_id?: int, project_id?: int, spent_on?: string, hours?: float, activity_id?: int, comments?: string, user_id?: int, custom_fields?: list, custom_field_values?: record}
export def "time-entries updateTimeEntry" [
  format: string
  time_entry_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  --time-entry: record # shape: {issue_id?: int, project_id?: int, spent_on?: string, hours?: float, activity_id?: int, comments?: string, user_id?: int, custom_fields?: list, custom_field_values?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/time_entries/($time_entry_id).($format)")
  let body = {time_entry: $time_entry} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete time entry
#
# DELETE /time_entries/{time_entry_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_TimeEntries#Deleting-a-time-entry
# operationId: deleteTimeEntry
export def "time-entries delete" [
  format: string
  time_entry_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/time_entries/($time_entry_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List time entries by project
#
# GET /projects/{project_id}/time_entries.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_TimeEntries#Listing-time-entries
# operationId: getTimeEntriesByProject
export def "projects-time-entries-format get" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int
  --limit: int
  --nometa: int@nometa-completer
  --user-id: string # Filter by user. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Special values: `me` (current user) Examples: `1`, `me`, `!*`
  --spent-on: string # Filter by date spent. Format: `[operator]value` Operators: `=` (on date), `>=`, `<=`, `><` (between, pipe-separated), `>t-` (more than N days ago), `<t-` (less than N days ago), `><t-` (between N and M days ago), `t-` (N days ago), `t` (today), `ld` (yesterday), `w` (this week), `lw` (last week), `l2w` (last 2 weeks), `m` (this month), `lm` (last month), `y` (this year), `*` (any), `!*` (none) Examples: `=2024-01-01`, `>=2024-01-01`, `><2024-01-01|2024-12-31`, `>t-7`, `t`, `lw`
  --qp-from: string # Shortcut for `spent_on` filter. When used with `to`, filters as between (`>=from` and `<=to`). When used alone, filters as `>=from`. Format: `YYYY-MM-DD` (format: date)
  --qp-to: string # Shortcut for `spent_on` filter. When used with `from`, filters as between (`>=from` and `<=to`). When used alone, filters as `<=to`. Format: `YYYY-MM-DD` (format: date)
  --subproject-id: string # Filter by subproject. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Examples: `1|2`, `*`, `!*`
  --issue-id: string # Filter by issue. Format: `[operator]value` Operators: `=` (exact match), `~` (issue and its subtasks), `*` (any), `!*` (none) Examples: `=1`, `~1`, `*`, `!*`
  --issuetracker-id: string # Filter by issue's tracker. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Examples: `1|2`, `!3`
  --issuestatus-id: string # Filter by issue's status. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Examples: `1|2`, `!3`
  --issuefixed-version-id: string # Filter by issue's target version. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Examples: `1|2`, `!3`
  --issueparent-id: string # Filter by issue's parent. Format: `[operator]value` Operators: `=` (exact match), `~` (issue and its subtasks), `*` (any), `!*` (none) Examples: `=1`, `~1`, `*`, `!*`
  --issuecategory-id: string # Filter by issue's category. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Examples: `1|2`, `!*`
  --issuesubject: string # Filter by issue's subject. Format: `[operator]value` Operators: `~` (contains, default), `*~` (contains any word), `!~` (does not contain), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~keyword`, `^prefix`, `$suffix`
  --usergroup: string # Filter by user's group. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Examples: `1|2`, `*`
  --userrole: string # Filter by user's role. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Examples: `1|2`, `*`
  --author-id: string # Filter by author. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal), `*` (any), `!*` (none) Special values: `me` (current user) Examples: `1`, `me`, `!*`
  --activity-id: string # Filter by activity. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Examples: `1|2`, `!3`
  --projectstatus: string # Filter by project's status. Format: `[operator]value[|value2|...]` Operators: `=` (default), `!` (not equal) Values: `1` (active), `5` (closed) Examples: `1`, `!5`
  --comments: string # Filter by comments. Format: `[operator]value` Operators: `~` (contains, default), `*~` (contains any word), `!~` (does not contain), `^` (starts with), `$` (ends with), `*` (any), `!*` (none) Examples: `~keyword`, `^prefix`
  --hours: string # Filter by hours. Format: `[operator]value` Operators: `=` (default), `>=`, `<=`, `><` (between, pipe-separated), `*` (any), `!*` (none) Examples: `=8`, `>=4`, `><1|8`
  --qp-sort: string # Sort order. Comma-separated list of `field` or `field:desc`. Default direction is ascending. Examples: `spent_on:desc`, `hours:desc,spent_on` (e.g. spent_on:desc)
  --X-Redmine-Switch-User: string # e.g. jsmith
  --X-Redmine-Nometa: int@X-Redmine-Nometa-completer
]: nothing -> record<time_entries: table<id: int, project: record, issue: record, user: record, activity: record, hours: float, comments: string, spent_on: string, created_on: string, updated_on: string, custom_fields: list>, total_count: int, offset: int, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "nometa" $nometa "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "spent_on" $spent_on "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "subproject_id" $subproject_id "scalar") (serialize-qp "issue_id" $issue_id "scalar") (serialize-qp "issue.tracker_id" $issuetracker_id "scalar") (serialize-qp "issue.status_id" $issuestatus_id "scalar") (serialize-qp "issue.fixed_version_id" $issuefixed_version_id "scalar") (serialize-qp "issue.parent_id" $issueparent_id "scalar") (serialize-qp "issue.category_id" $issuecategory_id "scalar") (serialize-qp "issue.subject" $issuesubject "scalar") (serialize-qp "user.group" $usergroup "scalar") (serialize-qp "user.role" $userrole "scalar") (serialize-qp "author_id" $author_id "scalar") (serialize-qp "activity_id" $activity_id "scalar") (serialize-qp "project.status" $projectstatus "scalar") (serialize-qp "comments" $comments "scalar") (serialize-qp "hours" $hours "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/time_entries.($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User, "X-Redmine-Nometa": $X_Redmine_Nometa} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create time entry under project
#
# POST /projects/{project_id}/time_entries.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_TimeEntries#Creating-a-time-entry
# operationId: createTimeEntryUnderProject
# --time_entry shape: {issue_id?: int, spent_on?: string, hours: float, activity_id?: int, comments?: string, user_id?: int, custom_fields?: list, custom_field_values?: record}
export def "projects-time-entries-format createTimeEntryUnderProject" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  time_entry: record # shape: {issue_id?: int, spent_on?: string, hours: float, activity_id?: int, comments?: string, user_id?: int, custom_fields?: list, custom_field_values?: record}
]: any -> record<time_entry: record<id: int, project: record<id: int, name: string>, issue: record<id: int>, user: record<id: int, name: string>, activity: record<id: int, name: string>, hours: float, comments: string, spent_on: string, created_on: string, updated_on: string, custom_fields: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/time_entries.($format)")
  let body = {time_entry: $time_entry} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create time entry under issue
#
# POST /issues/{issue_id}/time_entries.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_TimeEntries#Creating-a-time-entry
# operationId: createTimeEntryUnderIssue
# --time_entry shape: {project_id?: int, spent_on?: string, hours: float, activity_id?: int, comments?: string, user_id?: int, custom_fields?: list, custom_field_values?: record}
export def "issues-time-entries-format createTimeEntryUnderIssue" [
  format: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  time_entry: record # shape: {project_id?: int, spent_on?: string, hours: float, activity_id?: int, comments?: string, user_id?: int, custom_fields?: list, custom_field_values?: record}
]: any -> record<time_entry: record<id: int, project: record<id: int, name: string>, issue: record<id: int>, user: record<id: int, name: string>, activity: record<id: int, name: string>, hours: float, comments: string, spent_on: string, created_on: string, updated_on: string, custom_fields: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/issues/($issue_id)/time_entries.($format)")
  let body = {time_entry: $time_entry} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List news
#
# GET /news.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_News#GET
# operationId: getNewsList
export def "news-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int
  --limit: int
  --nometa: int@nometa-completer
  --X-Redmine-Switch-User: string # e.g. jsmith
  --X-Redmine-Nometa: int@X-Redmine-Nometa-completer
]: nothing -> record<news: table<id: int, project: record, author: record, title: string, summary: string, description: string, created_on: string, attachments: list, comments: list>, total_count: int, offset: int, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "nometa" $nometa "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/news.($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User, "X-Redmine-Nometa": $X_Redmine_Nometa} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show news
#
# GET /news/{news_id}.{format}
# operationId: getNews
export def "news get" [
  format: string
  news_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Comma-separated list of associated data to include in the response. Values: `attachments` (file attachments), `comments` (comments/replies on the news item)
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<news: record<id: int, project: record<id: int, name: string>, author: record<id: int, name: string>, title: string, summary: string, description: string, created_on: string, attachments: list<record>, comments: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/news/($news_id).($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update news
#
# PUT /news/{news_id}.{format}
# operationId: updateNews
# --news shape: {title?: string, summary?: string, description?: string, uploads?: list}
export def "news updateNews" [
  format: string
  news_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  --news: record # shape: {title?: string, summary?: string, description?: string, uploads?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/news/($news_id).($format)")
  let body = {news: $news} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete news
#
# DELETE /news/{news_id}.{format}
# operationId: deleteNews
export def "news delete" [
  format: string
  news_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/news/($news_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List news by project
#
# GET /projects/{project_id}/news.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_News#GET-2
# operationId: getNewsListByProject
export def "projects-news-format get" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int
  --limit: int
  --nometa: int@nometa-completer
  --X-Redmine-Switch-User: string # e.g. jsmith
  --X-Redmine-Nometa: int@X-Redmine-Nometa-completer
]: nothing -> record<news: table<id: int, project: record, author: record, title: string, summary: string, description: string, created_on: string, attachments: list, comments: list>, total_count: int, offset: int, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "nometa" $nometa "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/news.($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User, "X-Redmine-Nometa": $X_Redmine_Nometa} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create news
#
# POST /projects/{project_id}/news.{format}
# operationId: createNews
# --news shape: {title: string, summary?: string, description: string, uploads?: list}
export def "projects-news-format createNews" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  news: record # shape: {title: string, summary?: string, description: string, uploads?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/news.($format)")
  let body = {news: $news} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List issue relations
#
# GET /issues/{issue_id}/relations.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_IssueRelations#GET
# operationId: getIssueRelations
export def "issues-relations-format get" [
  format: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<relations: table<id: int, issue_id: int, issue_to_id: int, relation_type: string, delay: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/issues/($issue_id)/relations.($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create issue relation
#
# POST /issues/{issue_id}/relations.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_IssueRelations#POST
# operationId: createIssueRelation
# --relation shape: {issue_to_id: int, relation_type: "relates"|"duplicates"|"duplicated"|"blocks"|"blocked"|"precedes"|"follows"|"copied_to"|"copied_from", delay?: int}
export def "issues-relations-format createIssueRelation" [
  format: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  relation: record # shape: {issue_to_id: int, relation_type: "relates"|"duplicates"|"duplicated"|"blocks"|"blocked"|"precedes"|"follows"|"copied_to"|"copied_from", delay?: int}
]: any -> record<relation: record<id: int, issue_id: int, issue_to_id: int, relation_type: string, delay: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/issues/($issue_id)/relations.($format)")
  let body = {relation: $relation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show issue relation
#
# GET /relations/{issue_relation_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_IssueRelations#GET-2
# operationId: getIssueRelation
export def "relations get" [
  format: string
  issue_relation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<relation: record<id: int, issue_id: int, issue_to_id: int, relation_type: string, delay: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/relations/($issue_relation_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete issue relation
#
# DELETE /relations/{issue_relation_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_IssueRelations#DELETE
# operationId: deleteIssueRelation
export def "relations delete" [
  format: string
  issue_relation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/relations/($issue_relation_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List versions by project
#
# GET /projects/{project_id}/versions.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Versions#GET
# operationId: getVersionsByProject
export def "projects-versions-format get" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nometa: int@nometa-completer
  --X-Redmine-Switch-User: string # e.g. jsmith
  --X-Redmine-Nometa: int@X-Redmine-Nometa-completer
]: nothing -> record<versions: table<id: int, project: record, name: string, description: string, status: string, due_date: string, sharing: string, wiki_page_title: string, custom_fields: list, created_on: string, updated_on: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nometa" $nometa "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/versions.($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User, "X-Redmine-Nometa": $X_Redmine_Nometa} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create version
#
# POST /projects/{project_id}/versions.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Versions#POST
# operationId: createVersion
# --version shape: {name: string, status?: "open"|"locked"|"closed", sharing?: "none"|"descendants"|"hierarchy"|"tree"|"system", due_date?: string, description?: string, wiki_page_title?: string, default_project_version?: bool, custom_fields?: list, custom_field_values?: record}
export def "projects-versions-format createVersion" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  version: record # shape: {name: string, status?: "open"|"locked"|"closed", sharing?: "none"|"descendants"|"hierarchy"|"tree"|"system", due_date?: string, description?: string, wiki_page_title?: string, default_project_version?: bool, custom_fields?: list, custom_field_values?: record}
]: any -> record<version: record<id: int, project: record<id: int, name: string>, name: string, description: string, status: string, due_date: string, sharing: string, wiki_page_title: string, estimated_hours: float, spent_hours: float, custom_fields: list<record>, created_on: string, updated_on: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/versions.($format)")
  let body = {version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show version
#
# GET /versions/{version_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Versions#GET-2
# operationId: getVersion
export def "versions get" [
  format: string
  version_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<version: record<id: int, project: record<id: int, name: string>, name: string, description: string, status: string, due_date: string, sharing: string, wiki_page_title: string, estimated_hours: float, spent_hours: float, custom_fields: list<record>, created_on: string, updated_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/versions/($version_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update version
#
# PUT /versions/{version_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Versions#PUT
# operationId: updateVersion
# --version shape: {name?: string, status?: "open"|"locked"|"closed", sharing?: "none"|"descendants"|"hierarchy"|"tree"|"system", due_date?: string, description?: string, wiki_page_title?: string, default_project_version?: bool, custom_fields?: list, custom_field_values?: record}
export def "versions updateVersion" [
  format: string
  version_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  --version: record # shape: {name?: string, status?: "open"|"locked"|"closed", sharing?: "none"|"descendants"|"hierarchy"|"tree"|"system", due_date?: string, description?: string, wiki_page_title?: string, default_project_version?: bool, custom_fields?: list, custom_field_values?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/versions/($version_id).($format)")
  let body = {version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete version
#
# DELETE /versions/{version_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Versions#DELETE
# operationId: deleteVersion
export def "versions delete" [
  format: string
  version_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/versions/($version_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List wiki pages
#
# GET /projects/{project_id}/wiki/index.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_WikiPages#Getting-the-pages-list-of-a-wiki
# operationId: getWikiPages
export def "projects-wiki-index-format get" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<wiki_pages: table<title: string, parent: record, version: int, created_on: string, updated_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/wiki/index.($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show wiki page
#
# GET /projects/{project_id}/wiki/{wiki_page_title}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_WikiPages#Getting-a-wiki-page
# operationId: getWikiPage
export def "projects-wiki list" [
  format: string
  project_id: string
  wiki_page_title: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Comma-separated list of associated data to include in the response. Values: `attachments` (file attachments)
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<wiki_page: record<title: string, parent: record<title: string>, text: string, version: int, author: record<id: int, name: string>, comments: string, project: record<id: int, name: string>, created_on: string, updated_on: string, attachments: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/wiki/($wiki_page_title).($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update wiki page
#
# PUT /projects/{project_id}/wiki/{wiki_page_title}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_WikiPages#Creating-or-updating-a-wiki-page
# operationId: updateWikiPage
# --wiki_page shape: {text: string, comments?: string, version?: int, parent_title?: string, uploads?: list}
export def "projects-wiki updateWikiPage" [
  format: string
  project_id: string
  wiki_page_title: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  --wiki-page: record # shape: {text: string, comments?: string, version?: int, parent_title?: string, uploads?: list}
]: any -> record<wiki_page: record<title: string, parent: record<title: string>, text: string, version: int, author: record<id: int, name: string>, comments: string, project: record<id: int, name: string>, created_on: string, updated_on: string, attachments: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/wiki/($wiki_page_title).($format)")
  let body = {wiki_page: $wiki_page} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete wiki page
#
# DELETE /projects/{project_id}/wiki/{wiki_page_title}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_WikiPages#Deleting-a-wiki-page
# operationId: deleteWikiPage
export def "projects-wiki delete" [
  format: string
  project_id: string
  wiki_page_title: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/wiki/($wiki_page_title).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show wiki page by specific version
#
# GET /projects/{project_id}/wiki/{wiki_page_title}/{version_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_WikiPages#Getting-an-old-version-of-a-wiki-page
# operationId: getWikiPageByVersion
export def "projects-wiki get" [
  format: string
  project_id: string
  wiki_page_title: string
  version_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Comma-separated list of associated data to include in the response. Values: `attachments` (file attachments)
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<wiki_page: record<title: string, parent: record<title: string>, text: string, version: int, author: record<id: int, name: string>, comments: string, project: record<id: int, name: string>, created_on: string, updated_on: string, attachments: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/wiki/($wiki_page_title)/($version_id).($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List queries
#
# GET /queries.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Queries#GET
# operationId: getQueries
export def "queries-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int
  --limit: int
  --nometa: int@nometa-completer
  --X-Redmine-Switch-User: string # e.g. jsmith
  --X-Redmine-Nometa: int@X-Redmine-Nometa-completer
]: nothing -> record<queries: table<id: int, name: string, is_public: bool, project_id: int>, total_count: int, offset: int, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "nometa" $nometa "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/queries.($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User, "X-Redmine-Nometa": $X_Redmine_Nometa} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show attachment
#
# GET /attachments/{attachment_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Attachments#GET
# operationId: getAttachment
export def "attachments get" [
  format: string
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<attachment: record<id: int, filename: string, filesize: int, content_type: string, description: string, content_url: string, thumbnail_url: string, author: record<id: int, name: string>, created_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/attachments/($attachment_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update attachment
#
# PATCH /attachments/{attachment_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Attachments#PATCH
# operationId: updateAttachment
# --attachment shape: {filename?: string, content_type?: string, description?: string}
export def "attachments updateAttachment" [
  format: string
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  --attachment: record # shape: {filename?: string, content_type?: string, description?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/attachments/($attachment_id).($format)")
  let body = {attachment: $attachment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete attachment
#
# DELETE /attachments/{attachment_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Attachments#DELETE
# operationId: deleteAttachment
export def "attachments delete" [
  format: string
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/attachments/($attachment_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download attachment file
#
# GET /attachments/download/{attachment_id}/{filename}
# operationId: downloadAttachmentFile
export def "attachments-download downloadAttachmentFile" [
  attachment_id: int
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/attachments/download/($attachment_id)/($filename)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download thumbnail
#
# GET /attachments/thumbnail/{attachment_id}
# operationId: downloadThumbnail
export def "attachments-thumbnail downloadThumbnail" [
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --size: int # Desired thumbnail size in pixels (max 800). Rounded up to the nearest 50px increment. If not specified, the configured default thumbnail size is used.
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/attachments/thumbnail/($attachment_id)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List issue statuses
#
# GET /issue_statuses.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_IssueStatuses#GET
# operationId: getIssueStatuses
export def "issue-statuses-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<issue_statuses: table<id: int, name: string, is_closed: bool, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/issue_statuses.($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List trackers
#
# GET /trackers.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Trackers#GET
# operationId: getTrackers
export def "trackers-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<trackers: table<id: int, name: string, default_status: record, description: string, enabled_standard_fields: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/trackers.($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List issue categories
#
# GET /projects/{project_id}/issue_categories.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_IssueCategories#GET
# operationId: getIssueCategories
export def "projects-issue-categories-format get" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nometa: int@nometa-completer
  --X-Redmine-Switch-User: string # e.g. jsmith
  --X-Redmine-Nometa: int@X-Redmine-Nometa-completer
]: nothing -> record<issue_categories: table<id: int, project: record, name: string, assigned_to: record>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nometa" $nometa "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/issue_categories.($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User, "X-Redmine-Nometa": $X_Redmine_Nometa} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create issue category
#
# POST /projects/{project_id}/issue_categories.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_IssueCategories#POST
# operationId: createIssueCategory
# --issue_category shape: {name: string, assigned_to_id?: int}
export def "projects-issue-categories-format createIssueCategory" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  issue_category: record # shape: {name: string, assigned_to_id?: int}
]: any -> record<issue_category: record<id: int, project: record<id: int, name: string>, name: string, assigned_to: record<id: int, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/issue_categories.($format)")
  let body = {issue_category: $issue_category} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List issue priorities
#
# GET /enumerations/issue_priorities.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Enumerations#GET
# operationId: getIssuePriorities
export def "enumerations-issue-priorities-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<issue_priorities: table<id: int, name: string, is_default: bool, active: bool, custom_fields: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enumerations/issue_priorities.($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List time entry activities
#
# GET /enumerations/time_entry_activities.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Enumerations#GET-2
# operationId: getTimeEntryActivities
export def "enumerations-time-entry-activities-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<time_entry_activities: table<id: int, name: string, is_default: bool, active: bool, custom_fields: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enumerations/time_entry_activities.($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List document categories
#
# GET /enumerations/document_categories.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Enumerations#GET-3
# operationId: getDocumentCategories
export def "enumerations-document-categories-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<document_categories: table<id: int, name: string, is_default: bool, active: bool, custom_fields: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enumerations/document_categories.($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show issue category
#
# GET /issue_categories/{issue_category_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_IssueCategories#GET-2
# operationId: getIssueCategory
export def "issue-categories get" [
  format: string
  issue_category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<issue_category: record<id: int, project: record<id: int, name: string>, name: string, assigned_to: record<id: int, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/issue_categories/($issue_category_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update issue category
#
# PUT /issue_categories/{issue_category_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_IssueCategories#PUT
# operationId: updateIssueCategory
# --issue_category shape: {name?: string, assigned_to_id?: int}
export def "issue-categories updateIssueCategory" [
  format: string
  issue_category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  --issue-category: record # shape: {name?: string, assigned_to_id?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/issue_categories/($issue_category_id).($format)")
  let body = {issue_category: $issue_category} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete issue category
#
# DELETE /issue_categories/{issue_category_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_IssueCategories#DELETE
# operationId: deleteIssueCategory
export def "issue-categories delete" [
  format: string
  issue_category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reassign-to-id: int # ID of another issue category to reassign issues to before deleting this category. If the category has associated issues and this parameter is not provided, the issues will have their category unset.
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reassign_to_id" $reassign_to_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/issue_categories/($issue_category_id).($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List roles
#
# GET /roles.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Roles#GET
# operationId: getRoles
export def "roles-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<roles: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/roles.($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show role
#
# GET /roles/{role_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Roles#GET-2
# operationId: getRole
export def "roles get" [
  format: string
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<role: record<id: int, name: string, assignable: bool, issues_visibility: string, time_entries_visibility: string, users_visibility: string, permissions: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/roles/($role_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List groups
#
# GET /groups.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Groups#GET
# operationId: getGroups
export def "groups-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --builtin: string@builtin-completer # Include built-in groups (e.g., "Anonymous", "Non member") in the response. Set to `1` to include built-in groups. Without this parameter, only user-created groups are returned.
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<groups: table<id: int, name: string, builtin: string, custom_fields: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "builtin" $builtin "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups.($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create group
#
# POST /groups.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Groups#POST
# operationId: createGroup
# --group shape: {name?: string, user_ids?: list, twofa_required?: bool, custom_fields?: list, custom_field_values?: record}
export def "groups-format createGroup" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  group: record # shape: {name?: string, user_ids?: list, twofa_required?: bool, custom_fields?: list, custom_field_values?: record}
]: any -> record<group: record<id: int, name: string, builtin: string, custom_fields: list<record>, users: list<record>, memberships: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups.($format)")
  let body = {group: $group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show group
#
# GET /groups/{group_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Groups#GET-2
# operationId: getGroup
export def "groups get" [
  format: string
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Comma-separated list of associated data to include in the response. Values: `users` (list of users in the group), `memberships` (project memberships with roles)
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<group: record<id: int, name: string, builtin: string, custom_fields: list<record>, users: list<record>, memberships: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id).($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update group
#
# PUT /groups/{group_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Groups#PUT
# operationId: updateGroup
# --group shape: {name?: string, user_ids?: list, twofa_required?: bool, custom_fields?: list, custom_field_values?: record}
export def "groups updateGroup" [
  format: string
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  --group: record # shape: {name?: string, user_ids?: list, twofa_required?: bool, custom_fields?: list, custom_field_values?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id).($format)")
  let body = {group: $group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete group
#
# DELETE /groups/{group_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Groups#DELETE
# operationId: deleteGroup
export def "groups delete" [
  format: string
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add user to group
#
# POST /groups/{group_id}/users.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Groups#POST-2
# operationId: addUserToGroup
export def "groups-users-format addUserToGroup" [
  format: string
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  user_id: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/users.($format)")
  let body = {user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove user from group
#
# DELETE /groups/{group_id}/users/{user_id}.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Groups#DELETE-2
# operationId: removeUserFromGroup
export def "groups-users removeUserFromGroup" [
  format: string
  group_id: int
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/users/($user_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List custom fields
#
# GET /custom_fields.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_CustomFields#GET
# operationId: getCustomFields
export def "custom-fields-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<custom_fields: table<id: int, name: string, description: string, customized_type: string, field_format: string, regexp: string, min_length: int, max_length: int, is_required: bool, is_filter: bool, searchable: bool, multiple: bool, default_value: string, visible: bool, editable: bool, trackers: list, roles: list, possible_values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_fields.($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search
#
# GET /search.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Search#GET
# operationId: getSearch
export def "search-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int
  --offset: int
  --nometa: int@nometa-completer
  --q: string # Search query string. Tokenized into words for matching. When `all_words` is enabled (default), all tokens must match. Otherwise, any token can match.
  --scope: string@scope-completer # Search scope. Values: `all` (all projects), `my_projects` (projects where current user is a member), `bookmarks` (bookmarked projects), `subprojects` (include subprojects, only effective for project-scoped search)
  --all-words: string # Require all words to match. Default is `true` (all words must match). Set to empty string to disable (any word matches). Any non-empty value enables this option.
  --titles-only: string # Search titles only. Default is `false`. Any non-empty value enables this option.
  --issues: int@issues-completer # Include issues in search results. Any non-empty value enables this search type. If no search type parameters are specified, all types are searched.
  --news: int@news-completer # Include news in search results. Any non-empty value enables this search type. If no search type parameters are specified, all types are searched.
  --wiki-pages: int@wiki-pages-completer # Include wiki pages in search results. Any non-empty value enables this search type. If no search type parameters are specified, all types are searched.
  --projects: int@projects-completer # Include projects in search results. Any non-empty value enables this search type. If no search type parameters are specified, all types are searched. Not available when searching within a specific project.
  --documents: int@documents-completer # Include documents in search results. Any non-empty value enables this search type. If no search type parameters are specified, all types are searched.
  --changesets: int@changesets-completer # Include changesets in search results. Any non-empty value enables this search type. If no search type parameters are specified, all types are searched.
  --messages: int@messages-completer # Include forum messages in search results. Any non-empty value enables this search type. If no search type parameters are specified, all types are searched.
  --open-issues: string # Only return open issues. Default is `false`. Any non-empty value enables this option.
  --attachments: string@attachments-completer # Search attachments. Default is `0` (do not search attachments). Values: `0` (disabled), `1` (search attachments and content), `only` (search attachments only)
  --X-Redmine-Switch-User: string # e.g. jsmith
  --X-Redmine-Nometa: int@X-Redmine-Nometa-completer
]: nothing -> record<results: table<id: int, title: string, type: string, url: string, description: string, datetime: string>, total_count: int, offset: int, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "nometa" $nometa "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "all_words" $all_words "scalar") (serialize-qp "titles_only" $titles_only "scalar") (serialize-qp "issues" $issues "scalar") (serialize-qp "news" $news "scalar") (serialize-qp "wiki_pages" $wiki_pages "scalar") (serialize-qp "projects" $projects "scalar") (serialize-qp "documents" $documents "scalar") (serialize-qp "changesets" $changesets "scalar") (serialize-qp "messages" $messages "scalar") (serialize-qp "open_issues" $open_issues "scalar") (serialize-qp "attachments" $attachments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search.($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User, "X-Redmine-Nometa": $X_Redmine_Nometa} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search within project
#
# GET /projects/{project_id}/search.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Search#GET
# operationId: getSearchByProject
export def "projects-search-format get" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int
  --offset: int
  --nometa: int@nometa-completer
  --q: string # Search query string. Tokenized into words for matching. When `all_words` is enabled (default), all tokens must match. Otherwise, any token can match.
  --scope: string@scope-completer-1 # Search scope. Values: `subprojects` (include subprojects of the specified project) When not specified, only the specified project is searched.
  --all-words: string # Require all words to match. Default is `true` (all words must match). Set to empty string to disable (any word matches). Any non-empty value enables this option.
  --titles-only: string # Search titles only. Default is `false`. Any non-empty value enables this option.
  --issues: int@issues-completer # Include issues in search results. Any non-empty value enables this search type. If no search type parameters are specified, all types are searched.
  --news: int@news-completer # Include news in search results. Any non-empty value enables this search type. If no search type parameters are specified, all types are searched.
  --wiki-pages: int@wiki-pages-completer # Include wiki pages in search results. Any non-empty value enables this search type. If no search type parameters are specified, all types are searched.
  --documents: int@documents-completer # Include documents in search results. Any non-empty value enables this search type. If no search type parameters are specified, all types are searched.
  --changesets: int@changesets-completer # Include changesets in search results. Any non-empty value enables this search type. If no search type parameters are specified, all types are searched.
  --messages: int@messages-completer # Include forum messages in search results. Any non-empty value enables this search type. If no search type parameters are specified, all types are searched.
  --open-issues: string # Only return open issues. Default is `false`. Any non-empty value enables this option.
  --attachments: string@attachments-completer # Search attachments. Default is `0` (do not search attachments). Values: `0` (disabled), `1` (search attachments and content), `only` (search attachments only)
  --X-Redmine-Switch-User: string # e.g. jsmith
  --X-Redmine-Nometa: int@X-Redmine-Nometa-completer
]: nothing -> record<results: table<id: int, title: string, type: string, url: string, description: string, datetime: string>, total_count: int, offset: int, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "nometa" $nometa "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "all_words" $all_words "scalar") (serialize-qp "titles_only" $titles_only "scalar") (serialize-qp "issues" $issues "scalar") (serialize-qp "news" $news "scalar") (serialize-qp "wiki_pages" $wiki_pages "scalar") (serialize-qp "documents" $documents "scalar") (serialize-qp "changesets" $changesets "scalar") (serialize-qp "messages" $messages "scalar") (serialize-qp "open_issues" $open_issues "scalar") (serialize-qp "attachments" $attachments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/search.($format)" $qp)
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User, "X-Redmine-Nometa": $X_Redmine_Nometa} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List files
#
# GET /projects/{project_id}/files.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Files#GET
# operationId: getFiles
export def "projects-files-format get" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<files: table<id: int, filename: string, filesize: int, content_type: string, description: string, content_url: string, thumbnail_url: string, author: record, created_on: string, version: record, digest: string, downloads: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/files.($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create file
#
# POST /projects/{project_id}/files.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_Files#POST
# operationId: createFile
# --file shape: {token: string, version_id?: int, filename?: string, description?: string, content_type?: string}
export def "projects-files-format createFile" [
  format: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  file: record # shape: {token: string, version_id?: int, filename?: string, description?: string, content_type?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/files.($format)")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show my account
#
# GET /my/account.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_MyAccount#GET
# operationId: getMyAccount
export def "my-account-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> record<user: record<id: int, login: string, admin: bool, firstname: string, lastname: string, mail: string, created_on: string, last_login_on: string, api_key: string, custom_fields: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/my/account.($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update my account
#
# PUT /my/account.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_MyAccount#PUT
# operationId: updateMyAccount
# --user shape: {login?: string, admin?: bool, firstname?: string, lastname?: string, mail?: string, language?: string, auth_source_id?: int, mail_notification?: "all"|"selected"|"only_my_events"|"only_assigned"|"only_owner"|"none", notified_project_ids?: list, must_change_passwd?: bool, generate_password?: bool, status?: int, custom_fields?: list, custom_field_values?: record, group_ids?: list}
# --pref shape: {hide_mail?: bool, time_zone?: string, comments_sorting?: "asc"|"desc", warn_on_leaving_unsaved?: bool, no_self_notified?: bool, notify_about_high_priority_issues?: bool, textarea_font?: "monospace"|"proportional", recently_used_projects?: int, history_default_tab?: "notes"|"history"|"properties"|"time_entries"|"changesets"|"last_tab_visited", toolbar_language_options?: string, default_issue_query?: int, default_project_query?: int, auto_watch_on?: list}
export def "my-account-format updateMyAccount" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  --user: record # shape: {login?: string, admin?: bool, firstname?: string, lastname?: string, mail?: string, language?: string, auth_source_id?: int, mail_notification?: "all"|"selected"|"only_my_events"|"only_assigned"|"only_owner"|"none", notified_project_ids?: list, must_change_passwd?: bool, generate_password?: bool, status?: int, custom_fields?: list, custom_field_values?: record, group_ids?: list}
  --pref: record # shape: {hide_mail?: bool, time_zone?: string, comments_sorting?: "asc"|"desc", warn_on_leaving_unsaved?: bool, no_self_notified?: bool, notify_about_high_priority_issues?: bool, textarea_font?: "monospace"|"proportional", recently_used_projects?: int, history_default_tab?: "notes"|"history"|"properties"|"time_entries"|"changesets"|"last_tab_visited", toolbar_language_options?: string, default_issue_query?: int, default_project_query?: int, auto_watch_on?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/my/account.($format)")
  let body = {user: $user, pref: $pref} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update journal
#
# PUT /journals/{journal_id}.{format}
# operationId: updateJournal
# --journal shape: {notes?: string, private_notes?: bool}
export def "journals updateJournal" [
  format: string
  journal_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  --journal: record # shape: {notes?: string, private_notes?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/journals/($journal_id).($format)")
  let body = {journal: $journal} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload attachment file
#
# POST /uploads.{format}
# Docs: https://www.redmine.org/projects/redmine/wiki/Rest_api#Attaching-files
# operationId: uploadAttachmentFile
export def "uploads-format uploadAttachmentFile" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filename: string # Filename for the uploaded file. If not provided, a random hexadecimal name is generated.
  --content-type: string # MIME type of the file (e.g., `application/pdf`, `image/png`). If not provided, auto-detected from the filename.
  --X-Redmine-Switch-User: string # e.g. jsmith
  --body: record
]: any -> record<upload: record<id: int, token: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filename" $filename "scalar") (serialize-qp "content_type" $content_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/uploads.($format)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/octet-stream" $body
}

# Add related issue
#
# POST /projects/{project_id}/repository/{repository_id}/revisions/{revision}/issues.{format}
# operationId: addRelatedIssue
export def "projects-repository-revisions-issues-format addRelatedIssue" [
  format: string
  project_id: string
  repository_id: string
  revision: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
  issue_id: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/repository/($repository_id)/revisions/($revision)/issues.($format)")
  let body = {issue_id: $issue_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove related issue
#
# DELETE /projects/{project_id}/repository/{repository_id}/revisions/{revision}/issues/{issue_id}.{format}
# operationId: removeRelatedIssue
export def "projects-repository-revisions-issues removeRelatedIssue" [
  format: string
  project_id: string
  repository_id: string
  revision: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Redmine-Switch-User: string # e.g. jsmith
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/repository/($repository_id)/revisions/($revision)/issues/($issue_id).($format)")
  let extra_headers = {"X-Redmine-Switch-User": $X_Redmine_Switch_User} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
