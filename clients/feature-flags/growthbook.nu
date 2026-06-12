# Auto-generated client for GrowthBook REST API v1.0.0
# Source: https://raw.githubusercontent.com/growthbook/growthbook/main/packages/back-end/generated/spec.yaml
# Auth: --token flag or $env.GROWTHBOOK_REST_API_TOKEN

const BASE_URL = "https://api.growthbook.io/api"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GROWTHBOOK_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://api.growthbook.io/api" "https://{domain}/api"] }
def auth-scheme-completer [] { ["bearer" "basic"] }

# Completers for enum parameters
def valueType-completer [] { ["boolean" "json" "number" "string"] }
def withRevisions-completer [] { ["all" "drafts" "none" "published"] }
def action-completer [] { ["approve" "comment" "request-changes"] }
def strategy-completer [] { ["draft" "publish"] }
def status-completer [] { ["draft" "running" "stopped"] }
def type-completer [] { ["multi-armed-bandit" "standard"] }
def inProgressConversions-completer [] { ["loose" "strict"] }
def attributionModel-completer [] { ["experimentDuration" "firstExposure" "lookbackOverride"] }
def statsEngine-completer [] { ["bayesian" "frequentist"] }
def shareLevel-completer [] { ["organization" "public"] }
def banditScheduleUnit-completer [] { ["days" "hours"] }
def banditBurnInUnit-completer [] { ["days" "hours"] }
def banditConversionWindowUnit-completer [] { ["days" "hours"] }
def results-completer [] { ["dnf" "inconclusive" "lost" "won"] }
def triggeredBy-completer [] { ["manual" "schedule"] }
def contentType-completer [] { ["image/gif" "image/jpeg" "image/png"] }
def managedBy-completer [] { ["" "api"] }
def type-completer-1 [] { ["binomial" "count" "duration" "revenue"] }
def managedBy-completer-1 [] { ["" "admin" "api"] }
def type-completer-2 [] { ["FACT" "SQL"] }
def datatype-completer [] { ["boolean" "enum" "number" "number[]" "secureString" "secureString[]" "string" "string[]"] }
def format-completer [] { ["" "date" "isoCountryCode" "version"] }
def type-completer-3 [] { ["condition" "list"] }
def decision-completer [] { ["approve" "comment" "request-changes"] }
def metricType-completer [] { ["dailyParticipation" "mean" "proportion" "quantile" "ratio" "retention"] }
def populationType-completer [] { ["factTable" "segment"] }
def deleteMissing-completer [] { ["false" "true"] }
def status-completer-1 [] { ["completed" "paused" "pending" "ready" "rolled-back" "running"] }
def experimentHealthAction-completer [] { ["hold" "rollback" "warn"] }
def monitoringMode-completer [] { ["auto" "manual"] }
def srmAction-completer [] { ["hold" "rollback" "warn"] }
def noTrafficAction-completer [] { ["hold" "rollback" "warn"] }
def multipleExposureAction-completer [] { ["hold" "rollback" "warn"] }
def mode-completer [] { ["locked" "none"] }
def differenceType-completer [] { ["absolute" "relative" "scaled"] }
def shareLevel-completer-1 [] { ["organization" "private" "public"] }
def status-completer-2 [] { ["private" "published"] }
def editLevel-completer [] { ["organization" "private"] }
def status-completer-3 [] { ["active" "inactive"] }
def format-completer-1 [] { ["legacy" "multiRange"] }
def mode-completer-1 [] { ["concise" "energetic" "humorous"] }
def contentType-completer-1 [] { ["image/gif" "image/jpeg" "image/png" "image/webp"] }
def editLevel-completer-1 [] { ["private" "published"] }
def shareLevel-completer-2 [] { ["private" "published"] }
def type-completer-4 [] { ["boolean" "date" "datetime" "enum" "markdown" "multiselect" "number" "text" "textarea" "url"] }
def type-completer-5 [] { ["standard"] }
def cache-completer [] { ["never" "preferred" "required"] }
def chartType-completer [] { ["area" "bar" "bigNumber" "horizontalBar" "line" "stackedBar" "stackedHorizontalBar" "table" "timeseries-table"] }
def showAs-completer [] { ["per_unit" "total"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "features listFeatures" } } | get name | first)
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

# Get all features
#
# GET /v1/features
# DEPRECATED
# operationId: listFeatures
@deprecated
export def "features listFeatures" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --projectId: string # Filter by project id
  --clientKey: string # Filter by a SDK connection's client key
  --skipPagination: string # If true, return all matching items and ignore limit/offset. Self-hosted only. Has no effect unless API_ALLOW_SKIP_PAGINATION is set to true or 1. (default: false)
]: nothing -> record<features: table<id: string, dateCreated: string, dateUpdated: string, archived: bool, description: string, owner: string, ownerEmail: string, project: string, valueType: string, defaultValue: string, tags: list, environments: record, prerequisites: list, revision: record, customFields: record, holdout: any>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "skipPagination" $skipPagination "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/features" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single feature
#
# POST /v1/features
# DEPRECATED
# operationId: postFeature
@deprecated
export def "features post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # A unique key name for the feature. Feature keys can only include letters, numbers, hyphens, and underscores.
  --archived: oneof<nothing, bool>
  --description: string # Description of the feature
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization. When omitted, it defaults to the user associated with the request's Personal Access Token (PAT), if one is being used.
  --project: string # An associated project ID
  valueType: string@valueType-completer # The data type of the feature payload. Boolean by default.
  defaultValue: string # Default value when feature is enabled. Type must match `valueType`.
  --tags: list # List of associated tags
  --environments: record # A dictionary of environments that are enabled for this feature. Keys supply the names of environments. Environments belong to organization and are not specified will be disabled by default.
  --prerequisites: list # Feature IDs. Each feature must evaluate to `true`
  --jsonSchema: string # Use JSON schema to validate the payload of a JSON-type feature value (enterprise only).
  --customFields: record
]: any -> record<feature: record<id: string, dateCreated: string, dateUpdated: string, archived: bool, description: string, owner: string, ownerEmail: string, project: string, valueType: string, defaultValue: string, tags: list<string>, environments: record, prerequisites: list<string>, revision: record<version: int, comment: string, date: string, createdBy: string, publishedBy: string>, customFields: record, holdout: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/features")
  let body = {id: $id, archived: $archived, description: $description, owner: $owner, project: $project, valueType: $valueType, defaultValue: $defaultValue, tags: $tags, environments: $environments, prerequisites: $prerequisites, jsonSchema: $jsonSchema, customFields: $customFields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single feature
#
# GET /v1/features/{id}
# DEPRECATED
# operationId: getFeature
@deprecated
export def "features get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --withRevisions: string@withRevisions-completer # Also return feature revisions (all, draft, or published statuses)
]: nothing -> record<feature: record<id: string, dateCreated: string, dateUpdated: string, archived: bool, description: string, owner: string, ownerEmail: string, project: string, valueType: string, defaultValue: string, tags: list<string>, environments: record, prerequisites: list<string>, revision: record<version: int, comment: string, date: string, createdBy: string, publishedBy: string>, customFields: record, holdout: any, revisions: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withRevisions" $withRevisions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/features/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Partially update a feature
#
# POST /v1/features/{id}
# DEPRECATED
# operationId: updateFeature
@deprecated
export def "features updateFeature" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the feature
  --archived: oneof<nothing, bool>
  --project: string # An associated project ID
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization.
  --defaultValue: string
  --tags: list # List of associated tags. Will override tags completely with submitted list
  --environments: record
  --prerequisites: list # Feature IDs. Each feature must evaluate to `true`
  --jsonSchema: string # Use JSON schema to validate the payload of a JSON-type feature value (enterprise only).
  --customFields: record
  --holdout: any # Holdout to assign this feature to. Pass `null` to remove the feature from its current holdout. Omit the field entirely to leave the holdout unchanged.
]: any -> record<feature: record<id: string, dateCreated: string, dateUpdated: string, archived: bool, description: string, owner: string, ownerEmail: string, project: string, valueType: string, defaultValue: string, tags: list<string>, environments: record, prerequisites: list<string>, revision: record<version: int, comment: string, date: string, createdBy: string, publishedBy: string>, customFields: record, holdout: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)")
  let body = {description: $description, archived: $archived, project: $project, owner: $owner, defaultValue: $defaultValue, tags: $tags, environments: $environments, prerequisites: $prerequisites, jsonSchema: $jsonSchema, customFields: $customFields, holdout: $holdout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a single feature
#
# DELETE /v1/features/{id}
# DEPRECATED
# operationId: deleteFeature
@deprecated
export def "features delete-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Toggle a feature in one or more environments
#
# POST /v1/features/{id}/toggle
# DEPRECATED
# operationId: toggleFeature
@deprecated
export def "features-toggle toggleFeature" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string
  environments: record
]: any -> record<feature: record<id: string, dateCreated: string, dateUpdated: string, archived: bool, description: string, owner: string, ownerEmail: string, project: string, valueType: string, defaultValue: string, tags: list<string>, environments: record, prerequisites: list<string>, revision: record<version: int, comment: string, date: string, createdBy: string, publishedBy: string>, customFields: record, holdout: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/toggle")
  let body = {reason: $reason, environments: $environments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revert a feature to a specific revision
#
# POST /v1/features/{id}/revert
# DEPRECATED
# operationId: revertFeature
@deprecated
export def "features-revert revertFeature" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  revision: float
  --comment: string
]: any -> record<feature: record<id: string, dateCreated: string, dateUpdated: string, archived: bool, description: string, owner: string, ownerEmail: string, project: string, valueType: string, defaultValue: string, tags: list<string>, environments: record, prerequisites: list<string>, revision: record<version: int, comment: string, date: string, createdBy: string, publishedBy: string>, customFields: record, holdout: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revert")
  let body = {revision: $revision, comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get list of feature keys
#
# GET /v1/feature-keys
# DEPRECATED
# operationId: getFeatureKeys
@deprecated
export def "feature-keys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --projectId: string # Filter by project id
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/feature-keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get stale status for one or more features
#
# GET /v1/stale-features
# DEPRECATED
# operationId: getFeatureStale
@deprecated
export def "stale-features get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # Comma-separated list of feature IDs (URL-encoded if needed). Example: `my_feature,another_feature`
]: nothing -> record<features: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/stale-features" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List feature revisions
#
# GET /v1/revisions
# DEPRECATED
# operationId: listRevisions
@deprecated
export def "revisions listRevisions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --skipPagination: string # If true, return all matching items and ignore limit/offset. Self-hosted only. Has no effect unless API_ALLOW_SKIP_PAGINATION is set to true or 1. (default: false)
  --featureId: string
  --status: string # Filter by revision status. Single value, comma-separated list, repeated params (?status=draft&status=approved), or `all-drafts` shorthand for all active-draft statuses (draft, pending-review, approved, changes-requested).
  --author: string
  --mine: string # If true, return only revisions authored by or contributed to by the calling user. Requires a user-scoped API key. Mutually exclusive with `author`.
]: nothing -> record<revisions: table<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list, metadata: record, rampActions: list>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "skipPagination" $skipPagination "scalar") (serialize-qp "featureId" $featureId "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "mine" $mine "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/revisions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List revisions for a feature
#
# GET /v1/features/{id}/revisions
# DEPRECATED
# operationId: getFeatureRevisions
@deprecated
export def "features-revisions get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --skipPagination: string # If true, return all matching items and ignore limit/offset. Self-hosted only. Has no effect unless API_ALLOW_SKIP_PAGINATION is set to true or 1. (default: false)
  --status: string # Filter by revision status. Single value, comma-separated list, repeated params (?status=draft&status=approved), or `all-drafts` shorthand for all active-draft statuses (draft, pending-review, approved, changes-requested).
  --author: string
]: nothing -> record<revisions: table<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list, metadata: record, rampActions: list>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "skipPagination" $skipPagination "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "author" $author "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/features/($id)/revisions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a draft revision
#
# POST /v1/features/{id}/revisions
# DEPRECATED
# operationId: postFeatureRevision
@deprecated
export def "features-revisions post-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  --title: string
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions")
  let body = {comment: $comment, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the most recent active draft revision
#
# GET /v1/features/{id}/revisions/latest
# DEPRECATED
# operationId: getFeatureRevisionLatest
@deprecated
export def "features-revisions-latest get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mine: string # If true, return only the most recent active draft authored by or contributed to by the calling user. Requires a user-scoped API key.
]: nothing -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mine" $mine "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/features/($id)/revisions/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single feature revision
#
# GET /v1/features/{id}/revisions/{version}
# DEPRECATED
# operationId: getFeatureRevision
@deprecated
export def "features-revisions get-by-id-version" [
  id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update revision metadata (comment, title, feature metadata)
#
# PUT /v1/features/{id}/revisions/{version}/metadata
# DEPRECATED
# operationId: putFeatureRevisionMetadata
# --jsonSchema shape: {schemaType: "schema"|"simple", schema: string, simple: record, date: any, enabled: bool}
@deprecated
export def "features-revisions-metadata put-by-id-version" [
  id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  --title: string
  --description: string
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization.
  --project: string
  --tags: list
  --neverStale: oneof<nothing, bool>
  --customFields: record
  --jsonSchema: record # shape: {schemaType: "schema"|"simple", schema: string, simple: record, date: any, enabled: bool}
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)/metadata")
  let body = {comment: $comment, title: $title, description: $description, owner: $owner, project: $project, tags: $tags, neverStale: $neverStale, customFields: $customFields, jsonSchema: $jsonSchema} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set the default value in a draft revision
#
# PUT /v1/features/{id}/revisions/{version}/default-value
# DEPRECATED
# operationId: putFeatureRevisionDefaultValue
@deprecated
export def "features-revisions-default-value put-by-id-version" [
  id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  defaultValue: string
  --revisionTitle: string
  --revisionComment: string
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)/default-value")
  let body = {defaultValue: $defaultValue, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set feature-level prerequisites in a draft revision
#
# PUT /v1/features/{id}/revisions/{version}/prerequisites
# DEPRECATED
# operationId: putFeatureRevisionPrerequisites
# --prerequisites item shape: {id: string, condition: string}
@deprecated
export def "features-revisions-prerequisites put-by-id-version" [
  id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  prerequisites: list # item shape: {id: string, condition: string}
  --revisionTitle: string
  --revisionComment: string
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)/prerequisites")
  let body = {prerequisites: $prerequisites, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set holdout in a draft revision
#
# PUT /v1/features/{id}/revisions/{version}/holdout
# DEPRECATED
# operationId: putFeatureRevisionHoldout
@deprecated
export def "features-revisions-holdout put-by-id-version" [
  id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  holdout: any
  --revisionTitle: string
  --revisionComment: string
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)/holdout")
  let body = {holdout: $holdout, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set archived state in a draft revision
#
# PUT /v1/features/{id}/revisions/{version}/archive
# DEPRECATED
# operationId: putFeatureRevisionArchive
@deprecated
export def "features-revisions-archive put-by-id-version" [
  id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --archived: oneof<nothing, bool>
  --revisionTitle: string
  --revisionComment: string
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)/archive")
  let body = {archived: $archived, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Toggle an environment on/off in a draft revision
#
# POST /v1/features/{id}/revisions/{version}/toggle
# DEPRECATED
# operationId: postFeatureRevisionToggle
@deprecated
export def "features-revisions-toggle post-by-id-version" [
  id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  environment: string
  --enabled: oneof<nothing, bool>
  --revisionTitle: string
  --revisionComment: string
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)/toggle")
  let body = {environment: $environment, enabled: $enabled, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a rule to a draft revision
#
# POST /v1/features/{id}/revisions/{version}/rules
# DEPRECATED
# operationId: postFeatureRevisionRuleAdd
# --rampSchedule shape: {name?: string, templateId?: string, startActions?: list, steps?: list, endActions?: list, startDate?: any, cutoffDate?: any, monitoringConfig?: record, lockdownConfig?: record}
# --schedule shape: {startDate?: any, endDate?: any}
@deprecated
export def "features-revisions-rules post-by-id-version" [
  id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  environment: string
  rule: any
  --rampSchedule: record # shape: {name?: string, templateId?: string, startActions?: list, steps?: list, endActions?: list, startDate?: any, cutoffDate?: any, monitoringConfig?: record, lockdownConfig?: record}
  --schedule: record # shape: {startDate?: any, endDate?: any}
  --revisionTitle: string
  --revisionComment: string
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)/rules")
  let body = {environment: $environment, rule: $rule, rampSchedule: $rampSchedule, schedule: $schedule, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a rule in a draft revision
#
# PUT /v1/features/{id}/revisions/{version}/rules/{ruleId}
# DEPRECATED
# operationId: putFeatureRevisionRule
# --rule shape: {description?: string, enabled?: bool, condition?: string, savedGroups?: list, prerequisites?: list, scheduleRules?: any, scheduleType?: any, type?: "force"|"rollout"|"experiment-ref"|"safe-rollout", value?: string, coverage?: float, hashAttribute?: string, seed?: string, hashVersion?: any, experimentId?: string, variations?: list, controlValue?: string, variationValue?: string}
# --rampSchedule shape: {name?: string, templateId?: string, startActions?: list, steps?: list, endActions?: list, startDate?: any, cutoffDate?: any, monitoringConfig?: record, lockdownConfig?: record}
# --schedule shape: {startDate?: any, endDate?: any}
@deprecated
export def "features-revisions-rules put-by-id-version-ruleId" [
  id: string
  version: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  environment: string
  rule: record # shape: {description?: string, enabled?: bool, condition?: string, savedGroups?: list, prerequisites?: list, scheduleRules?: any, scheduleType?: any, type?: "force"|"rollout"|"experiment-ref"|"safe-rollout", value?: string, coverage?: float, hashAttribute?: string, seed?: string, hashVersion?: any, experimentId?: string, variations?: list, controlValue?: string, variationValue?: string}
  --rampSchedule: record # shape: {name?: string, templateId?: string, startActions?: list, steps?: list, endActions?: list, startDate?: any, cutoffDate?: any, monitoringConfig?: record, lockdownConfig?: record}
  --schedule: record # shape: {startDate?: any, endDate?: any}
  --revisionTitle: string
  --revisionComment: string
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)/rules/($ruleId)")
  let body = {environment: $environment, rule: $rule, rampSchedule: $rampSchedule, schedule: $schedule, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a rule from a draft revision
#
# DELETE /v1/features/{id}/revisions/{version}/rules/{ruleId}
# DEPRECATED
# operationId: deleteFeatureRevisionRule
@deprecated
export def "features-revisions-rules delete-by-id-version-ruleId" [
  id: string
  version: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  environment: string
  --revisionTitle: string
  --revisionComment: string
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)/rules/($ruleId)")
  let body = {environment: $environment, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reorder rules in an environment
#
# POST /v1/features/{id}/revisions/{version}/rules/reorder
# DEPRECATED
# operationId: postFeatureRevisionRulesReorder
@deprecated
export def "features-revisions-rules-reorder post-by-id-version" [
  id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  environment: string
  ruleIds: list
  --revisionTitle: string
  --revisionComment: string
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)/rules/reorder")
  let body = {environment: $environment, ruleIds: $ruleIds, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set ramp schedule for a rule
#
# PUT /v1/features/{id}/revisions/{version}/rules/{ruleId}/ramp-schedule
# DEPRECATED
# operationId: putFeatureRevisionRuleRampSchedule
# --startActions item shape: {targetType?: string, targetId?: string, patch: record}
# --steps item shape: {interval: any, actions?: list, approvalNotes?: any, monitored?: bool, holdConditions?: record}
# --endActions item shape: {targetType?: string, targetId?: string, patch: record}
# --monitoringConfig shape: {datasourceId: string, exposureQueryId: string, guardrailMetricIds: list, signalMetricIds?: list, updateScheduleMinutes?: any, monitoringMode?: "auto"|"manual", autoUpdate?: bool, srmAction?: "rollback"|"hold"|"warn", noTrafficAction?: "rollback"|"hold"|"warn", noTrafficGracePeriodHours?: any, multipleExposureAction?: "rollback"|"hold"|"warn"}
# --lockdownConfig shape: {mode: "none"|"locked"}
@deprecated
@deprecated --flag environment
export def "features-revisions-rules-ramp-schedule put-by-id-version-ruleId" [
  id: string
  version: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --templateId: string
  --startActions: list # item shape: {targetType?: string, targetId?: string, patch: record}
  --steps: list # item shape: {interval: any, actions?: list, approvalNotes?: any, monitored?: bool, holdConditions?: record}
  --endActions: list # item shape: {targetType?: string, targetId?: string, patch: record}
  --startDate: any # ISO 8601 date-time, e.g. "2025-06-01T00:00:00Z". Absent or null means start immediately on publish.
  --cutoffDate: any # ISO 8601 date-time, e.g. "2025-07-01T00:00:00Z". The ramp ends at this time.
  --monitoringConfig: record # shape: {datasourceId: string, exposureQueryId: string, guardrailMetricIds: list, signalMetricIds?: list, updateScheduleMinutes?: any, monitoringMode?: "auto"|"manual", autoUpdate?: bool, srmAction?: "rollback"|"hold"|"warn", noTrafficAction?: "rollback"|"hold"|"warn", noTrafficGracePeriodHours?: any, multipleExposureAction?: "rollback"|"hold"|"warn"}
  --lockdownConfig: record # shape: {mode: "none"|"locked"}
  --environment: string # DEPRECATED
  --revisionTitle: string
  --revisionComment: string
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)/rules/($ruleId)/ramp-schedule")
  let body = {name: $name, templateId: $templateId, startActions: $startActions, steps: $steps, endActions: $endActions, startDate: $startDate, cutoffDate: $cutoffDate, monitoringConfig: $monitoringConfig, lockdownConfig: $lockdownConfig, environment: $environment, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove ramp schedule from a rule
#
# DELETE /v1/features/{id}/revisions/{version}/rules/{ruleId}/ramp-schedule
# DEPRECATED
# operationId: deleteFeatureRevisionRuleRampSchedule
@deprecated
@deprecated --flag environment
export def "features-revisions-rules-ramp-schedule delete-by-id-version-ruleId" [
  id: string
  version: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment: string # DEPRECATED
  --revisionTitle: string
  --revisionComment: string
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)/rules/($ruleId)/ramp-schedule")
  let body = {environment: $environment, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request review for a draft revision
#
# POST /v1/features/{id}/revisions/{version}/request-review
# DEPRECATED
# operationId: postFeatureRevisionRequestReview
@deprecated
export def "features-revisions-request-review post-by-id-version" [
  id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)/request-review")
  let body = {comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Submit a review on a draft revision
#
# POST /v1/features/{id}/revisions/{version}/submit-review
# DEPRECATED
# operationId: postFeatureRevisionSubmitReview
@deprecated
export def "features-revisions-submit-review post-by-id-version" [
  id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  --action: string@action-completer
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)/submit-review")
  let body = {comment: $comment, action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get merge status for a draft revision
#
# GET /v1/features/{id}/revisions/{version}/merge-status
# DEPRECATED
# operationId: getFeatureRevisionMergeStatus
@deprecated
export def "features-revisions-merge-status get-by-id-version" [
  id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool, conflicts: table<name: string, key: string, resolved: bool, base: string, live: string, revision: string>, result: record<defaultValue: string, rules: list<any>, environmentsEnabled: record, prerequisites: list<record>, archived: bool, metadata: record<releaseType: string, riskLevel: string>, holdout: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)/merge-status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rebase a draft revision onto the current live version
#
# POST /v1/features/{id}/revisions/{version}/rebase
# DEPRECATED
# operationId: postFeatureRevisionRebase
@deprecated
export def "features-revisions-rebase post-by-id-version" [
  id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conflictResolutions: record
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)/rebase")
  let body = {conflictResolutions: $conflictResolutions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Publish a draft revision
#
# POST /v1/features/{id}/revisions/{version}/publish
# DEPRECATED
# operationId: postFeatureRevisionPublish
@deprecated
export def "features-revisions-publish post-by-id-version" [
  id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)/publish")
  let body = {comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Discard a draft revision
#
# POST /v1/features/{id}/revisions/{version}/discard
# DEPRECATED
# operationId: postFeatureRevisionDiscard
@deprecated
export def "features-revisions-discard post-by-id-version" [
  id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)/discard")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revert the feature to a prior revision
#
# POST /v1/features/{id}/revisions/{version}/revert
# DEPRECATED
# operationId: postFeatureRevisionRevert
@deprecated
export def "features-revisions-revert post-by-id-version" [
  id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --strategy: string@strategy-completer
  --comment: string
  --title: string
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: string, publishedBy: string, defaultValue: string, rules: record, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/features/($id)/revisions/($version)/revert")
  let body = {strategy: $strategy, comment: $comment, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all features
#
# GET /v2/features
# operationId: listFeaturesV2
export def "features listFeaturesV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --projectId: string # Filter by project id
  --clientKey: string # Filter by a SDK connection's client key
  --archived: string # Whether to include archived features. Defaults to `false` (non-archived only). Pass `true` to include archived features alongside non-archived ones.
  --skipPagination: string # If true, return all matching items and ignore limit/offset. Self-hosted only. Has no effect unless API_ALLOW_SKIP_PAGINATION is set to true or 1. (default: false)
]: nothing -> record<features: table<id: string, dateCreated: string, dateUpdated: string, archived: bool, description: string, owner: string, project: string, valueType: string, defaultValue: string, tags: list, rules: list, environments: record, prerequisites: list, revision: record, customFields: record, holdout: any>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "skipPagination" $skipPagination "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/features" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single feature
#
# POST /v2/features
# operationId: postFeatureV2
export def "features post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # A unique key name for the feature. Feature keys can only include letters, numbers, hyphens, and underscores.
  --archived: oneof<nothing, bool>
  --description: string # Description of the feature
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization. When omitted, it defaults to the user associated with the request's Personal Access Token (PAT), if one is being used.
  --project: string # An associated project ID
  valueType: string@valueType-completer # The data type of the feature payload. Boolean by default.
  defaultValue: string # Default value when feature is enabled. Type must match `valueType`.
  --tags: list # List of associated tags
  --rules: list # Feature rules. Each rule carries its own environment scope via `allEnvironments` / `environments`.
  --environments: record # Per-environment enabled state. V2 rules are specified on the top-level `rules` field.
  --prerequisites: list # Feature IDs. Each feature must evaluate to `true`
  --jsonSchema: string # Use JSON schema to validate the payload of a JSON-type feature value (enterprise only).
  --customFields: record
]: any -> record<feature: record<id: string, dateCreated: string, dateUpdated: string, archived: bool, description: string, owner: string, project: string, valueType: string, defaultValue: string, tags: list<string>, rules: list<record>, environments: record, prerequisites: list<string>, revision: record<version: int, comment: string, date: string, createdBy: record, publishedBy: record>, customFields: record, holdout: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/features")
  let body = {id: $id, archived: $archived, description: $description, owner: $owner, project: $project, valueType: $valueType, defaultValue: $defaultValue, tags: $tags, rules: $rules, environments: $environments, prerequisites: $prerequisites, jsonSchema: $jsonSchema, customFields: $customFields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single feature
#
# GET /v2/features/{id}
# operationId: getFeatureV2
export def "features get-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --withRevisions: string@withRevisions-completer # Also return feature revisions (all, draft, or published statuses)
]: nothing -> record<feature: record<id: string, dateCreated: string, dateUpdated: string, archived: bool, description: string, owner: string, project: string, valueType: string, defaultValue: string, tags: list<string>, rules: list<record>, environments: record, prerequisites: list<string>, revision: record<version: int, comment: string, date: string, createdBy: record, publishedBy: record>, customFields: record, holdout: any, revisions: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withRevisions" $withRevisions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/features/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Partially update a feature
#
# POST /v2/features/{id}
# operationId: updateFeatureV2
export def "features updateFeatureV2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the feature
  --archived: oneof<nothing, bool>
  --project: string # An associated project ID
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization.
  --defaultValue: string
  --tags: list # List of associated tags. Will override tags completely with submitted list
  --rules: list # Replaces all feature rules atomically. Behavior differs from v1: v1 PUT applies per-environment patches, v2 PUT swaps the entire `rules` array in one revision. To preserve existing rules during a partial edit, GET the feature first, mutate the returned `rules` array, and PUT the full array back. Safe-rollout rules round-trip via their `safeRolloutId` (creation requires `POST /v2/features/:id/revisions/:version/rules`).
  --environments: record # Per-environment enabled state. V2 rules are specified on the top-level `rules` field.
  --prerequisites: list # Feature IDs. Each feature must evaluate to `true`
  --jsonSchema: string # Use JSON schema to validate the payload of a JSON-type feature value (enterprise only).
  --customFields: record
  --holdout: any # Holdout to assign this feature to. Pass `null` to remove the feature from its current holdout. Omit the field entirely to leave the holdout unchanged.
]: any -> record<feature: record<id: string, dateCreated: string, dateUpdated: string, archived: bool, description: string, owner: string, project: string, valueType: string, defaultValue: string, tags: list<string>, rules: list<record>, environments: record, prerequisites: list<string>, revision: record<version: int, comment: string, date: string, createdBy: record, publishedBy: record>, customFields: record, holdout: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)")
  let body = {description: $description, archived: $archived, project: $project, owner: $owner, defaultValue: $defaultValue, tags: $tags, rules: $rules, environments: $environments, prerequisites: $prerequisites, jsonSchema: $jsonSchema, customFields: $customFields, holdout: $holdout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a single feature
#
# DELETE /v2/features/{id}
# operationId: deleteFeatureV2
export def "features delete-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Toggle a feature in one or more environments
#
# POST /v2/features/{id}/toggle
# operationId: toggleFeatureV2
export def "features-toggle toggleFeatureV2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string
  environments: record
]: any -> record<feature: record<id: string, dateCreated: string, dateUpdated: string, archived: bool, description: string, owner: string, project: string, valueType: string, defaultValue: string, tags: list<string>, rules: list<record>, environments: record, prerequisites: list<string>, revision: record<version: int, comment: string, date: string, createdBy: record, publishedBy: record>, customFields: record, holdout: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/toggle")
  let body = {reason: $reason, environments: $environments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revert a feature to a specific revision
#
# POST /v2/features/{id}/revert
# operationId: revertFeatureV2
export def "features-revert revertFeatureV2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  revision: float
  --comment: string
]: any -> record<feature: record<id: string, dateCreated: string, dateUpdated: string, archived: bool, description: string, owner: string, project: string, valueType: string, defaultValue: string, tags: list<string>, rules: list<record>, environments: record, prerequisites: list<string>, revision: record<version: int, comment: string, date: string, createdBy: record, publishedBy: record>, customFields: record, holdout: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revert")
  let body = {revision: $revision, comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get list of feature keys
#
# GET /v2/feature-keys
# operationId: getFeatureKeysV2
export def "feature-keys get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --projectId: string # Filter by project id
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/feature-keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get stale status for one or more features
#
# GET /v2/stale-features
# operationId: getFeatureStaleV2
export def "stale-features get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # Comma-separated list of feature IDs (URL-encoded if needed). Example: `my_feature,another_feature`
]: nothing -> record<features: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/stale-features" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List revisions across all features
#
# GET /v2/feature-revisions
# operationId: listRevisionsV2
export def "feature-revisions listRevisionsV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --skipPagination: string # If true, return all matching items and ignore limit/offset. Self-hosted only. Has no effect unless API_ALLOW_SKIP_PAGINATION is set to true or 1. (default: false)
  --featureId: string
  --status: string # Filter by revision status. Single value, comma-separated list, repeated params (?status=draft&status=approved), or `all-drafts` shorthand for all active-draft statuses (draft, pending-review, approved, changes-requested).
  --author: string
  --mine: string # If true, return only revisions authored by or contributed to by the calling user.
  --archived: string # Whether to include revisions for archived features. Defaults to `false` (non-archived features only). Pass `true` to include revisions for archived features alongside non-archived ones.
]: nothing -> record<revisions: table<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record, publishedBy: record, defaultValue: string, rules: list, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list, metadata: record, rampActions: list>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "skipPagination" $skipPagination "scalar") (serialize-qp "featureId" $featureId "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "mine" $mine "scalar") (serialize-qp "archived" $archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/feature-revisions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List revisions for a feature
#
# GET /v2/features/{id}/revisions
# operationId: getFeatureRevisionsV2
export def "features-revisions get-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --skipPagination: string # If true, return all matching items and ignore limit/offset. Self-hosted only. Has no effect unless API_ALLOW_SKIP_PAGINATION is set to true or 1. (default: false)
  --status: string # Filter by revision status. Single value, comma-separated list, repeated params (?status=draft&status=approved), or `all-drafts` shorthand for all active-draft statuses (draft, pending-review, approved, changes-requested).
  --author: string
  --mine: string # If true, return only revisions authored by or contributed to by the calling user. Requires a user-scoped API key. Mutually exclusive with `author`.
]: nothing -> record<revisions: table<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record, publishedBy: record, defaultValue: string, rules: list, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list, metadata: record, rampActions: list>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "skipPagination" $skipPagination "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "mine" $mine "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/features/($id)/revisions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a draft revision
#
# POST /v2/features/{id}/revisions
# operationId: postFeatureRevisionV2
export def "features-revisions post-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  --title: string
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions")
  let body = {comment: $comment, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the most recent active draft revision
#
# GET /v2/features/{id}/revisions/latest
# operationId: getFeatureRevisionLatestV2
export def "features-revisions-latest get-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mine: string # If true, return only the most recent active draft authored by or contributed to by the calling user.
  --status: string # Filter by revision status. Single value, comma-separated list, repeated params (?status=draft&status=approved), or `all-drafts` shorthand for all active-draft statuses (draft, pending-review, approved, changes-requested).
  --author: string # Filter to drafts created by this user (userId).
]: nothing -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mine" $mine "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "author" $author "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/features/($id)/revisions/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single feature revision
#
# GET /v2/features/{id}/revisions/{version}
# operationId: getFeatureRevisionV2
export def "features-revisions get-by-id-version-1" [
  id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update revision metadata
#
# PUT /v2/features/{id}/revisions/{version}/metadata
# operationId: putFeatureRevisionMetadataV2
# --jsonSchema shape: {schemaType: "schema"|"simple", schema: string, simple: record, date: any, enabled: bool}
export def "features-revisions-metadata put-by-id-version-1" [
  id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  --title: string
  --description: string
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization.
  --project: string
  --tags: list
  --neverStale: oneof<nothing, bool>
  --customFields: record
  --jsonSchema: record # shape: {schemaType: "schema"|"simple", schema: string, simple: record, date: any, enabled: bool}
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)/metadata")
  let body = {comment: $comment, title: $title, description: $description, owner: $owner, project: $project, tags: $tags, neverStale: $neverStale, customFields: $customFields, jsonSchema: $jsonSchema} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set the default value in a draft revision
#
# PUT /v2/features/{id}/revisions/{version}/default-value
# operationId: putFeatureRevisionDefaultValueV2
export def "features-revisions-default-value put-by-id-version-1" [
  id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  defaultValue: string
  --revisionTitle: string # Title for a newly created draft. Only used when version is "new"; ignored for existing revisions.
  --revisionComment: string # Comment for a newly created draft. Only used when version is "new"; ignored for existing revisions.
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)/default-value")
  let body = {defaultValue: $defaultValue, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set feature-level prerequisites in a draft revision
#
# PUT /v2/features/{id}/revisions/{version}/prerequisites
# operationId: putFeatureRevisionPrerequisitesV2
# --prerequisites item shape: {id: string}
export def "features-revisions-prerequisites put-by-id-version-1" [
  id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  prerequisites: list # List of prerequisite boolean flags. When any prerequisite flag is off for a user, this flag returns its defaultValue for that user. — item shape: {id: string}
  --revisionTitle: string # Title for a newly created draft. Only used when version is "new"; ignored for existing revisions.
  --revisionComment: string # Comment for a newly created draft. Only used when version is "new"; ignored for existing revisions.
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)/prerequisites")
  let body = {prerequisites: $prerequisites, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set holdout in a draft revision
#
# PUT /v2/features/{id}/revisions/{version}/holdout
# operationId: putFeatureRevisionHoldoutV2
export def "features-revisions-holdout put-by-id-version-1" [
  id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  holdout: any
  --revisionTitle: string # Title for a newly created draft. Only used when version is "new"; ignored for existing revisions.
  --revisionComment: string # Comment for a newly created draft. Only used when version is "new"; ignored for existing revisions.
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)/holdout")
  let body = {holdout: $holdout, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set archived state in a draft revision
#
# PUT /v2/features/{id}/revisions/{version}/archive
# operationId: putFeatureRevisionArchiveV2
export def "features-revisions-archive put-by-id-version-1" [
  id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --archived: oneof<nothing, bool>
  --revisionTitle: string # Title for a newly created draft. Only used when version is "new"; ignored for existing revisions.
  --revisionComment: string # Comment for a newly created draft. Only used when version is "new"; ignored for existing revisions.
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)/archive")
  let body = {archived: $archived, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Toggle an environment on/off in a draft revision
#
# POST /v2/features/{id}/revisions/{version}/toggle
# operationId: postFeatureRevisionToggleV2
export def "features-revisions-toggle post-by-id-version-1" [
  id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  environment: string
  --enabled: oneof<nothing, bool>
  --revisionTitle: string # Title for a newly created draft. Only used when version is "new"; ignored for existing revisions.
  --revisionComment: string # Comment for a newly created draft. Only used when version is "new"; ignored for existing revisions.
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)/toggle")
  let body = {environment: $environment, enabled: $enabled, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a rule to a draft revision
#
# POST /v2/features/{id}/revisions/{version}/rules
# operationId: postFeatureRevisionRuleAddV2
# --rampSchedule shape: {name?: string, templateId?: string, startActions?: list, steps?: list, endActions?: list, startDate?: any, cutoffDate?: any, monitoringConfig?: record, lockdownConfig?: record}
# --schedule shape: {startDate?: any, endDate?: any}
export def "features-revisions-rules post-by-id-version-1" [
  id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  rule: any
  --rampSchedule: record # Multi-step ramp schedule for force/rollout rules. Not supported for experiment-ref or safe-rollout rules. Mutually exclusive with `schedule`. — shape: {name?: string, templateId?: string, startActions?: list, steps?: list, endActions?: list, startDate?: any, cutoffDate?: any, monitoringConfig?: record, lockdownConfig?: record}
  --schedule: record # Simple start/end date window. For force/rollout rules this creates a standalone ramp action; for experiment-ref/safe-rollout rules this sets legacy schedule fields on the rule. Mutually exclusive with `rampSchedule`. — shape: {startDate?: any, endDate?: any}
  --revisionTitle: string # Title for a newly created draft. Only used when version is "new"; ignored for existing revisions.
  --revisionComment: string # Comment for a newly created draft. Only used when version is "new"; ignored for existing revisions.
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)/rules")
  let body = {rule: $rule, rampSchedule: $rampSchedule, schedule: $schedule, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a rule in a draft revision
#
# PUT /v2/features/{id}/revisions/{version}/rules/{ruleId}
# operationId: putFeatureRevisionRuleV2
# --rule shape: {description?: string, enabled?: bool, condition?: string, savedGroups?: list, prerequisites?: list, type?: "force"|"rollout"|"experiment-ref"|"safe-rollout", value?: string, coverage?: float, hashAttribute?: string, seed?: string, hashVersion?: any, experimentId?: string, variations?: list, controlValue?: string, variationValue?: string, allEnvironments?: bool, environments?: list}
# --rampSchedule shape: {name?: string, templateId?: string, startActions?: list, steps?: list, endActions?: list, startDate?: any, cutoffDate?: any, monitoringConfig?: record, lockdownConfig?: record}
# --schedule shape: {startDate?: any, endDate?: any}
export def "features-revisions-rules put-by-id-version-ruleId-1" [
  id: string
  version: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  rule: record # shape: {description?: string, enabled?: bool, condition?: string, savedGroups?: list, prerequisites?: list, type?: "force"|"rollout"|"experiment-ref"|"safe-rollout", value?: string, coverage?: float, hashAttribute?: string, seed?: string, hashVersion?: any, experimentId?: string, variations?: list, controlValue?: string, variationValue?: string, allEnvironments?: bool, environments?: list}
  --rampSchedule: record # Multi-step ramp schedule for force/rollout rules. Not supported for experiment-ref or safe-rollout rules. Mutually exclusive with `schedule`. — shape: {name?: string, templateId?: string, startActions?: list, steps?: list, endActions?: list, startDate?: any, cutoffDate?: any, monitoringConfig?: record, lockdownConfig?: record}
  --schedule: record # Simple start/end date window. For force/rollout rules this manages a standalone ramp action; for experiment-ref/safe-rollout rules this updates legacy schedule fields on the rule. Mutually exclusive with `rampSchedule`. — shape: {startDate?: any, endDate?: any}
  --revisionTitle: string # Title for a newly created draft. Only used when version is "new"; ignored for existing revisions.
  --revisionComment: string # Comment for a newly created draft. Only used when version is "new"; ignored for existing revisions.
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)/rules/($ruleId)")
  let body = {rule: $rule, rampSchedule: $rampSchedule, schedule: $schedule, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a rule from a draft revision
#
# DELETE /v2/features/{id}/revisions/{version}/rules/{ruleId}
# operationId: deleteFeatureRevisionRuleV2
export def "features-revisions-rules delete-by-id-version-ruleId-1" [
  id: string
  version: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revisionTitle: string # Title for a newly created draft. Only used when version is "new"; ignored for existing revisions.
  --revisionComment: string # Comment for a newly created draft. Only used when version is "new"; ignored for existing revisions.
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)/rules/($ruleId)")
  let body = {revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reorder rules in the revision
#
# POST /v2/features/{id}/revisions/{version}/rules/reorder
# operationId: postFeatureRevisionRulesReorderV2
export def "features-revisions-rules-reorder post-by-id-version-1" [
  id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ruleIds: list
  --revisionTitle: string # Title for a newly created draft. Only used when version is "new"; ignored for existing revisions.
  --revisionComment: string # Comment for a newly created draft. Only used when version is "new"; ignored for existing revisions.
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)/rules/reorder")
  let body = {ruleIds: $ruleIds, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set ramp schedule for a rule
#
# PUT /v2/features/{id}/revisions/{version}/rules/{ruleId}/ramp-schedule
# operationId: putFeatureRevisionRuleRampScheduleV2
# --startActions item shape: {targetType?: string, targetId?: string, patch: record}
# --steps item shape: {interval: any, actions?: list, approvalNotes?: any, monitored?: bool, holdConditions?: record}
# --endActions item shape: {targetType?: string, targetId?: string, patch: record}
# --monitoringConfig shape: {datasourceId: string, exposureQueryId: string, guardrailMetricIds: list, signalMetricIds?: list, updateScheduleMinutes?: any, monitoringMode?: "auto"|"manual", autoUpdate?: bool, srmAction?: "rollback"|"hold"|"warn", noTrafficAction?: "rollback"|"hold"|"warn", noTrafficGracePeriodHours?: any, multipleExposureAction?: "rollback"|"hold"|"warn"}
# --lockdownConfig shape: {mode: "none"|"locked"}
@deprecated --flag environment
export def "features-revisions-rules-ramp-schedule put-by-id-version-ruleId-1" [
  id: string
  version: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --templateId: string
  --startActions: list # item shape: {targetType?: string, targetId?: string, patch: record}
  --steps: list # item shape: {interval: any, actions?: list, approvalNotes?: any, monitored?: bool, holdConditions?: record}
  --endActions: list # item shape: {targetType?: string, targetId?: string, patch: record}
  --startDate: any # ISO 8601 date-time, e.g. "2025-06-01T00:00:00Z". Absent or null means start immediately on publish.
  --cutoffDate: any # ISO 8601 date-time, e.g. "2025-07-01T00:00:00Z". The ramp ends at this time.
  --monitoringConfig: record # shape: {datasourceId: string, exposureQueryId: string, guardrailMetricIds: list, signalMetricIds?: list, updateScheduleMinutes?: any, monitoringMode?: "auto"|"manual", autoUpdate?: bool, srmAction?: "rollback"|"hold"|"warn", noTrafficAction?: "rollback"|"hold"|"warn", noTrafficGracePeriodHours?: any, multipleExposureAction?: "rollback"|"hold"|"warn"}
  --lockdownConfig: record # shape: {mode: "none"|"locked"}
  --environment: string # DEPRECATED
  --revisionTitle: string # Title for a newly created draft. Only used when version is "new"; ignored for existing revisions.
  --revisionComment: string # Comment for a newly created draft. Only used when version is "new"; ignored for existing revisions.
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)/rules/($ruleId)/ramp-schedule")
  let body = {name: $name, templateId: $templateId, startActions: $startActions, steps: $steps, endActions: $endActions, startDate: $startDate, cutoffDate: $cutoffDate, monitoringConfig: $monitoringConfig, lockdownConfig: $lockdownConfig, environment: $environment, revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove ramp schedule from a rule
#
# DELETE /v2/features/{id}/revisions/{version}/rules/{ruleId}/ramp-schedule
# operationId: deleteFeatureRevisionRuleRampScheduleV2
export def "features-revisions-rules-ramp-schedule delete-by-id-version-ruleId-1" [
  id: string
  version: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revisionTitle: string # Title for a newly created draft. Only used when version is "new"; ignored for existing revisions.
  --revisionComment: string # Comment for a newly created draft. Only used when version is "new"; ignored for existing revisions.
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)/rules/($ruleId)/ramp-schedule")
  let body = {revisionTitle: $revisionTitle, revisionComment: $revisionComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request review for a draft revision
#
# POST /v2/features/{id}/revisions/{version}/request-review
# operationId: postFeatureRevisionRequestReviewV2
export def "features-revisions-request-review post-by-id-version-1" [
  id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)/request-review")
  let body = {comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Submit a review on a draft revision
#
# POST /v2/features/{id}/revisions/{version}/submit-review
# operationId: postFeatureRevisionSubmitReviewV2
export def "features-revisions-submit-review post-by-id-version-1" [
  id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  --action: string@action-completer
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)/submit-review")
  let body = {comment: $comment, action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get merge status for a draft revision
#
# GET /v2/features/{id}/revisions/{version}/merge-status
# operationId: getFeatureRevisionMergeStatusV2
export def "features-revisions-merge-status get-by-id-version-1" [
  id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool, conflicts: table<name: string, key: string, resolved: bool, base: string, live: string, revision: string>, result: record<defaultValue: string, rules: list<any>, environmentsEnabled: record, prerequisites: list<record>, archived: bool, metadata: record<releaseType: string, riskLevel: string>, holdout: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)/merge-status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rebase a draft revision onto the current live version
#
# POST /v2/features/{id}/revisions/{version}/rebase
# operationId: postFeatureRevisionRebaseV2
export def "features-revisions-rebase post-by-id-version-1" [
  id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conflictResolutions: record
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)/rebase")
  let body = {conflictResolutions: $conflictResolutions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Publish a draft revision
#
# POST /v2/features/{id}/revisions/{version}/publish
# operationId: postFeatureRevisionPublishV2
export def "features-revisions-publish post-by-id-version-1" [
  id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)/publish")
  let body = {comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Discard a draft revision
#
# POST /v2/features/{id}/revisions/{version}/discard
# operationId: postFeatureRevisionDiscardV2
export def "features-revisions-discard post-by-id-version-1" [
  id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)/discard")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revert the feature to a prior revision
#
# POST /v2/features/{id}/revisions/{version}/revert
# operationId: postFeatureRevisionRevertV2
export def "features-revisions-revert post-by-id-version-1" [
  id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --strategy: string@strategy-completer
  --comment: string
  --title: string
]: any -> record<revision: record<featureId: string, baseVersion: int, version: int, comment: string, date: string, status: string, createdBy: record<type: string, id: string, name: string, email: string>, publishedBy: record<type: string, id: string, name: string, email: string>, defaultValue: string, rules: list<record>, definitions: record, environmentsEnabled: record, envPrerequisites: record, prerequisites: list<record>, metadata: record<description: string, owner: string, project: string, tags: list, neverStale: bool, valueType: string, jsonSchema: record, customFields: record>, rampActions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/features/($id)/revisions/($version)/revert")
  let body = {strategy: $strategy, comment: $comment, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the organization's archetypes
#
# GET /v1/archetypes
# operationId: listArchetypes
export def "archetypes listArchetypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archetypes: table<id: string, dateCreated: string, dateUpdated: string, name: string, description: string, owner: string, ownerEmail: string, isPublic: bool, attributes: record, projects: list, environments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/archetypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single archetype
#
# POST /v1/archetypes
# operationId: postArchetype
export def "archetypes post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string
  --isPublic: oneof<nothing, bool> # Whether to make this Archetype available to other team members
  --attributes: record # The attributes to set when using this Archetype
  --projects: list
  --environments: list # Limit this Archetype to specific environments. Omit or leave empty to apply to all environments.
]: any -> record<archetype: record<id: string, dateCreated: string, dateUpdated: string, name: string, description: string, owner: string, ownerEmail: string, isPublic: bool, attributes: record, projects: list<string>, environments: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/archetypes")
  let body = {name: $name, description: $description, isPublic: $isPublic, attributes: $attributes, projects: $projects, environments: $environments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single archetype
#
# GET /v1/archetypes/{id}
# operationId: getArchetype
export def "archetypes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archetype: record<id: string, dateCreated: string, dateUpdated: string, name: string, description: string, owner: string, ownerEmail: string, isPublic: bool, attributes: record, projects: list<string>, environments: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/archetypes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single archetype
#
# PUT /v1/archetypes/{id}
# operationId: putArchetype
export def "archetypes put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: string
  --isPublic: oneof<nothing, bool> # Whether to make this Archetype available to other team members
  --attributes: record # The attributes to set when using this Archetype
  --projects: list
  --environments: list # Limit this Archetype to specific environments. Omit or leave empty to apply to all environments.
]: any -> record<archetype: record<id: string, dateCreated: string, dateUpdated: string, name: string, description: string, owner: string, ownerEmail: string, isPublic: bool, attributes: record, projects: list<string>, environments: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/archetypes/($id)")
  let body = {name: $name, description: $description, isPublic: $isPublic, attributes: $attributes, projects: $projects, environments: $environments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a single archetype
#
# DELETE /v1/archetypes/{id}
# operationId: deleteArchetype
export def "archetypes delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/archetypes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all experiments
#
# GET /v1/experiments
# operationId: listExperiments
export def "experiments listExperiments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --projectId: string # Filter by project id
  --datasourceId: string # Filter by Data Source
  --trackingKey: string # Filter by experiment tracking key
  --experimentId: string # Filter the returned list by the experiment tracking key (not the internal experiment ID). Note, this was deprecated to help reduce confusion, consider using `trackingKey` instead, which is functionally identical. You cannot use both params at the same time.
  --status: string@status-completer
]: nothing -> record<experiments: table<id: string, trackingKey: string, dateCreated: string, dateUpdated: string, name: string, type: string, project: string, hypothesis: string, description: string, tags: list, owner: string, ownerEmail: string, archived: bool, status: string, autoRefresh: bool, hashAttribute: string, fallbackAttribute: string, hashVersion: any, disableStickyBucketing: bool, bucketVersion: float, minBucketVersion: float, variations: list, phases: list, settings: record, resultSummary: record, shareLevel: string, publicUrl: string, banditScheduleValue: float, banditScheduleUnit: string, banditBurnInValue: float, banditBurnInUnit: string, banditConversionWindowValue: float, banditConversionWindowUnit: string, linkedFeatures: list, hasVisualChangesets: bool, hasURLRedirects: bool, customFields: record, customMetricSlices: list, precomputedUnitDimensionIds: list, defaultDashboardId: string, templateId: string, statusUpdateSchedule: any, nextScheduledStatusUpdate: any>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "datasourceId" $datasourceId "scalar") (serialize-qp "trackingKey" $trackingKey "scalar") (serialize-qp "experimentId" $experimentId "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/experiments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single experiment
#
# POST /v1/experiments
# operationId: postExperiment
# --lookbackOverride shape: {type: "date"|"window", value: any, valueUnit?: "minutes"|"hours"|"days"|"weeks"}
# --variations item shape: {id?: string, key: string, name: string, description?: string, screenshots?: list}
# --phases item shape: {name: string, dateStarted: string, dateEnded?: string, reasonForStopping?: string, seed?: string, coverage?: float, namespace?: record, prerequisites?: list, reason?: string, condition?: string, savedGroupTargeting?: list, variationWeights?: list}
# --decisionFrameworkSettings shape: {decisionCriteriaId?: string, decisionFrameworkMetricOverrides?: list}
# --metricOverrides item shape: {id: string, windowType?: "conversion"|"lookback"|"", windowHours?: float, delayHours?: float, properPriorOverride?: bool, properPriorEnabled?: bool, properPriorMean?: float, properPriorStdDev?: float, regressionAdjustmentOverride?: bool, regressionAdjustmentEnabled?: bool, regressionAdjustmentDays?: float}
# --customMetricSlices item shape: {slices: list}
# --statusUpdateSchedule shape: {startAt: string}
export def "experiments post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasourceId: string # ID for the [DataSource](#tag/DataSource_model). Can only be set if a templateId is not provided.
  --assignmentQueryId: string # The ID property of one of the assignment query objects associated with the datasource. Can only be set if a templateId is not provided.
  trackingKey: string
  --bypassDuplicateKeyCheck: oneof<nothing, bool> # If true, allow creating an experiment even if another experiment with the same tracking key already exists. This is ignored if the organization requires unique tracking keys as a rule.
  name: string # Name of the experiment
  --type: string@type-completer
  --project: string # Project ID which the experiment belongs to
  --templateId: string # ID of the [ExperimentTemplate](#tag/ExperimentTemplate_model) this experiment was created from. Template fields are applied by default and overridden by explicitly provided payload fields.
  --hypothesis: string # Hypothesis of the experiment
  --description: string # Description of the experiment
  --tags: list
  --metrics: list
  --secondaryMetrics: list
  --guardrailMetrics: list
  --activationMetric: string # Users must convert on this metric before being included
  --segmentId: string # Only users in this segment will be included
  --queryFilter: string # WHERE clause to add to the default experiment query
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization. When omitted, it defaults to the user associated with the request's Personal Access Token (PAT), if one is being used.
  --archived: oneof<nothing, bool>
  --status: string@status-completer
  --autoRefresh: oneof<nothing, bool>
  --hashAttribute: string
  --fallbackAttribute: string
  --hashVersion: any
  --disableStickyBucketing: oneof<nothing, bool>
  --bucketVersion: float
  --minBucketVersion: float
  --releasedVariationId: string
  --excludeFromPayload: oneof<nothing, bool>
  --inProgressConversions: string@inProgressConversions-completer
  --attributionModel: string@attributionModel-completer # Setting attribution model to `"experimentDuration"` is the same as selecting "Ignore Conversion Windows" for the Conversion Window Override. Setting it to `"lookbackOverride"` requires a `lookbackOverride` object to be provided.
  --lookbackOverride: record # Controls the lookback override for the experiment. For type "window", value must be a non-negative number and valueUnit is required. — shape: {type: "date"|"window", value: any, valueUnit?: "minutes"|"hours"|"days"|"weeks"}
  --statsEngine: string@statsEngine-completer
  variations: list # item shape: {id?: string, key: string, name: string, description?: string, screenshots?: list}
  --phases: list # item shape: {name: string, dateStarted: string, dateEnded?: string, reasonForStopping?: string, seed?: string, coverage?: float, namespace?: record, prerequisites?: list, reason?: string, condition?: string, savedGroupTargeting?: list, variationWeights?: list}
  --regressionAdjustmentEnabled: oneof<nothing, bool> # Controls whether regression adjustment (CUPED) is enabled for experiment analyses
  --sequentialTestingEnabled: oneof<nothing, bool> # Only applicable to frequentist analyses
  --sequentialTestingTuningParameter: float
  --shareLevel: string@shareLevel-completer
  --banditScheduleValue: float
  --banditScheduleUnit: string@banditScheduleUnit-completer
  --banditBurnInValue: float
  --banditBurnInUnit: string@banditBurnInUnit-completer
  --banditConversionWindowValue: float
  --banditConversionWindowUnit: string@banditConversionWindowUnit-completer
  --postStratificationEnabled: any # When null, the organization default is used.
  --decisionFrameworkSettings: record # Controls the decision framework and metric overrides for the experiment. Replaces the entire stored object on update (does not patch individual fields). — shape: {decisionCriteriaId?: string, decisionFrameworkMetricOverrides?: list}
  --metricOverrides: list # Per-metric analysis overrides for this experiment. Replaces the entire stored array (does not patch individual entries). — item shape: {id: string, windowType?: "conversion"|"lookback"|"", windowHours?: float, delayHours?: float, properPriorOverride?: bool, properPriorEnabled?: bool, properPriorMean?: float, properPriorStdDev?: float, regressionAdjustmentOverride?: bool, regressionAdjustmentEnabled?: bool, regressionAdjustmentDays?: float}
  --defaultDashboardId: string # ID of the default dashboard for this experiment.
  --customFields: record
  --customMetricSlices: list # Custom slices that apply to ALL applicable metrics in the experiment — item shape: {slices: list}
  --precomputedUnitDimensionIds: list
  --statusUpdateSchedule: record # Schedule a future start for a draft experiment. Only `startAt` is currently supported. — shape: {startAt: string}
]: any -> record<experiment: record<id: string, trackingKey: string, dateCreated: string, dateUpdated: string, name: string, type: string, project: string, hypothesis: string, description: string, tags: list<string>, owner: string, ownerEmail: string, archived: bool, status: string, autoRefresh: bool, hashAttribute: string, fallbackAttribute: string, hashVersion: any, disableStickyBucketing: bool, bucketVersion: float, minBucketVersion: float, variations: list<record>, phases: list<record>, settings: record<datasourceId: string, assignmentQueryId: string, experimentId: string, segmentId: string, queryFilter: string, inProgressConversions: string, attributionModel: string, lookbackOverride: record, statsEngine: string, regressionAdjustmentEnabled: bool, sequentialTestingEnabled: bool, sequentialTestingTuningParameter: float, postStratificationEnabled: any, decisionFrameworkSettings: record, metricOverrides: list, goals: list, secondaryMetrics: list, guardrails: list, activationMetric: record>, resultSummary: record<status: string, winner: string, conclusions: string, releasedVariationId: string, excludeFromPayload: bool>, shareLevel: string, publicUrl: string, banditScheduleValue: float, banditScheduleUnit: string, banditBurnInValue: float, banditBurnInUnit: string, banditConversionWindowValue: float, banditConversionWindowUnit: string, linkedFeatures: list<string>, hasVisualChangesets: bool, hasURLRedirects: bool, customFields: record, customMetricSlices: list<record>, precomputedUnitDimensionIds: list<string>, defaultDashboardId: string, templateId: string, statusUpdateSchedule: any, nextScheduledStatusUpdate: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/experiments")
  let body = {datasourceId: $datasourceId, assignmentQueryId: $assignmentQueryId, trackingKey: $trackingKey, bypassDuplicateKeyCheck: $bypassDuplicateKeyCheck, name: $name, type: $type, project: $project, templateId: $templateId, hypothesis: $hypothesis, description: $description, tags: $tags, metrics: $metrics, secondaryMetrics: $secondaryMetrics, guardrailMetrics: $guardrailMetrics, activationMetric: $activationMetric, segmentId: $segmentId, queryFilter: $queryFilter, owner: $owner, archived: $archived, status: $status, autoRefresh: $autoRefresh, hashAttribute: $hashAttribute, fallbackAttribute: $fallbackAttribute, hashVersion: $hashVersion, disableStickyBucketing: $disableStickyBucketing, bucketVersion: $bucketVersion, minBucketVersion: $minBucketVersion, releasedVariationId: $releasedVariationId, excludeFromPayload: $excludeFromPayload, inProgressConversions: $inProgressConversions, attributionModel: $attributionModel, lookbackOverride: $lookbackOverride, statsEngine: $statsEngine, variations: $variations, phases: $phases, regressionAdjustmentEnabled: $regressionAdjustmentEnabled, sequentialTestingEnabled: $sequentialTestingEnabled, sequentialTestingTuningParameter: $sequentialTestingTuningParameter, shareLevel: $shareLevel, banditScheduleValue: $banditScheduleValue, banditScheduleUnit: $banditScheduleUnit, banditBurnInValue: $banditBurnInValue, banditBurnInUnit: $banditBurnInUnit, banditConversionWindowValue: $banditConversionWindowValue, banditConversionWindowUnit: $banditConversionWindowUnit, postStratificationEnabled: $postStratificationEnabled, decisionFrameworkSettings: $decisionFrameworkSettings, metricOverrides: $metricOverrides, defaultDashboardId: $defaultDashboardId, customFields: $customFields, customMetricSlices: $customMetricSlices, precomputedUnitDimensionIds: $precomputedUnitDimensionIds, statusUpdateSchedule: $statusUpdateSchedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get latest results for many experiments
#
# GET /v1/experiments/results
# operationId: listExperimentResults
export def "experiments-results listExperimentResults" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --projectId: string # Filter by project id
  --datasourceId: string # Filter by Data Source
  --trackingKey: string # Filter by experiment tracking key
  --status: string@status-completer
]: nothing -> record<experimentResults: table<id: string, dateUpdated: string, experimentId: string, phase: string, dateStart: string, dateEnd: string, dimension: record, settings: record, queryIds: list, results: list>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "datasourceId" $datasourceId "scalar") (serialize-qp "trackingKey" $trackingKey "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/experiments/results" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single experiment
#
# GET /v1/experiments/{id}
# operationId: getExperiment
export def "experiments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<experiment: record<id: string, trackingKey: string, dateCreated: string, dateUpdated: string, name: string, type: string, project: string, hypothesis: string, description: string, tags: list<string>, owner: string, ownerEmail: string, archived: bool, status: string, autoRefresh: bool, hashAttribute: string, fallbackAttribute: string, hashVersion: any, disableStickyBucketing: bool, bucketVersion: float, minBucketVersion: float, variations: list<record>, phases: list<record>, settings: record<datasourceId: string, assignmentQueryId: string, experimentId: string, segmentId: string, queryFilter: string, inProgressConversions: string, attributionModel: string, lookbackOverride: record, statsEngine: string, regressionAdjustmentEnabled: bool, sequentialTestingEnabled: bool, sequentialTestingTuningParameter: float, postStratificationEnabled: any, decisionFrameworkSettings: record, metricOverrides: list, goals: list, secondaryMetrics: list, guardrails: list, activationMetric: record>, resultSummary: record<status: string, winner: string, conclusions: string, releasedVariationId: string, excludeFromPayload: bool>, shareLevel: string, publicUrl: string, banditScheduleValue: float, banditScheduleUnit: string, banditBurnInValue: float, banditBurnInUnit: string, banditConversionWindowValue: float, banditConversionWindowUnit: string, linkedFeatures: list<string>, hasVisualChangesets: bool, hasURLRedirects: bool, customFields: record, customMetricSlices: list<record>, precomputedUnitDimensionIds: list<string>, defaultDashboardId: string, templateId: string, statusUpdateSchedule: any, nextScheduledStatusUpdate: any, enhancedStatus: record<status: string, detailedStatus: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/experiments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single experiment
#
# POST /v1/experiments/{id}
# operationId: updateExperiment
# --lookbackOverride shape: {type: "date"|"window", value: any, valueUnit?: "minutes"|"hours"|"days"|"weeks"}
# --variations item shape: {id?: string, key: string, name: string, description?: string, screenshots?: list}
# --phases item shape: {name: string, dateStarted: string, dateEnded?: string, reasonForStopping?: string, seed?: string, coverage?: float, namespace?: record, prerequisites?: list, reason?: string, condition?: string, savedGroupTargeting?: list, variationWeights?: list}
# --decisionFrameworkSettings shape: {decisionCriteriaId?: string, decisionFrameworkMetricOverrides?: list}
# --metricOverrides item shape: {id: string, windowType?: "conversion"|"lookback"|"", windowHours?: float, delayHours?: float, properPriorOverride?: bool, properPriorEnabled?: bool, properPriorMean?: float, properPriorStdDev?: float, regressionAdjustmentOverride?: bool, regressionAdjustmentEnabled?: bool, regressionAdjustmentDays?: float}
# --customMetricSlices item shape: {slices: list}
export def "experiments updateExperiment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasourceId: string # Can only be set if existing experiment does not have a datasource
  --assignmentQueryId: string
  --trackingKey: string
  --bypassDuplicateKeyCheck: oneof<nothing, bool> # If true, allow updating the tracking key even if another experiment with the same tracking key already exist. This is ignored if the organization requires unique tracking keys as a rule.
  --name: string # Name of the experiment
  --type: string@type-completer
  --project: string # Project ID which the experiment belongs to
  --hypothesis: string # Hypothesis of the experiment
  --description: string # Description of the experiment
  --tags: list
  --metrics: list
  --secondaryMetrics: list
  --guardrailMetrics: list
  --activationMetric: string # Users must convert on this metric before being included
  --segmentId: string # Only users in this segment will be included
  --queryFilter: string # WHERE clause to add to the default experiment query
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization.
  --archived: oneof<nothing, bool>
  --status: string@status-completer
  --autoRefresh: oneof<nothing, bool>
  --hashAttribute: string
  --fallbackAttribute: string
  --hashVersion: any
  --disableStickyBucketing: oneof<nothing, bool>
  --bucketVersion: float
  --minBucketVersion: float
  --results: string@results-completer # The result status of the experiment. Maps to resultSummary.status in the GET response.
  --winner: float # The index of the winning variation (0-indexed). Maps to resultSummary.winner (variation ID) in the GET response.
  --analysis: string # Analysis summary or conclusions for the experiment. Maps to resultSummary.conclusions in the GET response.
  --releasedVariationId: string # The ID of the released variation. Maps to resultSummary.releasedVariationId in the GET response.
  --excludeFromPayload: oneof<nothing, bool> # If true, the experiment is excluded from the SDK payload. Maps to resultSummary.excludeFromPayload in the GET response.
  --inProgressConversions: string@inProgressConversions-completer
  --attributionModel: string@attributionModel-completer # Setting attribution model to `"experimentDuration"` is the same as selecting "Ignore Conversion Windows" for the Conversion Window Override. Setting it to `"lookbackOverride"` requires a `lookbackOverride` object to be provided.
  --lookbackOverride: record # Controls the lookback override for the experiment. For type "window", value must be a non-negative number and valueUnit is required. — shape: {type: "date"|"window", value: any, valueUnit?: "minutes"|"hours"|"days"|"weeks"}
  --statsEngine: string@statsEngine-completer
  --variations: list # item shape: {id?: string, key: string, name: string, description?: string, screenshots?: list}
  --phases: list # item shape: {name: string, dateStarted: string, dateEnded?: string, reasonForStopping?: string, seed?: string, coverage?: float, namespace?: record, prerequisites?: list, reason?: string, condition?: string, savedGroupTargeting?: list, variationWeights?: list}
  --regressionAdjustmentEnabled: oneof<nothing, bool> # Controls whether regression adjustment (CUPED) is enabled for experiment analyses
  --sequentialTestingEnabled: oneof<nothing, bool> # Only applicable to frequentist analyses
  --sequentialTestingTuningParameter: float
  --shareLevel: string@shareLevel-completer
  --banditScheduleValue: float
  --banditScheduleUnit: string@banditScheduleUnit-completer
  --banditBurnInValue: float
  --banditBurnInUnit: string@banditBurnInUnit-completer
  --banditConversionWindowValue: float
  --banditConversionWindowUnit: string@banditConversionWindowUnit-completer
  --postStratificationEnabled: any # When null, the organization default is used.
  --decisionFrameworkSettings: record # Controls the decision framework and metric overrides for the experiment. Replaces the entire stored object on update (does not patch individual fields). — shape: {decisionCriteriaId?: string, decisionFrameworkMetricOverrides?: list}
  --metricOverrides: list # Per-metric analysis overrides for this experiment. Replaces the entire stored array (does not patch individual entries). — item shape: {id: string, windowType?: "conversion"|"lookback"|"", windowHours?: float, delayHours?: float, properPriorOverride?: bool, properPriorEnabled?: bool, properPriorMean?: float, properPriorStdDev?: float, regressionAdjustmentOverride?: bool, regressionAdjustmentEnabled?: bool, regressionAdjustmentDays?: float}
  --defaultDashboardId: string # ID of the default dashboard for this experiment.
  --customFields: record
  --customMetricSlices: list # Custom slices that apply to ALL applicable metrics in the experiment — item shape: {slices: list}
  --statusUpdateSchedule: any
  --precomputedUnitDimensionIds: list
]: any -> record<experiment: record<id: string, trackingKey: string, dateCreated: string, dateUpdated: string, name: string, type: string, project: string, hypothesis: string, description: string, tags: list<string>, owner: string, ownerEmail: string, archived: bool, status: string, autoRefresh: bool, hashAttribute: string, fallbackAttribute: string, hashVersion: any, disableStickyBucketing: bool, bucketVersion: float, minBucketVersion: float, variations: list<record>, phases: list<record>, settings: record<datasourceId: string, assignmentQueryId: string, experimentId: string, segmentId: string, queryFilter: string, inProgressConversions: string, attributionModel: string, lookbackOverride: record, statsEngine: string, regressionAdjustmentEnabled: bool, sequentialTestingEnabled: bool, sequentialTestingTuningParameter: float, postStratificationEnabled: any, decisionFrameworkSettings: record, metricOverrides: list, goals: list, secondaryMetrics: list, guardrails: list, activationMetric: record>, resultSummary: record<status: string, winner: string, conclusions: string, releasedVariationId: string, excludeFromPayload: bool>, shareLevel: string, publicUrl: string, banditScheduleValue: float, banditScheduleUnit: string, banditBurnInValue: float, banditBurnInUnit: string, banditConversionWindowValue: float, banditConversionWindowUnit: string, linkedFeatures: list<string>, hasVisualChangesets: bool, hasURLRedirects: bool, customFields: record, customMetricSlices: list<record>, precomputedUnitDimensionIds: list<string>, defaultDashboardId: string, templateId: string, statusUpdateSchedule: any, nextScheduledStatusUpdate: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/experiments/($id)")
  let body = {datasourceId: $datasourceId, assignmentQueryId: $assignmentQueryId, trackingKey: $trackingKey, bypassDuplicateKeyCheck: $bypassDuplicateKeyCheck, name: $name, type: $type, project: $project, hypothesis: $hypothesis, description: $description, tags: $tags, metrics: $metrics, secondaryMetrics: $secondaryMetrics, guardrailMetrics: $guardrailMetrics, activationMetric: $activationMetric, segmentId: $segmentId, queryFilter: $queryFilter, owner: $owner, archived: $archived, status: $status, autoRefresh: $autoRefresh, hashAttribute: $hashAttribute, fallbackAttribute: $fallbackAttribute, hashVersion: $hashVersion, disableStickyBucketing: $disableStickyBucketing, bucketVersion: $bucketVersion, minBucketVersion: $minBucketVersion, results: $results, winner: $winner, analysis: $analysis, releasedVariationId: $releasedVariationId, excludeFromPayload: $excludeFromPayload, inProgressConversions: $inProgressConversions, attributionModel: $attributionModel, lookbackOverride: $lookbackOverride, statsEngine: $statsEngine, variations: $variations, phases: $phases, regressionAdjustmentEnabled: $regressionAdjustmentEnabled, sequentialTestingEnabled: $sequentialTestingEnabled, sequentialTestingTuningParameter: $sequentialTestingTuningParameter, shareLevel: $shareLevel, banditScheduleValue: $banditScheduleValue, banditScheduleUnit: $banditScheduleUnit, banditBurnInValue: $banditBurnInValue, banditBurnInUnit: $banditBurnInUnit, banditConversionWindowValue: $banditConversionWindowValue, banditConversionWindowUnit: $banditConversionWindowUnit, postStratificationEnabled: $postStratificationEnabled, decisionFrameworkSettings: $decisionFrameworkSettings, metricOverrides: $metricOverrides, defaultDashboardId: $defaultDashboardId, customFields: $customFields, customMetricSlices: $customMetricSlices, statusUpdateSchedule: $statusUpdateSchedule, precomputedUnitDimensionIds: $precomputedUnitDimensionIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an experiment pre-launch checklist status
#
# GET /v1/experiments/{id}/start-checklist
# operationId: getExperimentStartChecklist
export def "experiments-start-checklist get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<checklistItems: table<key: string, required: bool, status: string, manual: bool, reason: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/experiments/($id)/start-checklist")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get results for an experiment
#
# GET /v1/experiments/{id}/results
# operationId: getExperimentResults
export def "experiments-results get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --phase: string
  --dimension: string
]: nothing -> record<experiment: record<id: string, trackingKey: string, dateCreated: string, dateUpdated: string, name: string, type: string, project: string, hypothesis: string, description: string, tags: list<string>, owner: string, ownerEmail: string, archived: bool, status: string, autoRefresh: bool, hashAttribute: string, fallbackAttribute: string, hashVersion: any, disableStickyBucketing: bool, bucketVersion: float, minBucketVersion: float, variations: list<record>, phases: list<record>, settings: record<datasourceId: string, assignmentQueryId: string, experimentId: string, segmentId: string, queryFilter: string, inProgressConversions: string, attributionModel: string, lookbackOverride: record, statsEngine: string, regressionAdjustmentEnabled: bool, sequentialTestingEnabled: bool, sequentialTestingTuningParameter: float, postStratificationEnabled: any, decisionFrameworkSettings: record, metricOverrides: list, goals: list, secondaryMetrics: list, guardrails: list, activationMetric: record>, resultSummary: record<status: string, winner: string, conclusions: string, releasedVariationId: string, excludeFromPayload: bool>, shareLevel: string, publicUrl: string, banditScheduleValue: float, banditScheduleUnit: string, banditBurnInValue: float, banditBurnInUnit: string, banditConversionWindowValue: float, banditConversionWindowUnit: string, linkedFeatures: list<string>, hasVisualChangesets: bool, hasURLRedirects: bool, customFields: record, customMetricSlices: list<record>, precomputedUnitDimensionIds: list<string>, defaultDashboardId: string, templateId: string, statusUpdateSchedule: any, nextScheduledStatusUpdate: any>, result: record<id: string, dateUpdated: string, experimentId: string, phase: string, dateStart: string, dateEnd: string, dimension: record<type: string, id: string>, settings: record<datasourceId: string, assignmentQueryId: string, experimentId: string, segmentId: string, queryFilter: string, inProgressConversions: string, attributionModel: string, lookbackOverride: record, statsEngine: string, regressionAdjustmentEnabled: bool, sequentialTestingEnabled: bool, sequentialTestingTuningParameter: float, postStratificationEnabled: any, decisionFrameworkSettings: record, metricOverrides: list, goals: list, secondaryMetrics: list, guardrails: list, activationMetric: record>, queryIds: list<string>, results: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "phase" $phase "scalar") (serialize-qp "dimension" $dimension "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/experiments/($id)/results" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start/Stage an experiment
#
# POST /v1/experiments/{id}/start
# operationId: postExperimentStart
export def "experiments-start post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skipChecklist: oneof<nothing, bool> # If true, skips validating the experiment satisifies all pre-launch checklist items
]: any -> record<experiment: record<id: string, trackingKey: string, dateCreated: string, dateUpdated: string, name: string, type: string, project: string, hypothesis: string, description: string, tags: list<string>, owner: string, ownerEmail: string, archived: bool, status: string, autoRefresh: bool, hashAttribute: string, fallbackAttribute: string, hashVersion: any, disableStickyBucketing: bool, bucketVersion: float, minBucketVersion: float, variations: list<record>, phases: list<record>, settings: record<datasourceId: string, assignmentQueryId: string, experimentId: string, segmentId: string, queryFilter: string, inProgressConversions: string, attributionModel: string, lookbackOverride: record, statsEngine: string, regressionAdjustmentEnabled: bool, sequentialTestingEnabled: bool, sequentialTestingTuningParameter: float, postStratificationEnabled: any, decisionFrameworkSettings: record, metricOverrides: list, goals: list, secondaryMetrics: list, guardrails: list, activationMetric: record>, resultSummary: record<status: string, winner: string, conclusions: string, releasedVariationId: string, excludeFromPayload: bool>, shareLevel: string, publicUrl: string, banditScheduleValue: float, banditScheduleUnit: string, banditBurnInValue: float, banditBurnInUnit: string, banditConversionWindowValue: float, banditConversionWindowUnit: string, linkedFeatures: list<string>, hasVisualChangesets: bool, hasURLRedirects: bool, customFields: record, customMetricSlices: list<record>, precomputedUnitDimensionIds: list<string>, defaultDashboardId: string, templateId: string, statusUpdateSchedule: any, nextScheduledStatusUpdate: any, enhancedStatus: record<status: string, detailedStatus: string>>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/experiments/($id)/start")
  let body = {skipChecklist: $skipChecklist} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Mark manual pre-launch checklist items complete
#
# POST /v1/experiments/{id}/start-checklist/manual/complete
# operationId: postExperimentStartChecklistManualComplete
export def "experiments-start-checklist-manual-complete post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  keys: list # Manual pre-launch checklist item keys to mark as complete (auto-computed items cannot be updated via this endpoint).
]: any -> record<checklistItems: table<key: string, required: bool, status: string, manual: bool, reason: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/experiments/($id)/start-checklist/manual/complete")
  let body = {keys: $keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Stop an experiment
#
# POST /v1/experiments/{id}/stop
# operationId: postExperimentStop
export def "experiments-stop post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  results: string@results-completer # The experiment conclusion status.
  --enableTemporaryRollout: oneof<nothing, bool> # If true, include this stopped experiment in SDK payload and force the release variation (`releasedVariationId`) to all traffic.
  --releasedVariationId: string # Required if enableTemporaryRollout is true. Variation ID (e.g. var_abc123) to release to 100% of traffic eligible for this experiment.
  --winnerVariationId: string # Variation ID (e.g. var_abc123) of the winning variation. Used only as metadata. Required if results is 'won' and there are multiple test variations. Otherwise, defaults to the test variation when results is 'won' and to the baseline variation for other results.
  --analysis: string # Optional markdown summary displayed on the experiment results page.
  --reason: string # Optional reason for ending the phase stored on the latest phase metadata.
  --dateEnded: string # Optional ISO datetime for ending the latest phase. Defaults to the current date and time.
]: any -> record<experiment: record<id: string, trackingKey: string, dateCreated: string, dateUpdated: string, name: string, type: string, project: string, hypothesis: string, description: string, tags: list<string>, owner: string, ownerEmail: string, archived: bool, status: string, autoRefresh: bool, hashAttribute: string, fallbackAttribute: string, hashVersion: any, disableStickyBucketing: bool, bucketVersion: float, minBucketVersion: float, variations: list<record>, phases: list<record>, settings: record<datasourceId: string, assignmentQueryId: string, experimentId: string, segmentId: string, queryFilter: string, inProgressConversions: string, attributionModel: string, lookbackOverride: record, statsEngine: string, regressionAdjustmentEnabled: bool, sequentialTestingEnabled: bool, sequentialTestingTuningParameter: float, postStratificationEnabled: any, decisionFrameworkSettings: record, metricOverrides: list, goals: list, secondaryMetrics: list, guardrails: list, activationMetric: record>, resultSummary: record<status: string, winner: string, conclusions: string, releasedVariationId: string, excludeFromPayload: bool>, shareLevel: string, publicUrl: string, banditScheduleValue: float, banditScheduleUnit: string, banditBurnInValue: float, banditBurnInUnit: string, banditConversionWindowValue: float, banditConversionWindowUnit: string, linkedFeatures: list<string>, hasVisualChangesets: bool, hasURLRedirects: bool, customFields: record, customMetricSlices: list<record>, precomputedUnitDimensionIds: list<string>, defaultDashboardId: string, templateId: string, statusUpdateSchedule: any, nextScheduledStatusUpdate: any, enhancedStatus: record<status: string, detailedStatus: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/experiments/($id)/stop")
  let body = {results: $results, enableTemporaryRollout: $enableTemporaryRollout, releasedVariationId: $releasedVariationId, winnerVariationId: $winnerVariationId, analysis: $analysis, reason: $reason, dateEnded: $dateEnded} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Modify temporary rollout status for a stopped experiment
#
# POST /v1/experiments/{id}/modify-temporary-rollout
# operationId: postExperimentModifyTemporaryRollout
export def "experiments-modify-temporary-rollout post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enableTemporaryRollout: oneof<nothing, bool> # If true, keep the stopped experiment in SDK payload and force traffic to the winner variation. If false, end temporary rollout and remove from SDK payload.
  --releasedVariationId: string # Variation ID (e.g. var_abc123) to release to 100% of traffic eligible for this experiment. Required if enableTemporaryRollout is true.
]: any -> record<experiment: record<id: string, trackingKey: string, dateCreated: string, dateUpdated: string, name: string, type: string, project: string, hypothesis: string, description: string, tags: list<string>, owner: string, ownerEmail: string, archived: bool, status: string, autoRefresh: bool, hashAttribute: string, fallbackAttribute: string, hashVersion: any, disableStickyBucketing: bool, bucketVersion: float, minBucketVersion: float, variations: list<record>, phases: list<record>, settings: record<datasourceId: string, assignmentQueryId: string, experimentId: string, segmentId: string, queryFilter: string, inProgressConversions: string, attributionModel: string, lookbackOverride: record, statsEngine: string, regressionAdjustmentEnabled: bool, sequentialTestingEnabled: bool, sequentialTestingTuningParameter: float, postStratificationEnabled: any, decisionFrameworkSettings: record, metricOverrides: list, goals: list, secondaryMetrics: list, guardrails: list, activationMetric: record>, resultSummary: record<status: string, winner: string, conclusions: string, releasedVariationId: string, excludeFromPayload: bool>, shareLevel: string, publicUrl: string, banditScheduleValue: float, banditScheduleUnit: string, banditBurnInValue: float, banditBurnInUnit: string, banditConversionWindowValue: float, banditConversionWindowUnit: string, linkedFeatures: list<string>, hasVisualChangesets: bool, hasURLRedirects: bool, customFields: record, customMetricSlices: list<record>, precomputedUnitDimensionIds: list<string>, defaultDashboardId: string, templateId: string, statusUpdateSchedule: any, nextScheduledStatusUpdate: any, enhancedStatus: record<status: string, detailedStatus: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/experiments/($id)/modify-temporary-rollout")
  let body = {enableTemporaryRollout: $enableTemporaryRollout, releasedVariationId: $releasedVariationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Experiment Snapshot
#
# POST /v1/experiments/{id}/snapshot
# operationId: postExperimentSnapshot
export def "experiments-snapshot post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --triggeredBy: string@triggeredBy-completer # Set to "schedule" if you want this request to trigger notifications and other events as it if were a scheduled update. Defaults to manual.
  --dimension: string # Dimension to break results down by. For Unit Dimensions, use the dimension id (e.g. "dim_abc123"). For Experiment Dimensions, use "exp:<dimensionName>" (e.g. "exp:country"). Built-in pre-exposure dimensions include "pre:date" and, when configured, "pre:activation". Omit this field to create a standard snapshot.
  --phase: int # Zero-based phase index to snapshot, where 0 is the first experiment phase. Defaults to the latest phase.
]: any -> record<snapshot: record<id: string, experiment: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/experiments/($id)/snapshot")
  let body = {triggeredBy: $triggeredBy, dimension: $dimension, phase: $phase} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upload a variation screenshot
#
# POST /v1/experiments/{id}/variation/{variationId}/screenshot/upload
# operationId: postVariationImageUpload
export def "experiments-variation-screenshot-upload post" [
  id: string
  variationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  screenshot: string # Base64-encoded screenshot data
  contentType: string@contentType-completer # MIME type of the screenshot
  --description: string # Optional description for the screenshot
]: any -> record<screenshot: record<path: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/experiments/($id)/variation/($variationId)/screenshot/upload")
  let body = {screenshot: $screenshot, contentType: $contentType, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a variation screenshot
#
# DELETE /v1/experiments/{id}/variation/{variationId}/screenshot
# operationId: deleteVariationScreenshot
export def "experiments-variation-screenshot delete" [
  id: string
  variationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  path: string # The screenshot path/URL to delete (from upload response)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/experiments/($id)/variation/($variationId)/screenshot")
  let body = {path: $path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of experiments with names and ids
#
# GET /v1/experiment-names
# operationId: getExperimentNames
export def "experiment-names get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --projectId: string # Filter by project id
]: nothing -> record<experiments: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/experiment-names" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all visual changesets
#
# GET /v1/experiments/{id}/visual-changesets
# operationId: listVisualChangesets
export def "experiments-visual-changesets listVisualChangesets" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<visualChangesets: table<id: string, urlPatterns: list, editorUrl: string, experiment: string, visualChanges: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/experiments/($id)/visual-changesets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a visual changeset for an experiment
#
# POST /v1/experiments/{id}/visual-changesets
# operationId: postVisualChangesets
# --urlPatterns item shape: {include?: bool, type: "simple"|"regex", pattern: string}
export def "experiments-visual-changesets post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  editorUrl: string # URL of the page opened in the visual editor when creating this changeset
  urlPatterns: list # URL patterns that determine which pages this visual changeset applies to — item shape: {include?: bool, type: "simple"|"regex", pattern: string}
]: any -> record<visualChangeset: record<id: string, urlPatterns: list<record>, editorUrl: string, experiment: string, visualChanges: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/experiments/($id)/visual-changesets")
  let body = {editorUrl: $editorUrl, urlPatterns: $urlPatterns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an experiment snapshot status
#
# GET /v1/snapshots/{id}
# operationId: getExperimentSnapshot
export def "snapshots get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<snapshot: record<id: string, experiment: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/snapshots/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all metrics
#
# GET /v1/metrics
# operationId: listMetrics
export def "metrics listMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --projectId: string # Filter by project id
  --datasourceId: string # Filter by Data Source
]: nothing -> record<metrics: table<id: string, managedBy: string, dateCreated: string, dateUpdated: string, owner: string, ownerEmail: string, datasourceId: string, name: string, description: string, type: string, tags: list, projects: list, archived: bool, behavior: record, sql: record, sqlBuilder: record, mixpanel: record>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "datasourceId" $datasourceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single metric
#
# POST /v1/metrics
# operationId: postMetric
# --behavior shape: {goal?: "increase"|"decrease", cappingSettings?: record, cap?: float, capping?: any, capValue?: float, windowSettings?: record, conversionWindowStart?: float, conversionWindowEnd?: float, priorSettings?: record, riskThresholdSuccess?: float, riskThresholdDanger?: float, minPercentChange?: float, maxPercentChange?: float, minSampleSize?: float, targetMDE?: float}
# --sql shape: {identifierTypes: list, conversionSQL: string, userAggregationSQL?: string, denominatorMetricId?: string}
# --sqlBuilder shape: {identifierTypeColumns: list, tableName: string, valueColumnName?: string, timestampColumnName: string, conditions?: list}
# --mixpanel shape: {eventName: string, eventValue?: string, userAggregation: string, conditions?: list}
export def "metrics post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  datasourceId: string # ID for the [DataSource](#tag/DataSource_model)
  --managedBy: string@managedBy-completer # Where this metric must be managed from. If not set (empty string), it can be managed from anywhere. If set to "api", it can be managed via the API only.
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization.
  name: string # Name of the metric
  --description: string # Description of the metric
  type: string@type-completer-1 # Type of metric. See [Metrics documentation](/app/metrics/legacy)
  --tags: list # List of tags
  --projects: list # List of project IDs for projects that can access this metric
  --archived: oneof<nothing, bool>
  --behavior: record # shape: {goal?: "increase"|"decrease", cappingSettings?: record, cap?: float, capping?: any, capValue?: float, windowSettings?: record, conversionWindowStart?: float, conversionWindowEnd?: float, priorSettings?: record, riskThresholdSuccess?: float, riskThresholdDanger?: float, minPercentChange?: float, maxPercentChange?: float, minSampleSize?: float, targetMDE?: float}
  --sql: record # Preferred way to define SQL. Only one of `sql`, `sqlBuilder` or `mixpanel` allowed, and at least one must be specified. — shape: {identifierTypes: list, conversionSQL: string, userAggregationSQL?: string, denominatorMetricId?: string}
  --sqlBuilder: record # An alternative way to specify a SQL metric, rather than a full query. Using `sql` is preferred to `sqlBuilder`. Only one of `sql`, `sqlBuilder` or `mixpanel` allowed, and at least one must be specified. — shape: {identifierTypeColumns: list, tableName: string, valueColumnName?: string, timestampColumnName: string, conditions?: list}
  --mixpanel: record # Only use for MixPanel (non-SQL) Data Sources. Only one of `sql`, `sqlBuilder` or `mixpanel` allowed, and at least one must be specified. — shape: {eventName: string, eventValue?: string, userAggregation: string, conditions?: list}
]: any -> record<metric: record<id: string, managedBy: string, dateCreated: string, dateUpdated: string, owner: string, ownerEmail: string, datasourceId: string, name: string, description: string, type: string, tags: list<string>, projects: list<string>, archived: bool, behavior: record<goal: string, cappingSettings: record, cap: float, capping: any, capValue: float, windowSettings: record, priorSettings: record, conversionWindowStart: float, conversionWindowEnd: float, riskThresholdSuccess: float, riskThresholdDanger: float, minPercentChange: float, maxPercentChange: float, minSampleSize: float, targetMDE: float>, sql: record<identifierTypes: list, conversionSQL: string, userAggregationSQL: string, denominatorMetricId: string>, sqlBuilder: record<identifierTypeColumns: list, tableName: string, valueColumnName: string, timestampColumnName: string, conditions: list>, mixpanel: record<eventName: string, eventValue: string, userAggregation: string, conditions: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/metrics")
  let body = {datasourceId: $datasourceId, managedBy: $managedBy, owner: $owner, name: $name, description: $description, type: $type, tags: $tags, projects: $projects, archived: $archived, behavior: $behavior, sql: $sql, sqlBuilder: $sqlBuilder, mixpanel: $mixpanel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single metric
#
# GET /v1/metrics/{id}
# operationId: getMetric
export def "metrics get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<metric: record<id: string, managedBy: string, dateCreated: string, dateUpdated: string, owner: string, ownerEmail: string, datasourceId: string, name: string, description: string, type: string, tags: list<string>, projects: list<string>, archived: bool, behavior: record<goal: string, cappingSettings: record, cap: float, capping: any, capValue: float, windowSettings: record, priorSettings: record, conversionWindowStart: float, conversionWindowEnd: float, riskThresholdSuccess: float, riskThresholdDanger: float, minPercentChange: float, maxPercentChange: float, minSampleSize: float, targetMDE: float>, sql: record<identifierTypes: list, conversionSQL: string, userAggregationSQL: string, denominatorMetricId: string>, sqlBuilder: record<identifierTypeColumns: list, tableName: string, valueColumnName: string, timestampColumnName: string, conditions: list>, mixpanel: record<eventName: string, eventValue: string, userAggregation: string, conditions: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/metrics/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a metric
#
# PUT /v1/metrics/{id}
# operationId: putMetric
# --behavior shape: {goal?: "increase"|"decrease", cappingSettings?: record, cap?: float, capping?: any, capValue?: float, windowSettings?: record, conversionWindowStart?: float, conversionWindowEnd?: float, priorSettings?: record, riskThresholdSuccess?: float, riskThresholdDanger?: float, minPercentChange?: float, maxPercentChange?: float, minSampleSize?: float, targetMDE?: float}
# --sql shape: {identifierTypes?: list, conversionSQL?: string, userAggregationSQL?: string, denominatorMetricId?: string}
# --sqlBuilder shape: {identifierTypeColumns?: list, tableName?: string, valueColumnName?: string, timestampColumnName?: string, conditions?: list}
# --mixpanel shape: {eventName?: string, eventValue?: string, userAggregation?: string, conditions?: list}
export def "metrics put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --managedBy: string@managedBy-completer-1 # Where this metric must be managed from. If not set (empty string), it can be managed from anywhere. If set to "api", it can be managed via the API only. Please note that we have deprecated support for setting the managedBy property to "admin". Your existing Legacy Metrics with this value will continue to work, but we suggest migrating to Fact Metrics instead.
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization.
  --name: string # Name of the metric
  --description: string # Description of the metric
  --type: string@type-completer-1 # Type of metric. See [Metrics documentation](/app/metrics/legacy)
  --tags: list # List of tags
  --projects: list # List of project IDs for projects that can access this metric
  --archived: oneof<nothing, bool>
  --behavior: record # shape: {goal?: "increase"|"decrease", cappingSettings?: record, cap?: float, capping?: any, capValue?: float, windowSettings?: record, conversionWindowStart?: float, conversionWindowEnd?: float, priorSettings?: record, riskThresholdSuccess?: float, riskThresholdDanger?: float, minPercentChange?: float, maxPercentChange?: float, minSampleSize?: float, targetMDE?: float}
  --sql: record # Preferred way to define SQL. Only one of `sql`, `sqlBuilder` or `mixpanel` allowed. — shape: {identifierTypes?: list, conversionSQL?: string, userAggregationSQL?: string, denominatorMetricId?: string}
  --sqlBuilder: record # An alternative way to specify a SQL metric, rather than a full query. Using `sql` is preferred to `sqlBuilder`. Only one of `sql`, `sqlBuilder` or `mixpanel` allowed — shape: {identifierTypeColumns?: list, tableName?: string, valueColumnName?: string, timestampColumnName?: string, conditions?: list}
  --mixpanel: record # Only use for MixPanel (non-SQL) Data Sources. Only one of `sql`, `sqlBuilder` or `mixpanel` allowed. — shape: {eventName?: string, eventValue?: string, userAggregation?: string, conditions?: list}
]: any -> record<updatedId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/metrics/($id)")
  let body = {managedBy: $managedBy, owner: $owner, name: $name, description: $description, type: $type, tags: $tags, projects: $projects, archived: $archived, behavior: $behavior, sql: $sql, sqlBuilder: $sqlBuilder, mixpanel: $mixpanel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a metric
#
# DELETE /v1/metrics/{id}
# operationId: deleteMetric
export def "metrics delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/metrics/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metric usage across experiments
#
# GET /v1/usage/metrics
# operationId: getMetricUsage
export def "usage-metrics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # List of comma-separated metric IDs (both fact and legacy) to get usage for, e.g. ids=met_123,fact_456
]: nothing -> record<metricUsage: table<metricId: string, error: string, experiments: list, lastSnapshotAttempt: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/usage/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all segments
#
# GET /v1/segments
# operationId: listSegments
export def "segments listSegments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --datasourceId: string # Filter by Data Source
]: nothing -> record<segments: table<id: string, owner: string, ownerEmail: string, datasourceId: string, identifierType: string, name: string, description: string, query: string, dateCreated: string, dateUpdated: string, managedBy: string, type: string, factTableId: string, filters: list, projects: list>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "datasourceId" $datasourceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/segments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single segment
#
# POST /v1/segments
# operationId: postSegment
export def "segments post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the segment
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization.
  --description: string # Description of the segment
  datasourceId: string # ID of the datasource this segment belongs to
  identifierType: string # Type of identifier (user, anonymous, etc.)
  --projects: list # List of project IDs for projects that can access this segment
  --managedBy: string@managedBy-completer # Where this Segment must be managed from. If not set (empty string), it can be managed from anywhere.
  type: string@type-completer-2 # GrowthBook supports two types of Segments, SQL and FACT. SQL segments are defined by a SQL query, and FACT segments are defined by a fact table and filters.
  --body-query: string # SQL query that defines the Segment. This is required for SQL segments.
  --factTableId: string # ID of the fact table this segment belongs to. This is required for FACT segments.
  --filters: list # Optional array of fact table filter ids that can further define the Fact Table based Segment.
]: any -> record<segment: record<id: string, owner: string, ownerEmail: string, datasourceId: string, identifierType: string, name: string, description: string, query: string, dateCreated: string, dateUpdated: string, managedBy: string, type: string, factTableId: string, filters: list<string>, projects: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/segments")
  let body = {name: $name, owner: $owner, description: $description, datasourceId: $datasourceId, identifierType: $identifierType, projects: $projects, managedBy: $managedBy, type: $type, query: $body_query, factTableId: $factTableId, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single segment
#
# GET /v1/segments/{id}
# operationId: getSegment
export def "segments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<segment: record<id: string, owner: string, ownerEmail: string, datasourceId: string, identifierType: string, name: string, description: string, query: string, dateCreated: string, dateUpdated: string, managedBy: string, type: string, factTableId: string, filters: list<string>, projects: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/segments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single segment
#
# POST /v1/segments/{id}
# operationId: updateSegment
export def "segments updateSegment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the segment
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization.
  --description: string # Description of the segment
  --datasourceId: string # ID of the datasource this segment belongs to
  --identifierType: string # Type of identifier (user, anonymous, etc.)
  --projects: list # List of project IDs for projects that can access this segment
  --managedBy: string@managedBy-completer # Where this Segment must be managed from. If not set (empty string), it can be managed from anywhere.
  --type: string@type-completer-2 # GrowthBook supports two types of Segments, SQL and FACT. SQL segments are defined by a SQL query, and FACT segments are defined by a fact table and filters.
  --body-query: string # SQL query that defines the Segment. This is required for SQL segments.
  --factTableId: string # ID of the fact table this segment belongs to. This is required for FACT segments.
  --filters: list # Optional array of fact table filter ids that can further define the Fact Table based Segment.
]: any -> record<segment: record<id: string, owner: string, ownerEmail: string, datasourceId: string, identifierType: string, name: string, description: string, query: string, dateCreated: string, dateUpdated: string, managedBy: string, type: string, factTableId: string, filters: list<string>, projects: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/segments/($id)")
  let body = {name: $name, owner: $owner, description: $description, datasourceId: $datasourceId, identifierType: $identifierType, projects: $projects, managedBy: $managedBy, type: $type, query: $body_query, factTableId: $factTableId, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a single segment
#
# DELETE /v1/segments/{id}
# operationId: deleteSegment
export def "segments delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/segments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all dimensions
#
# GET /v1/dimensions
# operationId: listDimensions
export def "dimensions listDimensions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --datasourceId: string # Filter by Data Source
]: nothing -> record<dimensions: table<id: string, dateCreated: string, dateUpdated: string, owner: string, ownerEmail: string, datasourceId: string, identifierType: string, name: string, description: string, query: string, managedBy: string>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "datasourceId" $datasourceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/dimensions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single dimension
#
# POST /v1/dimensions
# operationId: postDimension
export def "dimensions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the dimension
  --description: string # Description of the dimension
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization.
  datasourceId: string # ID of the datasource this dimension belongs to
  identifierType: string # Type of identifier (user, anonymous, etc.)
  --body-query: string # SQL query or equivalent for the dimension
  --managedBy: string@managedBy-completer # Where this dimension must be managed from. If not set (empty string), it can be managed from anywhere.
]: any -> record<dimension: record<id: string, dateCreated: string, dateUpdated: string, owner: string, ownerEmail: string, datasourceId: string, identifierType: string, name: string, description: string, query: string, managedBy: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dimensions")
  let body = {name: $name, description: $description, owner: $owner, datasourceId: $datasourceId, identifierType: $identifierType, query: $body_query, managedBy: $managedBy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single dimension
#
# GET /v1/dimensions/{id}
# operationId: getDimension
export def "dimensions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dimension: record<id: string, dateCreated: string, dateUpdated: string, owner: string, ownerEmail: string, datasourceId: string, identifierType: string, name: string, description: string, query: string, managedBy: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dimensions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single dimension
#
# POST /v1/dimensions/{id}
# operationId: updateDimension
export def "dimensions updateDimension" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the dimension
  --description: string # Description of the dimension
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization.
  --datasourceId: string # ID of the datasource this dimension belongs to
  --identifierType: string # Type of identifier (user, anonymous, etc.)
  --body-query: string # SQL query or equivalent for the dimension
  --managedBy: string@managedBy-completer # Where this dimension must be managed from. If not set (empty string), it can be managed from anywhere.
]: any -> record<dimension: record<id: string, dateCreated: string, dateUpdated: string, owner: string, ownerEmail: string, datasourceId: string, identifierType: string, name: string, description: string, query: string, managedBy: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dimensions/($id)")
  let body = {name: $name, description: $description, owner: $owner, datasourceId: $datasourceId, identifierType: $identifierType, query: $body_query, managedBy: $managedBy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a single dimension
#
# DELETE /v1/dimensions/{id}
# operationId: deleteDimension
export def "dimensions delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dimensions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all projects
#
# GET /v1/projects
# operationId: listProjects
export def "projects listProjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
]: nothing -> record<projects: table<id: string, name: string, dateCreated: string, dateUpdated: string, description: string, publicId: string, settings: record>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single project
#
# POST /v1/projects
# operationId: postProject
# --settings shape: {statsEngine?: string, confidenceLevel?: float, pValueThreshold?: float}
export def "projects post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string
  --publicId: string # URL-safe slug (lowercase letters, numbers, dashes). Auto-generated from name if not provided.
  --settings: record # Project stats settings that, when set, override the organization settings. — shape: {statsEngine?: string, confidenceLevel?: float, pValueThreshold?: float}
]: any -> record<project: record<id: string, name: string, dateCreated: string, dateUpdated: string, description: string, publicId: string, settings: record<statsEngine: string, confidenceLevel: float, pValueThreshold: float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/projects")
  let body = {name: $name, description: $description, publicId: $publicId, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single project
#
# GET /v1/projects/{id}
# operationId: getProject
export def "projects get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<project: record<id: string, name: string, dateCreated: string, dateUpdated: string, description: string, publicId: string, settings: record<statsEngine: string, confidenceLevel: float, pValueThreshold: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a single project
#
# PUT /v1/projects/{id}
# operationId: putProject
# --settings shape: {statsEngine?: string, confidenceLevel?: float, pValueThreshold?: float}
export def "projects put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Project name.
  --description: string # Project description.
  --publicId: string # URL-safe slug (lowercase letters, numbers, dashes).
  --settings: record # Project stats settings that, when set, override the organization settings. — shape: {statsEngine?: string, confidenceLevel?: float, pValueThreshold?: float}
]: any -> record<project: record<id: string, name: string, dateCreated: string, dateUpdated: string, description: string, publicId: string, settings: record<statsEngine: string, confidenceLevel: float, pValueThreshold: float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($id)")
  let body = {name: $name, description: $description, publicId: $publicId, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a single project
#
# DELETE /v1/projects/{id}
# operationId: deleteProject
export def "projects delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the organization's environments
#
# GET /v1/environments
# operationId: listEnvironments
export def "environments listEnvironments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<environments: table<id: string, description: string, toggleOnList: bool, defaultState: bool, projects: list, parent: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/environments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new environment
#
# POST /v1/environments
# operationId: postEnvironment
export def "environments post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # The ID of the new environment
  --description: string # The description of the new environment
  --toggleOnList: oneof<nothing, bool> # Show on feature list page
  --defaultState: oneof<nothing, bool> # Default state for new features
  --projects: list
  --parent: string # An environment that the new environment should inherit feature rules from. Requires an enterprise license
]: any -> record<environment: record<id: string, description: string, toggleOnList: bool, defaultState: bool, projects: list<string>, parent: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/environments")
  let body = {id: $id, description: $description, toggleOnList: $toggleOnList, defaultState: $defaultState, projects: $projects, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an environment
#
# PUT /v1/environments/{id}
# operationId: putEnvironment
export def "environments put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the new environment
  --toggleOnList: oneof<nothing, bool> # Show on feature list page
  --defaultState: oneof<nothing, bool> # Default state for new features
  --projects: list
]: any -> record<environment: record<id: string, description: string, toggleOnList: bool, defaultState: bool, projects: list<string>, parent: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($id)")
  let body = {description: $description, toggleOnList: $toggleOnList, defaultState: $defaultState, projects: $projects} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a single environment
#
# DELETE /v1/environments/{id}
# operationId: deleteEnvironment
export def "environments delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the organization's attributes
#
# GET /v1/attributes
# operationId: listAttributes
export def "attributes listAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --projectId: string # Filter to attributes available in this project — includes org-wide attributes (no project restriction) and attributes explicitly scoped to this project.
]: nothing -> record<attributes: table<property: string, datatype: string, description: string, hashAttribute: bool, archived: bool, enum: string, format: string, projects: list, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/attributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new attribute
#
# POST /v1/attributes
# operationId: postAttribute
export def "attributes post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  property: string # The attribute property
  datatype: string@datatype-completer # The attribute datatype
  --description: string # The description of the new attribute
  --archived: oneof<nothing, bool> # The attribute is archived
  --hashAttribute: oneof<nothing, bool> # Shall the attribute be hashed
  --enum: string
  --format: string@format-completer # The attribute's format
  --projects: list
  --tags: list
]: any -> record<attribute: record<property: string, datatype: string, description: string, hashAttribute: bool, archived: bool, enum: string, format: string, projects: list<string>, tags: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/attributes")
  let body = {property: $property, datatype: $datatype, description: $description, archived: $archived, hashAttribute: $hashAttribute, enum: $enum, format: $format, projects: $projects, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an attribute
#
# PUT /v1/attributes/{property}
# operationId: putAttribute
export def "attributes put" [
  property: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datatype: string@datatype-completer # The attribute datatype
  --description: string # The description of the new attribute
  --archived: oneof<nothing, bool> # The attribute is archived
  --hashAttribute: oneof<nothing, bool> # Shall the attribute be hashed
  --enum: string
  --format: string@format-completer # The attribute's format
  --projects: list
  --tags: list
]: any -> record<attribute: record<property: string, datatype: string, description: string, hashAttribute: bool, archived: bool, enum: string, format: string, projects: list<string>, tags: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/attributes/($property)")
  let body = {datatype: $datatype, description: $description, archived: $archived, hashAttribute: $hashAttribute, enum: $enum, format: $format, projects: $projects, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a single attribute
#
# DELETE /v1/attributes/{property}
# operationId: deleteAttribute
export def "attributes delete" [
  property: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedProperty: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/attributes/($property)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all sdk connections
#
# GET /v1/sdk-connections
# operationId: listSdkConnections
export def "sdk-connections listSdkConnections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --projectId: string # Filter by project id
  --withProxy: string
  --multiOrg: string
]: nothing -> record<connections: table<id: string, dateCreated: string, dateUpdated: string, name: string, organization: string, languages: list, sdkVersion: string, environment: string, project: string, projects: list, encryptPayload: bool, encryptionKey: string, includeVisualExperiments: bool, includeDraftExperiments: bool, includeDraftExperimentRefs: bool, includeExperimentNames: bool, includeRedirectExperiments: bool, includeRuleIds: bool, includeProjectIdInMetadata: bool, includeCustomFieldsInMetadata: bool, allowedCustomFieldsInMetadata: list, includeTagsInMetadata: bool, key: string, proxyEnabled: bool, proxyHost: string, proxySigningKey: string, sseEnabled: bool, hashSecureAttributes: bool, remoteEvalEnabled: bool, savedGroupReferencesEnabled: bool>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "withProxy" $withProxy "scalar") (serialize-qp "multiOrg" $multiOrg "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/sdk-connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single sdk connection
#
# POST /v1/sdk-connections
# operationId: postSdkConnection
export def "sdk-connections post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  language: string
  --sdkVersion: string
  environment: string
  --projects: list
  --encryptPayload: oneof<nothing, bool>
  --includeVisualExperiments: oneof<nothing, bool>
  --includeDraftExperiments: oneof<nothing, bool>
  --includeDraftExperimentRefs: oneof<nothing, bool> # When true, experiment-ref rules linked to draft experiments are included in feature definitions. Off by default.
  --includeExperimentNames: oneof<nothing, bool>
  --includeRedirectExperiments: oneof<nothing, bool>
  --includeRuleIds: oneof<nothing, bool>
  --includeProjectIdInMetadata: oneof<nothing, bool>
  --includeCustomFieldsInMetadata: oneof<nothing, bool>
  --allowedCustomFieldsInMetadata: list
  --includeTagsInMetadata: oneof<nothing, bool>
  --proxyEnabled: oneof<nothing, bool>
  --proxyHost: string
  --hashSecureAttributes: oneof<nothing, bool>
  --remoteEvalEnabled: oneof<nothing, bool>
  --savedGroupReferencesEnabled: oneof<nothing, bool>
]: any -> record<sdkConnection: record<id: string, dateCreated: string, dateUpdated: string, name: string, organization: string, languages: list<string>, sdkVersion: string, environment: string, project: string, projects: list<string>, encryptPayload: bool, encryptionKey: string, includeVisualExperiments: bool, includeDraftExperiments: bool, includeDraftExperimentRefs: bool, includeExperimentNames: bool, includeRedirectExperiments: bool, includeRuleIds: bool, includeProjectIdInMetadata: bool, includeCustomFieldsInMetadata: bool, allowedCustomFieldsInMetadata: list<string>, includeTagsInMetadata: bool, key: string, proxyEnabled: bool, proxyHost: string, proxySigningKey: string, sseEnabled: bool, hashSecureAttributes: bool, remoteEvalEnabled: bool, savedGroupReferencesEnabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sdk-connections")
  let body = {name: $name, language: $language, sdkVersion: $sdkVersion, environment: $environment, projects: $projects, encryptPayload: $encryptPayload, includeVisualExperiments: $includeVisualExperiments, includeDraftExperiments: $includeDraftExperiments, includeDraftExperimentRefs: $includeDraftExperimentRefs, includeExperimentNames: $includeExperimentNames, includeRedirectExperiments: $includeRedirectExperiments, includeRuleIds: $includeRuleIds, includeProjectIdInMetadata: $includeProjectIdInMetadata, includeCustomFieldsInMetadata: $includeCustomFieldsInMetadata, allowedCustomFieldsInMetadata: $allowedCustomFieldsInMetadata, includeTagsInMetadata: $includeTagsInMetadata, proxyEnabled: $proxyEnabled, proxyHost: $proxyHost, hashSecureAttributes: $hashSecureAttributes, remoteEvalEnabled: $remoteEvalEnabled, savedGroupReferencesEnabled: $savedGroupReferencesEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single sdk connection
#
# GET /v1/sdk-connections/{id}
# operationId: getSdkConnection
export def "sdk-connections get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<sdkConnection: record<id: string, dateCreated: string, dateUpdated: string, name: string, organization: string, languages: list<string>, sdkVersion: string, environment: string, project: string, projects: list<string>, encryptPayload: bool, encryptionKey: string, includeVisualExperiments: bool, includeDraftExperiments: bool, includeDraftExperimentRefs: bool, includeExperimentNames: bool, includeRedirectExperiments: bool, includeRuleIds: bool, includeProjectIdInMetadata: bool, includeCustomFieldsInMetadata: bool, allowedCustomFieldsInMetadata: list<string>, includeTagsInMetadata: bool, key: string, proxyEnabled: bool, proxyHost: string, proxySigningKey: string, sseEnabled: bool, hashSecureAttributes: bool, remoteEvalEnabled: bool, savedGroupReferencesEnabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sdk-connections/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single sdk connection
#
# PUT /v1/sdk-connections/{id}
# operationId: putSdkConnection
export def "sdk-connections put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --language: string
  --sdkVersion: string
  --environment: string
  --projects: list
  --encryptPayload: oneof<nothing, bool>
  --includeVisualExperiments: oneof<nothing, bool>
  --includeDraftExperiments: oneof<nothing, bool>
  --includeDraftExperimentRefs: oneof<nothing, bool> # When true, experiment-ref rules linked to draft experiments are included in feature definitions. Off by default.
  --includeExperimentNames: oneof<nothing, bool>
  --includeRedirectExperiments: oneof<nothing, bool>
  --includeRuleIds: oneof<nothing, bool>
  --includeProjectIdInMetadata: oneof<nothing, bool>
  --includeCustomFieldsInMetadata: oneof<nothing, bool>
  --allowedCustomFieldsInMetadata: list
  --includeTagsInMetadata: oneof<nothing, bool>
  --proxyEnabled: oneof<nothing, bool>
  --proxyHost: string
  --hashSecureAttributes: oneof<nothing, bool>
  --remoteEvalEnabled: oneof<nothing, bool>
  --savedGroupReferencesEnabled: oneof<nothing, bool>
]: any -> record<sdkConnection: record<id: string, dateCreated: string, dateUpdated: string, name: string, organization: string, languages: list<string>, sdkVersion: string, environment: string, project: string, projects: list<string>, encryptPayload: bool, encryptionKey: string, includeVisualExperiments: bool, includeDraftExperiments: bool, includeDraftExperimentRefs: bool, includeExperimentNames: bool, includeRedirectExperiments: bool, includeRuleIds: bool, includeProjectIdInMetadata: bool, includeCustomFieldsInMetadata: bool, allowedCustomFieldsInMetadata: list<string>, includeTagsInMetadata: bool, key: string, proxyEnabled: bool, proxyHost: string, proxySigningKey: string, sseEnabled: bool, hashSecureAttributes: bool, remoteEvalEnabled: bool, savedGroupReferencesEnabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sdk-connections/($id)")
  let body = {name: $name, language: $language, sdkVersion: $sdkVersion, environment: $environment, projects: $projects, encryptPayload: $encryptPayload, includeVisualExperiments: $includeVisualExperiments, includeDraftExperiments: $includeDraftExperiments, includeDraftExperimentRefs: $includeDraftExperimentRefs, includeExperimentNames: $includeExperimentNames, includeRedirectExperiments: $includeRedirectExperiments, includeRuleIds: $includeRuleIds, includeProjectIdInMetadata: $includeProjectIdInMetadata, includeCustomFieldsInMetadata: $includeCustomFieldsInMetadata, allowedCustomFieldsInMetadata: $allowedCustomFieldsInMetadata, includeTagsInMetadata: $includeTagsInMetadata, proxyEnabled: $proxyEnabled, proxyHost: $proxyHost, hashSecureAttributes: $hashSecureAttributes, remoteEvalEnabled: $remoteEvalEnabled, savedGroupReferencesEnabled: $savedGroupReferencesEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a single SDK connection
#
# DELETE /v1/sdk-connections/{id}
# operationId: deleteSdkConnection
export def "sdk-connections delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sdk-connections/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find a single sdk connection by its key
#
# GET /v1/sdk-connections/lookup/{key}
# operationId: lookupSdkConnectionByKey
export def "sdk-connections-lookup lookupSdkConnectionByKey" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<sdkConnection: record<id: string, dateCreated: string, dateUpdated: string, name: string, organization: string, languages: list<string>, sdkVersion: string, environment: string, project: string, projects: list<string>, encryptPayload: bool, encryptionKey: string, includeVisualExperiments: bool, includeDraftExperiments: bool, includeDraftExperimentRefs: bool, includeExperimentNames: bool, includeRedirectExperiments: bool, includeRuleIds: bool, includeProjectIdInMetadata: bool, includeCustomFieldsInMetadata: bool, allowedCustomFieldsInMetadata: list<string>, includeTagsInMetadata: bool, key: string, proxyEnabled: bool, proxyHost: string, proxySigningKey: string, sseEnabled: bool, hashSecureAttributes: bool, remoteEvalEnabled: bool, savedGroupReferencesEnabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sdk-connections/lookup/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all data sources
#
# GET /v1/data-sources
# operationId: listDataSources
export def "data-sources listDataSources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --projectId: string # Filter by project id
]: nothing -> record<dataSources: table<id: string, dateCreated: string, dateUpdated: string, type: string, name: string, description: string, projectIds: list, eventTracker: string, identifierTypes: list, assignmentQueries: list, identifierJoinQueries: list, mixpanelSettings: record>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "projectId" $projectId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/data-sources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single data source
#
# GET /v1/data-sources/{id}
# operationId: getDataSource
export def "data-sources get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dataSource: record<id: string, dateCreated: string, dateUpdated: string, type: string, name: string, description: string, projectIds: list<string>, eventTracker: string, identifierTypes: list<record>, assignmentQueries: list<record>, identifierJoinQueries: list<record>, mixpanelSettings: record<viewedExperimentEventName: string, experimentIdProperty: string, variationIdProperty: string, extraUserIdProperty: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/data-sources/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Data Source's Information Schema
#
# GET /v1/data-sources/{dataSourceId}/information-schema
# operationId: getInformationSchema
export def "data-sources-information-schema get" [
  dataSourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<informationSchema: record<id: string, datasourceId: string, status: string, error: record<errorType: string, message: string>, databases: list<record>, dateCreated: string, dateUpdated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/data-sources/($dataSourceId)/information-schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single visual changeset
#
# GET /v1/visual-changesets/{id}
# operationId: getVisualChangeset
export def "visual-changesets get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeExperiment: int # Include the associated experiment in payload
]: nothing -> record<visualChangeset: record<id: string, urlPatterns: list<record>, editorUrl: string, experiment: string, visualChanges: list<record>>, experiment: record<id: string, trackingKey: string, dateCreated: string, dateUpdated: string, name: string, type: string, project: string, hypothesis: string, description: string, tags: list<string>, owner: string, ownerEmail: string, archived: bool, status: string, autoRefresh: bool, hashAttribute: string, fallbackAttribute: string, hashVersion: any, disableStickyBucketing: bool, bucketVersion: float, minBucketVersion: float, variations: list<record>, phases: list<record>, settings: record<datasourceId: string, assignmentQueryId: string, experimentId: string, segmentId: string, queryFilter: string, inProgressConversions: string, attributionModel: string, lookbackOverride: record, statsEngine: string, regressionAdjustmentEnabled: bool, sequentialTestingEnabled: bool, sequentialTestingTuningParameter: float, postStratificationEnabled: any, decisionFrameworkSettings: record, metricOverrides: list, goals: list, secondaryMetrics: list, guardrails: list, activationMetric: record>, resultSummary: record<status: string, winner: string, conclusions: string, releasedVariationId: string, excludeFromPayload: bool>, shareLevel: string, publicUrl: string, banditScheduleValue: float, banditScheduleUnit: string, banditBurnInValue: float, banditBurnInUnit: string, banditConversionWindowValue: float, banditConversionWindowUnit: string, linkedFeatures: list<string>, hasVisualChangesets: bool, hasURLRedirects: bool, customFields: record, customMetricSlices: list<record>, precomputedUnitDimensionIds: list<string>, defaultDashboardId: string, templateId: string, statusUpdateSchedule: any, nextScheduledStatusUpdate: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeExperiment" $includeExperiment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/visual-changesets/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a visual changeset
#
# PUT /v1/visual-changesets/{id}
# operationId: putVisualChangeset
# --urlPatterns item shape: {include?: bool, type: "simple"|"regex", pattern: string}
# --visualChanges item shape: {id?: string, description?: string, css?: string, js?: string, variation: string, domMutations?: list}
export def "visual-changesets put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --editorUrl: string # URL of the page opened in the visual editor when creating this changeset
  --urlPatterns: list # URL patterns that determine which pages this visual changeset applies to — item shape: {include?: bool, type: "simple"|"regex", pattern: string}
  --visualChanges: list # item shape: {id?: string, description?: string, css?: string, js?: string, variation: string, domMutations?: list}
]: any -> record<nModified: float, visualChangeset: record<id: string, urlPatterns: list<record>, editorUrl: string, experiment: string, visualChanges: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/visual-changesets/($id)")
  let body = {editorUrl: $editorUrl, urlPatterns: $urlPatterns, visualChanges: $visualChanges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a visual change for a visual changeset
#
# POST /v1/visual-changesets/{id}/visual-change
# operationId: postVisualChange
# --domMutations item shape: {selector: string, action: "append"|"set"|"remove", attribute: string, value?: string, parentSelector?: string, insertBeforeSelector?: string}
export def "visual-changesets-visual-change post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string
  --description: string
  --css: string
  --js: string
  variation: string
  --domMutations: list # item shape: {selector: string, action: "append"|"set"|"remove", attribute: string, value?: string, parentSelector?: string, insertBeforeSelector?: string}
]: any -> record<nModified: float, visualChangeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/visual-changesets/($id)/visual-change")
  let body = {id: $body_id, description: $description, css: $css, js: $js, variation: $variation, domMutations: $domMutations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a visual change for a visual changeset
#
# PUT /v1/visual-changesets/{id}/visual-change/{visualChangeId}
# operationId: putVisualChange
# --domMutations item shape: {selector: string, action: "append"|"set"|"remove", attribute: string, value?: string, parentSelector?: string, insertBeforeSelector?: string}
export def "visual-changesets-visual-change put" [
  id: string
  visualChangeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string
  --description: string
  --css: string
  --js: string
  --variation: string
  --domMutations: list # item shape: {selector: string, action: "append"|"set"|"remove", attribute: string, value?: string, parentSelector?: string, insertBeforeSelector?: string}
]: any -> record<nModified: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/visual-changesets/($id)/visual-change/($visualChangeId)")
  let body = {id: $body_id, description: $description, css: $css, js: $js, variation: $variation, domMutations: $domMutations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all saved group
#
# GET /v1/saved-groups
# operationId: listSavedGroups
export def "saved-groups listSavedGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
]: nothing -> record<savedGroups: table<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/saved-groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single saved group
#
# POST /v1/saved-groups
# operationId: postSavedGroup
export def "saved-groups post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The display name of the Saved Group
  --type: string@type-completer-3 # The type of Saved Group (inferred from other arguments if missing)
  --condition: string # When type = 'condition', this is the JSON-encoded condition for the group
  --attributeKey: string # When type = 'list', this is the attribute key the group is based on
  --values: list # When type = 'list', this is the list of values for the attribute key
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization. When omitted, it defaults to the user associated with the request's Personal Access Token (PAT), if one is being used.
  --projects: list
  --bypassApproval: oneof<nothing, bool> # Set to true to skip the approval flow when the org requires approvals on saved groups. Requires the `bypassApprovalChecks` permission on every project the saved group belongs to. When the org does not require approvals, this flag has no effect.
]: any -> record<savedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list<string>, description: string, projects: list<string>, archived: bool, useEmptyListGroup: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/saved-groups")
  let body = {name: $name, type: $type, condition: $condition, attributeKey: $attributeKey, values: $values, owner: $owner, projects: $projects, bypassApproval: $bypassApproval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List saved-group revisions across the organization
#
# GET /v1/saved-groups-revisions
# operationId: listSavedGroupRevisions
export def "saved-groups-revisions listSavedGroupRevisions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --skipPagination: string # If true, return all matching items and ignore limit/offset. Self-hosted only. Has no effect unless API_ALLOW_SKIP_PAGINATION is set to true or 1. (default: false)
  --savedGroupId: string # Restrict results to revisions for a single saved group. When omitted, returns revisions across every saved group the caller can read.
  --status: string # Filter by revision status. Accepts a comma-separated list, or the literal `open` for non-merged/non-discarded revisions.
  --author: string
  --mine: string # If true, return only revisions authored by the calling user. Requires a user-scoped API key. Mutually exclusive with `author`.
]: nothing -> record<revisions: table<id: string, version: int, title: string, status: string, authorId: string, authorEmail: string, contributors: list, revertedFrom: string, reviews: list, activityLog: list, resolution: record, dateCreated: string, dateUpdated: string, baseSavedGroup: record, proposedSavedGroup: record, proposedChanges: list>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "skipPagination" $skipPagination "scalar") (serialize-qp "savedGroupId" $savedGroupId "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "mine" $mine "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/saved-groups-revisions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single saved group
#
# GET /v1/saved-groups/{id}
# operationId: getSavedGroup
export def "saved-groups get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<savedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list<string>, description: string, projects: list<string>, archived: bool, useEmptyListGroup: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Partially update a single saved group
#
# POST /v1/saved-groups/{id}
# operationId: updateSavedGroup
export def "saved-groups updateSavedGroup" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The display name of the Saved Group
  --condition: string # When type = 'condition', this is the JSON-encoded condition for the group
  --values: list # When type = 'list', this is the list of values for the attribute key
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization.
  --projects: list
  --bypassApproval: oneof<nothing, bool> # Set to true to skip the approval flow when the org requires approvals on saved groups. Requires the `bypassApprovalChecks` permission on the saved group's existing projects. When the org does not require approvals, this flag has no effect.
]: any -> record<savedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list<string>, description: string, projects: list<string>, archived: bool, useEmptyListGroup: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups/($id)")
  let body = {name: $name, condition: $condition, values: $values, owner: $owner, projects: $projects, bypassApproval: $bypassApproval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a single saved group
#
# DELETE /v1/saved-groups/{id}
# operationId: deleteSavedGroup
export def "saved-groups delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive a single saved group
#
# POST /v1/saved-groups/{id}/archive
# operationId: archiveSavedGroup
export def "saved-groups-archive archiveSavedGroup" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<savedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list<string>, description: string, projects: list<string>, archived: bool, useEmptyListGroup: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups/($id)/archive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unarchive a single saved group
#
# POST /v1/saved-groups/{id}/unarchive
# operationId: unarchiveSavedGroup
export def "saved-groups-unarchive unarchiveSavedGroup" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<savedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list<string>, description: string, projects: list<string>, archived: bool, useEmptyListGroup: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups/($id)/unarchive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List revisions for a saved group
#
# GET /v1/saved-groups-revisions/{savedGroupId}
# operationId: getSavedGroupRevisions
export def "saved-groups-revisions list" [
  savedGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --skipPagination: string # If true, return all matching items and ignore limit/offset. Self-hosted only. Has no effect unless API_ALLOW_SKIP_PAGINATION is set to true or 1. (default: false)
  --status: string # Filter by revision status. Accepts a comma-separated list, or the literal `open` for non-merged/non-discarded revisions.
  --author: string
  --mine: string # If true, return only revisions authored by the calling user. Requires a user-scoped API key. Mutually exclusive with `author`.
]: nothing -> record<revisions: table<id: string, version: int, title: string, status: string, authorId: string, authorEmail: string, contributors: list, revertedFrom: string, reviews: list, activityLog: list, resolution: record, dateCreated: string, dateUpdated: string, baseSavedGroup: record, proposedSavedGroup: record, proposedChanges: list>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "skipPagination" $skipPagination "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "mine" $mine "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/saved-groups-revisions/($savedGroupId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a draft revision
#
# POST /v1/saved-groups-revisions/{savedGroupId}
# operationId: postSavedGroupRevision
export def "saved-groups-revisions post" [
  savedGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string
  --comment: string
]: any -> record<revision: record<id: string, version: int, title: string, status: string, authorId: string, authorEmail: string, contributors: list<string>, revertedFrom: string, reviews: list<record>, activityLog: list<record>, resolution: record<action: string, userId: string, dateCreated: string>, dateCreated: string, dateUpdated: string, baseSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedChanges: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups-revisions/($savedGroupId)")
  let body = {title: $title, comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the most recent active draft revision
#
# GET /v1/saved-groups-revisions/{savedGroupId}/latest
# operationId: getSavedGroupRevisionLatest
export def "saved-groups-revisions-latest get" [
  savedGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mine: string # If true, return only the most recent active draft authored by the calling user. Requires a user-scoped API key.
]: nothing -> record<revision: record<id: string, version: int, title: string, status: string, authorId: string, authorEmail: string, contributors: list<string>, revertedFrom: string, reviews: list<record>, activityLog: list<record>, resolution: record<action: string, userId: string, dateCreated: string>, dateCreated: string, dateUpdated: string, baseSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedChanges: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mine" $mine "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/saved-groups-revisions/($savedGroupId)/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single saved group revision
#
# GET /v1/saved-groups-revisions/{savedGroupId}/{version}
# operationId: getSavedGroupRevision
export def "saved-groups-revisions get" [
  savedGroupId: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<revision: record<id: string, version: int, title: string, status: string, authorId: string, authorEmail: string, contributors: list<string>, revertedFrom: string, reviews: list<record>, activityLog: list<record>, resolution: record<action: string, userId: string, dateCreated: string>, dateCreated: string, dateUpdated: string, baseSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedChanges: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups-revisions/($savedGroupId)/($version)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update saved group metadata in a draft revision
#
# PUT /v1/saved-groups-revisions/{savedGroupId}/{version}/metadata
# operationId: putSavedGroupRevisionMetadata
export def "saved-groups-revisions-metadata put" [
  savedGroupId: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revisionTitle: string
  --revisionComment: string
  --name: string
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization.
  --description: string
  --projects: list
]: any -> record<revision: record<id: string, version: int, title: string, status: string, authorId: string, authorEmail: string, contributors: list<string>, revertedFrom: string, reviews: list<record>, activityLog: list<record>, resolution: record<action: string, userId: string, dateCreated: string>, dateCreated: string, dateUpdated: string, baseSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedChanges: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups-revisions/($savedGroupId)/($version)/metadata")
  let body = {revisionTitle: $revisionTitle, revisionComment: $revisionComment, name: $name, owner: $owner, description: $description, projects: $projects} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update the condition of a condition saved group draft revision
#
# PUT /v1/saved-groups-revisions/{savedGroupId}/{version}/condition
# operationId: putSavedGroupRevisionCondition
export def "saved-groups-revisions-condition put" [
  savedGroupId: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revisionTitle: string
  --revisionComment: string
  condition: string # The JSON-encoded condition for the saved group
]: any -> record<revision: record<id: string, version: int, title: string, status: string, authorId: string, authorEmail: string, contributors: list<string>, revertedFrom: string, reviews: list<record>, activityLog: list<record>, resolution: record<action: string, userId: string, dateCreated: string>, dateCreated: string, dateUpdated: string, baseSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedChanges: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups-revisions/($savedGroupId)/($version)/condition")
  let body = {revisionTitle: $revisionTitle, revisionComment: $revisionComment, condition: $condition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace the values list in a list saved group draft revision
#
# PUT /v1/saved-groups-revisions/{savedGroupId}/{version}/values
# operationId: putSavedGroupRevisionValues
export def "saved-groups-revisions-values put" [
  savedGroupId: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revisionTitle: string
  --revisionComment: string
  values: list
]: any -> record<revision: record<id: string, version: int, title: string, status: string, authorId: string, authorEmail: string, contributors: list<string>, revertedFrom: string, reviews: list<record>, activityLog: list<record>, resolution: record<action: string, userId: string, dateCreated: string>, dateCreated: string, dateUpdated: string, baseSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedChanges: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups-revisions/($savedGroupId)/($version)/values")
  let body = {revisionTitle: $revisionTitle, revisionComment: $revisionComment, values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Stage an archive/unarchive in a draft revision
#
# PUT /v1/saved-groups-revisions/{savedGroupId}/{version}/archive
# operationId: putSavedGroupRevisionArchive
export def "saved-groups-revisions-archive put" [
  savedGroupId: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revisionTitle: string
  --revisionComment: string
  --archived: oneof<nothing, bool>
]: any -> record<revision: record<id: string, version: int, title: string, status: string, authorId: string, authorEmail: string, contributors: list<string>, revertedFrom: string, reviews: list<record>, activityLog: list<record>, resolution: record<action: string, userId: string, dateCreated: string>, dateCreated: string, dateUpdated: string, baseSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedChanges: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups-revisions/($savedGroupId)/($version)/archive")
  let body = {revisionTitle: $revisionTitle, revisionComment: $revisionComment, archived: $archived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Append items to a list saved group draft revision
#
# POST /v1/saved-groups-revisions/{savedGroupId}/{version}/items/add
# operationId: postSavedGroupRevisionItemsAdd
export def "saved-groups-revisions-items-add post" [
  savedGroupId: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revisionTitle: string
  --revisionComment: string
  items: list
]: any -> record<revision: record<id: string, version: int, title: string, status: string, authorId: string, authorEmail: string, contributors: list<string>, revertedFrom: string, reviews: list<record>, activityLog: list<record>, resolution: record<action: string, userId: string, dateCreated: string>, dateCreated: string, dateUpdated: string, baseSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedChanges: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups-revisions/($savedGroupId)/($version)/items/add")
  let body = {revisionTitle: $revisionTitle, revisionComment: $revisionComment, items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove items from a list saved group draft revision
#
# POST /v1/saved-groups-revisions/{savedGroupId}/{version}/items/remove
# operationId: postSavedGroupRevisionItemsRemove
export def "saved-groups-revisions-items-remove post" [
  savedGroupId: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revisionTitle: string
  --revisionComment: string
  items: list
]: any -> record<revision: record<id: string, version: int, title: string, status: string, authorId: string, authorEmail: string, contributors: list<string>, revertedFrom: string, reviews: list<record>, activityLog: list<record>, resolution: record<action: string, userId: string, dateCreated: string>, dateCreated: string, dateUpdated: string, baseSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedChanges: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups-revisions/($savedGroupId)/($version)/items/remove")
  let body = {revisionTitle: $revisionTitle, revisionComment: $revisionComment, items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request review for a draft revision
#
# POST /v1/saved-groups-revisions/{savedGroupId}/{version}/request-review
# operationId: postSavedGroupRevisionRequestReview
export def "saved-groups-revisions-request-review post" [
  savedGroupId: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<revision: record<id: string, version: int, title: string, status: string, authorId: string, authorEmail: string, contributors: list<string>, revertedFrom: string, reviews: list<record>, activityLog: list<record>, resolution: record<action: string, userId: string, dateCreated: string>, dateCreated: string, dateUpdated: string, baseSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedChanges: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups-revisions/($savedGroupId)/($version)/request-review")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Submit a review on a draft revision
#
# POST /v1/saved-groups-revisions/{savedGroupId}/{version}/submit-review
# operationId: postSavedGroupRevisionSubmitReview
export def "saved-groups-revisions-submit-review post" [
  savedGroupId: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  decision: string@decision-completer
  --comment: string
]: any -> record<revision: record<id: string, version: int, title: string, status: string, authorId: string, authorEmail: string, contributors: list<string>, revertedFrom: string, reviews: list<record>, activityLog: list<record>, resolution: record<action: string, userId: string, dateCreated: string>, dateCreated: string, dateUpdated: string, baseSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedChanges: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups-revisions/($savedGroupId)/($version)/submit-review")
  let body = {decision: $decision, comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get merge status for a draft revision
#
# GET /v1/saved-groups-revisions/{savedGroupId}/{version}/merge-status
# operationId: getSavedGroupRevisionMergeStatus
export def "saved-groups-revisions-merge-status get" [
  savedGroupId: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool, hasConflicts: bool, conflicts: table<field: string, baseValue: any, liveValue: any, proposedValue: any>, canAutoMerge: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups-revisions/($savedGroupId)/($version)/merge-status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rebase a draft revision onto the current live saved group
#
# POST /v1/saved-groups-revisions/{savedGroupId}/{version}/rebase
# operationId: postSavedGroupRevisionRebase
export def "saved-groups-revisions-rebase post" [
  savedGroupId: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conflictResolutions: record
  --customValues: record # Custom values to use for `union` strategy fields. Keyed by field name.
]: any -> record<revision: record<id: string, version: int, title: string, status: string, authorId: string, authorEmail: string, contributors: list<string>, revertedFrom: string, reviews: list<record>, activityLog: list<record>, resolution: record<action: string, userId: string, dateCreated: string>, dateCreated: string, dateUpdated: string, baseSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedChanges: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups-revisions/($savedGroupId)/($version)/rebase")
  let body = {conflictResolutions: $conflictResolutions, customValues: $customValues} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Publish a draft revision
#
# POST /v1/saved-groups-revisions/{savedGroupId}/{version}/publish
# operationId: postSavedGroupRevisionPublish
export def "saved-groups-revisions-publish post" [
  savedGroupId: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<revision: record<id: string, version: int, title: string, status: string, authorId: string, authorEmail: string, contributors: list<string>, revertedFrom: string, reviews: list<record>, activityLog: list<record>, resolution: record<action: string, userId: string, dateCreated: string>, dateCreated: string, dateUpdated: string, baseSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedChanges: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups-revisions/($savedGroupId)/($version)/publish")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Discard a draft revision
#
# POST /v1/saved-groups-revisions/{savedGroupId}/{version}/discard
# operationId: postSavedGroupRevisionDiscard
export def "saved-groups-revisions-discard post" [
  savedGroupId: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string
]: any -> record<revision: record<id: string, version: int, title: string, status: string, authorId: string, authorEmail: string, contributors: list<string>, revertedFrom: string, reviews: list<record>, activityLog: list<record>, resolution: record<action: string, userId: string, dateCreated: string>, dateCreated: string, dateUpdated: string, baseSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedChanges: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups-revisions/($savedGroupId)/($version)/discard")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revert the saved group to a prior revision
#
# POST /v1/saved-groups-revisions/{savedGroupId}/{version}/revert
# operationId: postSavedGroupRevisionRevert
export def "saved-groups-revisions-revert post" [
  savedGroupId: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --strategy: string@strategy-completer
  --title: string
  --comment: string
]: any -> record<revision: record<id: string, version: int, title: string, status: string, authorId: string, authorEmail: string, contributors: list<string>, revertedFrom: string, reviews: list<record>, activityLog: list<record>, resolution: record<action: string, userId: string, dateCreated: string>, dateCreated: string, dateUpdated: string, baseSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedSavedGroup: record<id: string, type: string, dateCreated: string, dateUpdated: string, name: string, owner: string, ownerEmail: string, condition: string, attributeKey: string, values: list, description: string, projects: list, archived: bool, useEmptyListGroup: bool>, proposedChanges: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved-groups-revisions/($savedGroupId)/($version)/revert")
  let body = {strategy: $strategy, title: $title, comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all organizations (only for super admins on multi-org Enterprise Plan only)
#
# GET /v1/organizations
# operationId: listOrganizations
export def "organizations listOrganizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search string to search organization names, owner emails, and external ids by
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
]: nothing -> record<organizations: table<id: string, externalId: string, dateCreated: string, name: string, ownerEmail: string>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single organization (only for super admins on multi-org Enterprise Plan only)
#
# POST /v1/organizations
# operationId: postOrganization
export def "organizations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the organization
  --externalId: string # An optional identifier that you use within your company for the organization
]: any -> record<organization: record<id: string, externalId: string, dateCreated: string, name: string, ownerEmail: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/organizations")
  let body = {name: $name, externalId: $externalId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Edit a single organization (only for super admins on multi-org Enterprise Plan only)
#
# PUT /v1/organizations/{id}
# operationId: putOrganization
export def "organizations put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the organization
  --externalId: string # An optional identifier that you use within your company for the organization
]: any -> record<organization: record<id: string, externalId: string, dateCreated: string, name: string, ownerEmail: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($id)")
  let body = {name: $name, externalId: $externalId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a SDK payload
#
# GET /v1/sdk-payload/{key}
# operationId: getSdkPayload
export def "sdk-payload get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sdk-payload/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all fact tables
#
# GET /v1/fact-tables
# operationId: listFactTables
export def "fact-tables listFactTables" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --datasourceId: string # Filter by Data Source
  --projectId: string # Filter by project id
]: nothing -> record<factTables: table<id: string, name: string, description: string, owner: string, ownerEmail: string, projects: list, tags: list, datasource: string, userIdTypes: list, aggregatedFactTableSettings: record, sql: string, eventName: string, columns: list, columnsError: any, archived: bool, managedBy: string, dateCreated: string, dateUpdated: string>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "datasourceId" $datasourceId "scalar") (serialize-qp "projectId" $projectId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/fact-tables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single fact table
#
# POST /v1/fact-tables
# operationId: postFactTable
# --aggregatedFactTableSettings shape: {idTypes: list, updateTime: record, lookbackWindow: int}
export def "fact-tables post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string # Description of the fact table
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization.
  --projects: list # List of associated project ids
  --tags: list # List of associated tags
  datasource: string # The datasource id
  userIdTypes: list # List of identifier columns in this table. For example, "id" or "anonymous_id"
  --aggregatedFactTableSettings: record # Settings for maintaining shared daily aggregated tables (a subset of userIdTypes plus the daily update time and restate lookback window) used to speed up CUPED. Requires the data pipeline (pipeline-mode) feature. — shape: {idTypes: list, updateTime: record, lookbackWindow: int}
  sql: string # The SQL query for this fact table
  --eventName: string # The event name used in SQL template variables
  --managedBy: string@managedBy-completer-1 # Set this to "api" to disable editing in the GrowthBook UI
]: any -> record<factTable: record<id: string, name: string, description: string, owner: string, ownerEmail: string, projects: list<string>, tags: list<string>, datasource: string, userIdTypes: list<string>, aggregatedFactTableSettings: record<idTypes: list, updateTime: record, lookbackWindow: int>, sql: string, eventName: string, columns: list<record>, columnsError: any, archived: bool, managedBy: string, dateCreated: string, dateUpdated: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/fact-tables")
  let body = {name: $name, description: $description, owner: $owner, projects: $projects, tags: $tags, datasource: $datasource, userIdTypes: $userIdTypes, aggregatedFactTableSettings: $aggregatedFactTableSettings, sql: $sql, eventName: $eventName, managedBy: $managedBy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single fact table
#
# GET /v1/fact-tables/{id}
# operationId: getFactTable
export def "fact-tables get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<factTable: record<id: string, name: string, description: string, owner: string, ownerEmail: string, projects: list<string>, tags: list<string>, datasource: string, userIdTypes: list<string>, aggregatedFactTableSettings: record<idTypes: list, updateTime: record, lookbackWindow: int>, sql: string, eventName: string, columns: list<record>, columnsError: any, archived: bool, managedBy: string, dateCreated: string, dateUpdated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fact-tables/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single fact table
#
# POST /v1/fact-tables/{id}
# operationId: updateFactTable
# --aggregatedFactTableSettings shape: {idTypes: list, updateTime: record, lookbackWindow: int}
# --columns item shape: {column: string, datatype: "number"|"string"|"date"|"boolean"|"json"|"binary"|"other"|"", numberFormat?: ""|"currency"|"time:seconds"|"memory:bytes"|"memory:kilobytes", jsonFields?: record, name?: string, description?: string, alwaysInlineFilter?: bool, deleted?: bool, isAutoSliceColumn?: bool, autoSlices?: list, lockedAutoSlices?: list}
export def "fact-tables updateFactTable" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: string # Description of the fact table
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization.
  --projects: list # List of associated project ids
  --tags: list # List of associated tags
  --userIdTypes: list # List of identifier columns in this table. For example, "id" or "anonymous_id"
  --aggregatedFactTableSettings: record # Settings for maintaining shared daily aggregated tables (a subset of userIdTypes plus the daily update time and restate lookback window) used to speed up CUPED. Requires the data pipeline (pipeline-mode) feature. — shape: {idTypes: list, updateTime: record, lookbackWindow: int}
  --sql: string # The SQL query for this fact table
  --eventName: string # The event name used in SQL template variables
  --columns: list # Optional array of columns that you want to update. Only allows updating properties of existing columns. Cannot create new columns or delete existing ones. Columns cannot be added or deleted; column structure is determined by SQL parsing. Slice-related properties require an enterprise license. — item shape: {column: string, datatype: "number"|"string"|"date"|"boolean"|"json"|"binary"|"other"|"", numberFormat?: ""|"currency"|"time:seconds"|"memory:bytes"|"memory:kilobytes", jsonFields?: record, name?: string, description?: string, alwaysInlineFilter?: bool, deleted?: bool, isAutoSliceColumn?: bool, autoSlices?: list, lockedAutoSlices?: list}
  --columnsError: any # Error message if there was an issue parsing the SQL schema
  --managedBy: string@managedBy-completer-1 # Set this to "api" to disable editing in the GrowthBook UI
  --archived: oneof<nothing, bool>
]: any -> record<factTable: record<id: string, name: string, description: string, owner: string, ownerEmail: string, projects: list<string>, tags: list<string>, datasource: string, userIdTypes: list<string>, aggregatedFactTableSettings: record<idTypes: list, updateTime: record, lookbackWindow: int>, sql: string, eventName: string, columns: list<record>, columnsError: any, archived: bool, managedBy: string, dateCreated: string, dateUpdated: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fact-tables/($id)")
  let body = {name: $name, description: $description, owner: $owner, projects: $projects, tags: $tags, userIdTypes: $userIdTypes, aggregatedFactTableSettings: $aggregatedFactTableSettings, sql: $sql, eventName: $eventName, columns: $columns, columnsError: $columnsError, managedBy: $managedBy, archived: $archived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a single fact table
#
# DELETE /v1/fact-tables/{id}
# operationId: deleteFactTable
export def "fact-tables delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fact-tables/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all filters for a fact table
#
# GET /v1/fact-tables/{factTableId}/filters
# operationId: listFactTableFilters
export def "fact-tables-filters listFactTableFilters" [
  factTableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
]: nothing -> record<factTableFilters: table<id: string, name: string, description: string, value: string, managedBy: string, dateCreated: string, dateUpdated: string>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/fact-tables/($factTableId)/filters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single fact table filter
#
# POST /v1/fact-tables/{factTableId}/filters
# operationId: postFactTableFilter
export def "fact-tables-filters post" [
  factTableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string # Description of the fact table filter
  value: string # The SQL expression for this filter. (e.g. country = 'US')
  --managedBy: string@managedBy-completer # Set this to "api" to disable editing in the GrowthBook UI. Before you do this, the Fact Table itself must also be marked as "api"
]: any -> record<factTableFilter: record<id: string, name: string, description: string, value: string, managedBy: string, dateCreated: string, dateUpdated: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fact-tables/($factTableId)/filters")
  let body = {name: $name, description: $description, value: $value, managedBy: $managedBy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single fact filter
#
# GET /v1/fact-tables/{factTableId}/filters/{id}
# operationId: getFactTableFilter
export def "fact-tables-filters get" [
  factTableId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<factTableFilter: record<id: string, name: string, description: string, value: string, managedBy: string, dateCreated: string, dateUpdated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fact-tables/($factTableId)/filters/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single fact table filter
#
# POST /v1/fact-tables/{factTableId}/filters/{id}
# operationId: updateFactTableFilter
export def "fact-tables-filters updateFactTableFilter" [
  factTableId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: string # Description of the fact table filter
  --value: string # The SQL expression for this filter. (e.g. country = 'US')
  --managedBy: string@managedBy-completer # Set this to "api" to disable editing in the GrowthBook UI. Before you do this, the Fact Table itself must also be marked as "api"
]: any -> record<factTableFilter: record<id: string, name: string, description: string, value: string, managedBy: string, dateCreated: string, dateUpdated: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fact-tables/($factTableId)/filters/($id)")
  let body = {name: $name, description: $description, value: $value, managedBy: $managedBy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a single fact table filter
#
# DELETE /v1/fact-tables/{factTableId}/filters/{id}
# operationId: deleteFactTableFilter
export def "fact-tables-filters delete" [
  factTableId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fact-tables/($factTableId)/filters/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the materialization status of a fact table's shared daily aggregated tables
#
# GET /v1/fact-tables/{id}/aggregated-tables
# operationId: getAggregatedFactTables
export def "fact-tables-aggregated-tables get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<aggregatedFactTables: table<idType: string, status: string, tableFullName: any, firstEventDate: any, lastEventDate: any, lastMaxTimestamp: any, lastError: any, dateUpdated: any, pendingRestate: bool, pendingRestateReason: any>, nextScheduledUpdate: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fact-tables/($id)/aggregated-tables")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Force a refresh or full restate of a fact table's shared daily aggregated tables
#
# POST /v1/fact-tables/{id}/aggregated-tables/refresh
# operationId: refreshAggregatedFactTable
export def "fact-tables-aggregated-tables-refresh refreshAggregatedFactTable" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idType: string # Limit the refresh to a single id type. If omitted, all of the fact table's aggregatedFactTableSettings.idTypes are refreshed.
  --fullRestate: oneof<nothing, bool> # Drop and recreate the table, re-scanning the retained window. This is significantly more expensive than the default incremental append (it scans ~2-3 months of history).
]: any -> record<queued: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fact-tables/($id)/aggregated-tables/refresh")
  let body = {idType: $idType, fullRestate: $fullRestate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all fact metrics
#
# GET /v1/fact-metrics
# operationId: listFactMetrics
export def "fact-metrics listFactMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --datasourceId: string # Filter by Data Source
  --projectId: string # Filter by project id
  --factTableId: string # Filter by Fact Table Id (for ratio metrics, we only look at the numerator)
]: nothing -> record<factMetrics: table<id: string, name: string, description: string, owner: string, ownerEmail: string, projects: list, tags: list, datasource: string, metricType: string, numerator: record, denominator: record, inverse: bool, quantileSettings: record, cappingSettings: record, windowSettings: record, priorSettings: record, regressionAdjustmentSettings: record, riskThresholdSuccess: float, riskThresholdDanger: float, displayAsPercentage: bool, minPercentChange: float, maxPercentChange: float, minSampleSize: float, targetMDE: float, managedBy: string, dateCreated: string, dateUpdated: string, archived: bool, metricAutoSlices: list>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "datasourceId" $datasourceId "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "factTableId" $factTableId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/fact-metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single fact metric
#
# POST /v1/fact-metrics
# operationId: postFactMetric
# --numerator shape: {factTableId: string, column?: string, aggregation?: "sum"|"max"|"count distinct"|"hll merge"|"kll merge", filters?: list, inlineFilters?: record, rowFilters?: list, aggregateFilterColumn?: string, aggregateFilter?: string}
# --denominator shape: {factTableId: string, column: string, aggregation?: "sum"|"max"|"count distinct"|"hll merge"|"kll merge", filters?: list, inlineFilters?: record, rowFilters?: list}
# --quantileSettings shape: {type: "event"|"unit", ignoreZeros: bool, quantile: float, quantileEventCountColumn?: string}
# --cappingSettings shape: {type: "none"|"absolute"|"percentile", value?: float, ignoreZeros?: bool}
# --windowSettings shape: {type: "none"|"conversion"|"lookback", delayHours?: float, delayValue?: float, delayUnit?: "minutes"|"hours"|"days"|"weeks", windowValue?: float, windowUnit?: "minutes"|"hours"|"days"|"weeks"}
# --priorSettings shape: {override: bool, proper: bool, mean: float, stddev: float}
# --regressionAdjustmentSettings shape: {override: bool, enabled?: bool, days?: float}
@deprecated --flag riskThresholdSuccess
@deprecated --flag riskThresholdDanger
export def "fact-metrics post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization.
  --projects: list
  --tags: list
  metricType: string@metricType-completer
  numerator: record # shape: {factTableId: string, column?: string, aggregation?: "sum"|"max"|"count distinct"|"hll merge"|"kll merge", filters?: list, inlineFilters?: record, rowFilters?: list, aggregateFilterColumn?: string, aggregateFilter?: string}
  --denominator: record # Only when metricType is 'ratio' — shape: {factTableId: string, column: string, aggregation?: "sum"|"max"|"count distinct"|"hll merge"|"kll merge", filters?: list, inlineFilters?: record, rowFilters?: list}
  --inverse: oneof<nothing, bool> # Set to true for things like Bounce Rate, where you want the metric to decrease
  --quantileSettings: record # Controls the settings for quantile metrics (mandatory if metricType is "quantile") — shape: {type: "event"|"unit", ignoreZeros: bool, quantile: float, quantileEventCountColumn?: string}
  --cappingSettings: record # Controls how outliers are handled — shape: {type: "none"|"absolute"|"percentile", value?: float, ignoreZeros?: bool}
  --windowSettings: record # Controls the conversion window for the metric — shape: {type: "none"|"conversion"|"lookback", delayHours?: float, delayValue?: float, delayUnit?: "minutes"|"hours"|"days"|"weeks", windowValue?: float, windowUnit?: "minutes"|"hours"|"days"|"weeks"}
  --priorSettings: record # Controls the bayesian prior for the metric. If omitted, organization defaults will be used. — shape: {override: bool, proper: bool, mean: float, stddev: float}
  --regressionAdjustmentSettings: record # Controls the regression adjustment (CUPED) settings for the metric — shape: {override: bool, enabled?: bool, days?: float}
  --riskThresholdSuccess: float # No longer used. Threshold for Risk to be considered low enough, as a proportion (e.g. put 0.0025 for 0.25%). <br/> Must be a non-negative number and must not be higher than `riskThresholdDanger`. (DEPRECATED)
  --riskThresholdDanger: float # No longer used. Threshold for Risk to be considered too high, as a proportion (e.g. put 0.0125 for 1.25%). <br/> Must be a non-negative number. (DEPRECATED)
  --displayAsPercentage: oneof<nothing, bool> # If true and the metric is a ratio or dailyParticipation metric, variation means will be displayed as a percentage. Defaults to true for dailyParticipation metrics and false for ratio metrics.
  --minPercentChange: float # Minimum percent change to consider uplift significant, as a proportion (e.g. put 0.005 for 0.5%)
  --maxPercentChange: float # Maximum percent change to consider uplift significant, as a proportion (e.g. put 0.5 for 50%)
  --minSampleSize: float
  --targetMDE: float # The percentage change that you want to reliably detect before ending an experiment, as a proportion (e.g. put 0.1 for 10%). This is used to estimate the "Days Left" for running experiments.
  --managedBy: string@managedBy-completer-1 # Set this to "api" to disable editing in the GrowthBook UI
  --metricAutoSlices: list # Array of slice column names that will be automatically included in metric analysis. This is an enterprise feature.
]: any -> record<factMetric: record<id: string, name: string, description: string, owner: string, ownerEmail: string, projects: list<string>, tags: list<string>, datasource: string, metricType: string, numerator: record<factTableId: string, column: string, aggregation: string, filters: list, inlineFilters: record, rowFilters: list, aggregateFilterColumn: string, aggregateFilter: string>, denominator: record<factTableId: string, column: string, filters: list, inlineFilters: record, rowFilters: list>, inverse: bool, quantileSettings: record<type: string, ignoreZeros: bool, quantile: float, quantileEventCountColumn: string>, cappingSettings: record<type: string, value: float, ignoreZeros: bool>, windowSettings: record<type: string, delayValue: float, delayUnit: string, windowValue: float, windowUnit: string>, priorSettings: record<override: bool, proper: bool, mean: float, stddev: float>, regressionAdjustmentSettings: record<override: bool, enabled: bool, days: float>, riskThresholdSuccess: float, riskThresholdDanger: float, displayAsPercentage: bool, minPercentChange: float, maxPercentChange: float, minSampleSize: float, targetMDE: float, managedBy: string, dateCreated: string, dateUpdated: string, archived: bool, metricAutoSlices: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/fact-metrics")
  let body = {name: $name, description: $description, owner: $owner, projects: $projects, tags: $tags, metricType: $metricType, numerator: $numerator, denominator: $denominator, inverse: $inverse, quantileSettings: $quantileSettings, cappingSettings: $cappingSettings, windowSettings: $windowSettings, priorSettings: $priorSettings, regressionAdjustmentSettings: $regressionAdjustmentSettings, riskThresholdSuccess: $riskThresholdSuccess, riskThresholdDanger: $riskThresholdDanger, displayAsPercentage: $displayAsPercentage, minPercentChange: $minPercentChange, maxPercentChange: $maxPercentChange, minSampleSize: $minSampleSize, targetMDE: $targetMDE, managedBy: $managedBy, metricAutoSlices: $metricAutoSlices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single fact metric
#
# GET /v1/fact-metrics/{id}
# operationId: getFactMetric
export def "fact-metrics get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<factMetric: record<id: string, name: string, description: string, owner: string, ownerEmail: string, projects: list<string>, tags: list<string>, datasource: string, metricType: string, numerator: record<factTableId: string, column: string, aggregation: string, filters: list, inlineFilters: record, rowFilters: list, aggregateFilterColumn: string, aggregateFilter: string>, denominator: record<factTableId: string, column: string, filters: list, inlineFilters: record, rowFilters: list>, inverse: bool, quantileSettings: record<type: string, ignoreZeros: bool, quantile: float, quantileEventCountColumn: string>, cappingSettings: record<type: string, value: float, ignoreZeros: bool>, windowSettings: record<type: string, delayValue: float, delayUnit: string, windowValue: float, windowUnit: string>, priorSettings: record<override: bool, proper: bool, mean: float, stddev: float>, regressionAdjustmentSettings: record<override: bool, enabled: bool, days: float>, riskThresholdSuccess: float, riskThresholdDanger: float, displayAsPercentage: bool, minPercentChange: float, maxPercentChange: float, minSampleSize: float, targetMDE: float, managedBy: string, dateCreated: string, dateUpdated: string, archived: bool, metricAutoSlices: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fact-metrics/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single fact metric
#
# POST /v1/fact-metrics/{id}
# operationId: updateFactMetric
# --numerator shape: {factTableId: string, column?: string, aggregation?: "sum"|"max"|"count distinct"|"hll merge"|"kll merge", filters?: list, inlineFilters?: record, rowFilters?: list, aggregateFilterColumn?: string, aggregateFilter?: string}
# --denominator shape: {factTableId: string, column: string, aggregation?: "sum"|"max"|"count distinct"|"hll merge"|"kll merge", filters?: list, inlineFilters?: record, rowFilters?: list}
# --quantileSettings shape: {type: "event"|"unit", ignoreZeros: bool, quantile: float, quantileEventCountColumn?: string}
# --cappingSettings shape: {type: "none"|"absolute"|"percentile", value?: float, ignoreZeros?: bool}
# --windowSettings shape: {type: "none"|"conversion"|"lookback", delayHours?: float, delayValue?: float, delayUnit?: "minutes"|"hours"|"days"|"weeks", windowValue?: float, windowUnit?: "minutes"|"hours"|"days"|"weeks"}
# --priorSettings shape: {override: bool, proper: bool, mean: float, stddev: float}
# --regressionAdjustmentSettings shape: {override: bool, enabled?: bool, days?: float}
@deprecated --flag riskThresholdSuccess
@deprecated --flag riskThresholdDanger
export def "fact-metrics updateFactMetric" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: string
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization.
  --projects: list
  --tags: list
  --metricType: string@metricType-completer
  --numerator: record # shape: {factTableId: string, column?: string, aggregation?: "sum"|"max"|"count distinct"|"hll merge"|"kll merge", filters?: list, inlineFilters?: record, rowFilters?: list, aggregateFilterColumn?: string, aggregateFilter?: string}
  --denominator: record # Only when metricType is 'ratio' — shape: {factTableId: string, column: string, aggregation?: "sum"|"max"|"count distinct"|"hll merge"|"kll merge", filters?: list, inlineFilters?: record, rowFilters?: list}
  --inverse: oneof<nothing, bool> # Set to true for things like Bounce Rate, where you want the metric to decrease
  --quantileSettings: record # Controls the settings for quantile metrics (mandatory if metricType is "quantile") — shape: {type: "event"|"unit", ignoreZeros: bool, quantile: float, quantileEventCountColumn?: string}
  --cappingSettings: record # Controls how outliers are handled — shape: {type: "none"|"absolute"|"percentile", value?: float, ignoreZeros?: bool}
  --windowSettings: record # Controls the conversion window for the metric — shape: {type: "none"|"conversion"|"lookback", delayHours?: float, delayValue?: float, delayUnit?: "minutes"|"hours"|"days"|"weeks", windowValue?: float, windowUnit?: "minutes"|"hours"|"days"|"weeks"}
  --priorSettings: record # Controls the bayesian prior for the metric. If omitted, organization defaults will be used. — shape: {override: bool, proper: bool, mean: float, stddev: float}
  --regressionAdjustmentSettings: record # Controls the regression adjustment (CUPED) settings for the metric — shape: {override: bool, enabled?: bool, days?: float}
  --riskThresholdSuccess: float # No longer used. Threshold for Risk to be considered low enough, as a proportion (e.g. put 0.0025 for 0.25%). <br/> Must be a non-negative number and must not be higher than `riskThresholdDanger`. (DEPRECATED)
  --riskThresholdDanger: float # No longer used. Threshold for Risk to be considered too high, as a proportion (e.g. put 0.0125 for 1.25%). <br/> Must be a non-negative number. (DEPRECATED)
  --displayAsPercentage: oneof<nothing, bool> # If true and the metric is a ratio or dailyParticipation metric, variation means will be displayed as a percentage. Defaults to true for dailyParticipation metrics and false for ratio metrics.
  --minPercentChange: float # Minimum percent change to consider uplift significant, as a proportion (e.g. put 0.005 for 0.5%)
  --maxPercentChange: float # Maximum percent change to consider uplift significant, as a proportion (e.g. put 0.5 for 50%)
  --minSampleSize: float
  --targetMDE: float
  --managedBy: string@managedBy-completer-1 # Set this to "api" to disable editing in the GrowthBook UI
  --archived: oneof<nothing, bool>
  --metricAutoSlices: list # Array of slice column names that will be automatically included in metric analysis. This is an enterprise feature.
]: any -> record<factMetric: record<id: string, name: string, description: string, owner: string, ownerEmail: string, projects: list<string>, tags: list<string>, datasource: string, metricType: string, numerator: record<factTableId: string, column: string, aggregation: string, filters: list, inlineFilters: record, rowFilters: list, aggregateFilterColumn: string, aggregateFilter: string>, denominator: record<factTableId: string, column: string, filters: list, inlineFilters: record, rowFilters: list>, inverse: bool, quantileSettings: record<type: string, ignoreZeros: bool, quantile: float, quantileEventCountColumn: string>, cappingSettings: record<type: string, value: float, ignoreZeros: bool>, windowSettings: record<type: string, delayValue: float, delayUnit: string, windowValue: float, windowUnit: string>, priorSettings: record<override: bool, proper: bool, mean: float, stddev: float>, regressionAdjustmentSettings: record<override: bool, enabled: bool, days: float>, riskThresholdSuccess: float, riskThresholdDanger: float, displayAsPercentage: bool, minPercentChange: float, maxPercentChange: float, minSampleSize: float, targetMDE: float, managedBy: string, dateCreated: string, dateUpdated: string, archived: bool, metricAutoSlices: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fact-metrics/($id)")
  let body = {name: $name, description: $description, owner: $owner, projects: $projects, tags: $tags, metricType: $metricType, numerator: $numerator, denominator: $denominator, inverse: $inverse, quantileSettings: $quantileSettings, cappingSettings: $cappingSettings, windowSettings: $windowSettings, priorSettings: $priorSettings, regressionAdjustmentSettings: $regressionAdjustmentSettings, riskThresholdSuccess: $riskThresholdSuccess, riskThresholdDanger: $riskThresholdDanger, displayAsPercentage: $displayAsPercentage, minPercentChange: $minPercentChange, maxPercentChange: $maxPercentChange, minSampleSize: $minSampleSize, targetMDE: $targetMDE, managedBy: $managedBy, archived: $archived, metricAutoSlices: $metricAutoSlices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a single fact metric
#
# DELETE /v1/fact-metrics/{id}
# operationId: deleteFactMetric
export def "fact-metrics delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fact-metrics/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a fact metric analysis
#
# POST /v1/fact-metrics/{id}/analysis
# operationId: postFactMetricAnalysis
export def "fact-metrics-analysis post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userIdType: string # The identifier type to use for the analysis. If not provided, defaults to the first available identifier type in the fact table.
  --lookbackDays: float # Number of days to look back for the analysis. Defaults to 30.
  --populationType: string@populationType-completer # The type of population to analyze. Defaults to 'factTable', meaning the analysis will return the metric value for all units found in the fact table.
  --populationId: any # The ID of the population (e.g., segment ID) when populationType is not 'factTable'. Defaults to null.
  --additionalNumeratorFilters: list # We support passing in adhoc filters for an analysis that don't live on the metric itself. These are in addition to the metric's filters. To use this, you can pass in an array of Fact Table Filter Ids.
  --additionalDenominatorFilters: list # We support passing in adhoc filters for an analysis that don't live on the metric itself. These are in addition to the metric's filters. To use this, you can pass in an array of Fact Table Filter Ids.
  --useCache: oneof<nothing, bool> # Whether to use a cached query if one exists. Defaults to true.
]: any -> record<metricAnalysis: record<id: string, status: string, settings: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fact-metrics/($id)/analysis")
  let body = {userIdType: $userIdType, lookbackDays: $lookbackDays, populationType: $populationType, populationId: $populationId, additionalNumeratorFilters: $additionalNumeratorFilters, additionalDenominatorFilters: $additionalDenominatorFilters, useCache: $useCache} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Bulk import fact tables, filters, and metrics
#
# POST /v1/bulk-import/facts
# operationId: postBulkImportFacts
# --factTables item shape: {id: string, data: record}
# --factTableFilters item shape: {factTableId: string, id: string, data: record}
# --factMetrics item shape: {id: string, data: record}
export def "bulk-import-facts post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --factTables: list # item shape: {id: string, data: record}
  --factTableFilters: list # item shape: {factTableId: string, id: string, data: record}
  --factMetrics: list # item shape: {id: string, data: record}
]: any -> record<success: bool, factTablesAdded: int, factTablesUpdated: int, factTableFiltersAdded: int, factTableFiltersUpdated: int, factMetricsAdded: int, factMetricsUpdated: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/bulk-import/facts")
  let body = {factTables: $factTables, factTableFilters: $factTableFilters, factMetrics: $factMetrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Submit list of code references
#
# POST /v1/code-refs
# operationId: postCodeRefs
# --refs item shape: {filePath: string, startingLineNumber: int, lines: string, flagKey: string, contentHash: string}
export def "code-refs post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deleteMissing: string@deleteMissing-completer # Whether to delete code references that are no longer present in the submitted data (default: false)
  branch: string
  repoName: string
  refs: list # item shape: {filePath: string, startingLineNumber: int, lines: string, flagKey: string, contentHash: string}
]: any -> record<featuresUpdated: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteMissing" $deleteMissing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/code-refs" $qp)
  let body = {branch: $branch, repoName: $repoName, refs: $refs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get list of all code references for the current organization
#
# GET /v1/code-refs
# operationId: listCodeRefs
export def "code-refs listCodeRefs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
]: nothing -> record<codeRefs: table<organization: string, dateUpdated: string, feature: string, repo: string, branch: string, platform: string, refs: list>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/code-refs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of code references for a single feature id
#
# GET /v1/code-refs/{id}
# operationId: getCodeRefs
export def "code-refs get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<codeRefs: table<organization: string, dateUpdated: string, feature: string, repo: string, branch: string, platform: string, refs: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/code-refs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all organization members
#
# GET /v1/members
# operationId: listMembers
export def "members listMembers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --userName: string # Name of the user.
  --userEmail: string # Email address of the user.
  --globalRole: string # Name of the global role
]: nothing -> record<members: table<id: string, name: string, email: string, globalRole: string, environments: list, limitAccessByEnvironment: bool, managedbyIdp: bool, teams: list, projectRoles: list, lastLoginDate: string, dateCreated: string, dateUpdated: string>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "userName" $userName "scalar") (serialize-qp "userEmail" $userEmail "scalar") (serialize-qp "globalRole" $globalRole "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a member's global role (including any enviroment restrictions, if applicable). Can also update a member's project roles if your plan supports it.
#
# POST /v1/members/{id}/role
# operationId: updateMemberRole
# --member shape: {role?: string, environments?: list, projectRoles?: list}
export def "members-role updateMemberRole" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  member: record # shape: {role?: string, environments?: list, projectRoles?: list}
]: any -> record<updatedMember: record<id: string, role: string, environments: list<string>, limitAccessByEnvironment: bool, projectRoles: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/members/($id)/role")
  let body = {member: $member} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes a single user from an organization
#
# DELETE /v1/members/{id}
# operationId: deleteMember
export def "members delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/members/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single query
#
# GET /v1/queries/{id}
# operationId: getQuery
export def "queries get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<query: record<id: string, organization: string, datasource: string, language: string, query: string, queryType: string, createdAt: string, startedAt: string, status: string, externalId: string, dependencies: list<string>, runAtEnd: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/queries/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get organization settings
#
# GET /v1/settings
# operationId: getSettings
export def "settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<settings: record<confidenceLevel: float, northStar: any, metricDefaults: record<priorSettings: record, minimumSampleSize: float, maxPercentageChange: float, minPercentageChange: float, targetMDE: float>, pastExperimentsMinLength: float, metricAnalysisDays: float, updateSchedule: any, multipleExposureMinPercent: float, defaultRole: record<role: string, limitAccessByEnvironment: bool, environments: list>, statsEngine: string, pValueThreshold: float, regressionAdjustmentEnabled: bool, regressionAdjustmentDays: float, sequentialTestingEnabled: bool, sequentialTestingTuningParameter: float, attributionModel: string, targetMDE: float, delayHours: float, windowType: string, windowHours: float, winRisk: float, loseRisk: float, secureAttributeSalt: string, killswitchConfirmation: bool, featureKillSwitchBehavior: string, requireReviews: list<record>, restApiBypassesReviews: bool, featureKeyExample: string, featureRegexValidator: string, banditScheduleValue: float, banditScheduleUnit: string, banditBurnInValue: float, banditBurnInUnit: string, experimentMinLengthDays: float, experimentMaxLengthDays: any, preferredEnvironment: any, maxMetricSliceLevels: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single Information Schema Table by id
#
# GET /v1/information-schema-tables/{tableId}
# operationId: getInformationSchemaTable
export def "information-schema-tables get" [
  tableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<informationSchemaTable: record<id: string, datasourceId: string, informationSchemaId: string, tableName: string, tableSchema: string, databaseName: string, columns: list<record>, refreshMS: float, dateCreated: string, dateUpdated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/information-schema-tables/($tableId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all rampSchedules
#
# GET /v1/ramp-schedules
# operationId: listRampSchedules
export def "ramp-schedules listRampSchedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --featureId: string
  --status: string@status-completer-1 # Filter by schedule status
]: nothing -> record<limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any, rampSchedules: table<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: list, startActions: list, steps: list, endActions: list, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "featureId" $featureId "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/ramp-schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a ramp schedule
#
# POST /v1/ramp-schedules
# operationId: postRampSchedule
# --steps item shape: {interval: any, actions?: list, approvalNotes?: any, monitored?: bool, holdConditions?: record}
# --startActions item shape: {targetType?: string, targetId?: string, patch: record}
# --endActions item shape: {targetType?: string, targetId?: string, patch: record}
# --lockdownConfig shape: {mode: "none"|"locked"}
export def "ramp-schedules post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --featureId: string
  --ruleId: string
  --environment: string
  --steps: list # item shape: {interval: any, actions?: list, approvalNotes?: any, monitored?: bool, holdConditions?: record}
  --startActions: list # item shape: {targetType?: string, targetId?: string, patch: record}
  --endActions: list # item shape: {targetType?: string, targetId?: string, patch: record}
  --startDate: any
  --cutoffDate: any
  --monitoringConfig: any
  --lockdownConfig: record # shape: {mode: "none"|"locked"}
  --experimentHealthAction: string@experimentHealthAction-completer
  --templateId: string
]: any -> record<rampSchedule: record<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: list<record>, startActions: list<record>, steps: list<record>, endActions: list<record>, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record<mode: string>, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ramp-schedules")
  let body = {name: $name, featureId: $featureId, ruleId: $ruleId, environment: $environment, steps: $steps, startActions: $startActions, endActions: $endActions, startDate: $startDate, cutoffDate: $cutoffDate, monitoringConfig: $monitoringConfig, lockdownConfig: $lockdownConfig, experimentHealthAction: $experimentHealthAction, templateId: $templateId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Start a ramp schedule
#
# POST /v1/ramp-schedules/{id}/actions/start
# operationId: startRampSchedule
export def "ramp-schedules-actions-start startRampSchedule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rampSchedule: record<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: list<record>, startActions: list<record>, steps: list<record>, endActions: list<record>, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record<mode: string>, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)/actions/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pause a ramp schedule
#
# POST /v1/ramp-schedules/{id}/actions/pause
# operationId: pauseRampSchedule
export def "ramp-schedules-actions-pause pauseRampSchedule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rampSchedule: record<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: list<record>, startActions: list<record>, steps: list<record>, endActions: list<record>, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record<mode: string>, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)/actions/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resume a paused ramp schedule
#
# POST /v1/ramp-schedules/{id}/actions/resume
# operationId: resumeRampSchedule
export def "ramp-schedules-actions-resume resumeRampSchedule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rampSchedule: record<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: list<record>, startActions: list<record>, steps: list<record>, endActions: list<record>, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record<mode: string>, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)/actions/resume")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Roll back a ramp schedule
#
# POST /v1/ramp-schedules/{id}/actions/rollback
# operationId: rollbackRampSchedule
export def "ramp-schedules-actions-rollback rollbackRampSchedule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string
]: any -> record<rampSchedule: record<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: list<record>, startActions: list<record>, steps: list<record>, endActions: list<record>, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record<mode: string>, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)/actions/rollback")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restart a terminal ramp schedule
#
# POST /v1/ramp-schedules/{id}/actions/restart
# operationId: restartRampSchedule
export def "ramp-schedules-actions-restart restartRampSchedule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rampSchedule: record<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: list<record>, startActions: list<record>, steps: list<record>, endActions: list<record>, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record<mode: string>, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)/actions/restart")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Jump to a specific step
#
# POST /v1/ramp-schedules/{id}/actions/jump
# operationId: jumpRampSchedule
export def "ramp-schedules-actions-jump jumpRampSchedule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  targetStepIndex: int # Zero-based index of the step to jump to; -1 = pre-start
]: any -> record<rampSchedule: record<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: list<record>, startActions: list<record>, steps: list<record>, endActions: list<record>, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record<mode: string>, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)/actions/jump")
  let body = {targetStepIndex: $targetStepIndex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Complete a ramp schedule immediately
#
# POST /v1/ramp-schedules/{id}/actions/complete
# operationId: completeRampSchedule
export def "ramp-schedules-actions-complete completeRampSchedule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --disableRule: oneof<nothing, bool>
]: any -> record<rampSchedule: record<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: list<record>, startActions: list<record>, steps: list<record>, endActions: list<record>, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record<mode: string>, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)/actions/complete")
  let body = {disableRule: $disableRule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Approve the current step
#
# POST /v1/ramp-schedules/{id}/actions/approve-step
# operationId: approveStepRampSchedule
export def "ramp-schedules-actions-approve-step approveStepRampSchedule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rampSchedule: record<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: list<record>, startActions: list<record>, steps: list<record>, endActions: list<record>, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record<mode: string>, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)/actions/approve-step")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a target rule to a ramp schedule
#
# POST /v1/ramp-schedules/{id}/actions/add-target
# operationId: addTargetRampSchedule
@deprecated --flag environment
export def "ramp-schedules-actions-add-target addTargetRampSchedule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  featureId: string
  ruleId: string
  --environment: string # Deprecated pre-v2 disambiguator; ignored on v2 rules where `rule.id` is uniquely sufficient. (DEPRECATED)
]: any -> record<rampSchedule: record<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: list<record>, startActions: list<record>, steps: list<record>, endActions: list<record>, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record<mode: string>, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)/actions/add-target")
  let body = {featureId: $featureId, ruleId: $ruleId, environment: $environment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a target rule from a ramp schedule
#
# POST /v1/ramp-schedules/{id}/actions/eject-target
# operationId: ejectTargetRampSchedule
@deprecated --flag environment
export def "ramp-schedules-actions-eject-target ejectTargetRampSchedule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --targetId: string # Target ID (from the targets array)
  --ruleId: string # Rule ID — use as an alternative to targetId
  --environment: string # Deprecated pre-v2 disambiguator. Optional when used with ruleId; omit on v2 ramps. (DEPRECATED)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)/actions/eject-target")
  let body = {targetId: $targetId, ruleId: $ruleId, environment: $environment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Advance to the next step, overriding any holds
#
# POST /v1/ramp-schedules/{id}/actions/advance
# operationId: apiAdvanceRampSchedule
export def "ramp-schedules-actions-advance apiAdvanceRampSchedule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason for advancing
  --force: oneof<nothing, bool> # Bypass a pending approval gate on the current step. Requires admin-level (`canBypassApprovalChecks`) permission. When omitted or `false`, a 409 is returned if the step has an unsatisfied `holdConditions.requiresApproval` gate.
]: any -> record<rampSchedule: record<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: list<record>, startActions: list<record>, steps: list<record>, endActions: list<record>, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record<mode: string>, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)/actions/advance")
  let body = {reason: $reason, force: $force} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get ramp schedule status summary
#
# GET /v1/ramp-schedules/{id}/status
# operationId: getRampScheduleStatus
export def "ramp-schedules-status get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, status: string, currentStepIndex: float, totalSteps: float, lockdownMode: string, startedAt: any, lastRollbackAt: any, lastRollbackReason: any, monitoring: record<enabled: bool, monitoringMode: string, autoUpdate: bool, effectiveAutoUpdate: bool, blockedReason: any, currentStepMonitored: bool, nextSnapshotAt: any, safeRolloutId: any>, healthSummary: record<safeToAdvance: bool, decision: string, decisionReason: string, signals: list<string>, snapshotAt: string, traffic: record<totalUsers: float, variationUnits: list, srm: record, multipleExposures: record>, metrics: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set ramp monitoring mode
#
# POST /v1/ramp-schedules/{id}/actions/set-monitoring-mode
# operationId: setMonitoringModeRampSchedule
export def "ramp-schedules-actions-set-monitoring-mode setMonitoringModeRampSchedule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  monitoringMode: string@monitoringMode-completer # `auto` schedules snapshots automatically while allowed by ramp state. `manual` disables agenda updates and relies on manual Update clicks.
]: any -> record<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: table<id: string, entityType: string, entityId: string, ruleId: any, environment: any, status: string, activatingRevisionVersion: any>, startActions: table<targetType: string, targetId: string, patch: record>, steps: table<interval: any, approvalNotes: any, monitored: bool, holdConditions: record, actions: list>, endActions: table<targetType: string, targetId: string, patch: record>, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record<mode: string>, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)/actions/set-monitoring-mode")
  let body = {monitoringMode: $monitoringMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Toggle automatic monitoring updates
#
# POST /v1/ramp-schedules/{id}/actions/set-auto-update
# operationId: setAutoUpdateRampSchedule
export def "ramp-schedules-actions-set-auto-update setAutoUpdateRampSchedule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Legacy alias for monitoring mode (`true` => auto, `false` => manual).
]: any -> record<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: table<id: string, entityType: string, entityId: string, ruleId: any, environment: any, status: string, activatingRevisionVersion: any>, startActions: table<targetType: string, targetId: string, patch: record>, steps: table<interval: any, approvalNotes: any, monitored: bool, holdConditions: record, actions: list>, endActions: table<targetType: string, targetId: string, patch: record>, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record<mode: string>, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)/actions/set-auto-update")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update ramp monitoring configuration
#
# PUT /v1/ramp-schedules/{id}/monitoring
# operationId: updateRampScheduleMonitoring
export def "ramp-schedules-monitoring updateRampScheduleMonitoring" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  datasourceId: string
  exposureQueryId: string
  guardrailMetricIds: list
  --signalMetricIds: list
  --updateScheduleMinutes: any
  --monitoringMode: string@monitoringMode-completer
  --autoUpdate: oneof<nothing, bool>
  --srmAction: string@srmAction-completer
  --noTrafficAction: string@noTrafficAction-completer
  --noTrafficGracePeriodHours: any # How long to wait for traffic before applying `noTrafficAction`. Defaults to 24 hours when null or not set.
  --multipleExposureAction: string@multipleExposureAction-completer
]: any -> record<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: table<id: string, entityType: string, entityId: string, ruleId: any, environment: any, status: string, activatingRevisionVersion: any>, startActions: table<targetType: string, targetId: string, patch: record>, steps: table<interval: any, approvalNotes: any, monitored: bool, holdConditions: record, actions: list>, endActions: table<targetType: string, targetId: string, patch: record>, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record<mode: string>, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)/monitoring")
  let body = {datasourceId: $datasourceId, exposureQueryId: $exposureQueryId, guardrailMetricIds: $guardrailMetricIds, signalMetricIds: $signalMetricIds, updateScheduleMinutes: $updateScheduleMinutes, monitoringMode: $monitoringMode, autoUpdate: $autoUpdate, srmAction: $srmAction, noTrafficAction: $noTrafficAction, noTrafficGracePeriodHours: $noTrafficGracePeriodHours, multipleExposureAction: $multipleExposureAction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update ramp lockdown configuration
#
# PUT /v1/ramp-schedules/{id}/lockdown
# operationId: updateRampScheduleLockdown
export def "ramp-schedules-lockdown updateRampScheduleLockdown" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  mode: string@mode-completer
]: any -> record<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: table<id: string, entityType: string, entityId: string, ruleId: any, environment: any, status: string, activatingRevisionVersion: any>, startActions: table<targetType: string, targetId: string, patch: record>, steps: table<interval: any, approvalNotes: any, monitored: bool, holdConditions: record, actions: list>, endActions: table<targetType: string, targetId: string, patch: record>, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record<mode: string>, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)/lockdown")
  let body = {mode: $mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update ramp schedule steps
#
# PUT /v1/ramp-schedules/{id}/steps
# operationId: updateRampScheduleSteps
# --steps item shape: {interval: any, monitored?: bool, holdConditions?: record, approvalNotes?: any}
export def "ramp-schedules-steps updateRampScheduleSteps" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  steps: list # Full replacement of the steps array. Step-level coverage patches (`actions`) are intentionally excluded — those require a revision publish because they change the SDK payload. Use the revision flow to modify coverage/targeting; use this endpoint to update monitoring flags and hold conditions. — item shape: {interval: any, monitored?: bool, holdConditions?: record, approvalNotes?: any}
]: any -> record<rampSchedule: record<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: list<record>, startActions: list<record>, steps: list<record>, endActions: list<record>, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record<mode: string>, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)/steps")
  let body = {steps: $steps} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Trigger a manual monitoring update
#
# POST /v1/ramp-schedules/{id}/actions/refresh-monitoring
# operationId: refreshMonitoringRampSchedule
export def "ramp-schedules-actions-refresh-monitoring refreshMonitoringRampSchedule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rampSchedule: record<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: list<record>, startActions: list<record>, steps: list<record>, endActions: list<record>, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record<mode: string>, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)/actions/refresh-monitoring")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all reports
#
# GET /v1/reports
# operationId: listReports
export def "reports listReports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
  --experimentId: string # Filter reports by experiment id
]: nothing -> record<reports: table<id: string, dateCreated: string, dateUpdated: string, title: string, description: string, type: string, status: string, shareLevel: string, shareUrl: string, experimentId: string, snapshotId: string, snapshotStatus: string, snapshotError: string, analysisSettings: record, experimentMetadata: record, results: record>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "experimentId" $experimentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new report
#
# POST /v1/reports
# operationId: postReport
# --metricOverrides item shape: {id: string, windowType?: "conversion"|"lookback"|"", windowHours?: float, delayHours?: float, winRisk?: float, loseRisk?: float, properPriorOverride?: bool, properPriorEnabled?: bool, properPriorMean?: float, properPriorStdDev?: float, regressionAdjustmentOverride?: bool, regressionAdjustmentEnabled?: bool, regressionAdjustmentDays?: float}
# --customMetricSlices item shape: {slices: list}
export def "reports post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  experimentId: string # The experiment to create a report for
  --title: string # Report title (defaults to experiment name)
  --description: string # Report description
  --statsEngine: string@statsEngine-completer # Stats engine override
  --goalMetrics: list # Goal metric IDs (defaults to experiment's goal metrics)
  --secondaryMetrics: list # Secondary metric IDs (defaults to experiment's secondary metrics)
  --guardrailMetrics: list # Guardrail metric IDs (defaults to experiment's guardrail metrics)
  --activationMetric: string # Activation metric ID
  --dimension: string # Dimension to cut results by
  --dateStarted: string # Analysis start date (ISO 8601) (format: date-time)
  --dateEnded: string # Analysis end date (ISO 8601) (format: date-time)
  --regressionAdjustmentEnabled: oneof<nothing, bool> # Enable CUPED regression adjustment
  --sequentialTestingEnabled: oneof<nothing, bool> # Enable sequential testing
  --sequentialTestingTuningParameter: float # Tuning parameter for sequential testing (frequentist only)
  --differenceType: string@differenceType-completer # How lifts are expressed in results. Defaults to experiment setting.
  --attributionModel: string@attributionModel-completer # Metric conversion window attribution model. Defaults to experiment setting.
  --lookbackOverride: any # Lookback window when `attributionModel` is `lookbackOverride`
  --metricOverrides: list # Per-metric window, risk, and regression-adjustment overrides — item shape: {id: string, windowType?: "conversion"|"lookback"|"", windowHours?: float, delayHours?: float, winRisk?: float, loseRisk?: float, properPriorOverride?: bool, properPriorEnabled?: bool, properPriorMean?: float, properPriorStdDev?: float, regressionAdjustmentOverride?: bool, regressionAdjustmentEnabled?: bool, regressionAdjustmentDays?: float}
  --customMetricSlices: list # Custom metric slice definitions — item shape: {slices: list}
  --segment: string # Segment ID to filter users by. Defaults to experiment setting.
  --queryFilter: string # Raw SQL WHERE clause added to the exposure query. Defaults to experiment setting.
  --skipPartialData: oneof<nothing, bool> # When true, exclude users who have not completed the full conversion window.
  --shareLevel: string@shareLevel-completer-1 # Visibility of the created report. Defaults to `private`. Set to `public` to receive a shareable `shareUrl` in the response.
]: any -> record<report: record<id: string, dateCreated: string, dateUpdated: string, title: string, description: string, type: string, status: string, shareLevel: string, shareUrl: string, experimentId: string, snapshotId: string, snapshotStatus: string, snapshotError: string, analysisSettings: record<statsEngine: string, goalMetrics: list, secondaryMetrics: list, guardrailMetrics: list, activationMetric: string, metricOverrides: list, customMetricSlices: list, dimension: string, differenceType: string, dateStarted: string, dateEnded: string, regressionAdjustmentEnabled: bool, sequentialTestingEnabled: bool, sequentialTestingTuningParameter: float, attributionModel: string, lookbackOverride: any, trackingKey: string, exposureQueryId: string, segment: string, queryFilter: string, skipPartialData: bool>, experimentMetadata: record<type: string, variations: list, phases: list>, results: record<id: string, dateUpdated: string, experimentId: string, phase: string, dateStart: string, dateEnd: string, dimension: record, settings: record, queryIds: list, results: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/reports")
  let body = {experimentId: $experimentId, title: $title, description: $description, statsEngine: $statsEngine, goalMetrics: $goalMetrics, secondaryMetrics: $secondaryMetrics, guardrailMetrics: $guardrailMetrics, activationMetric: $activationMetric, dimension: $dimension, dateStarted: $dateStarted, dateEnded: $dateEnded, regressionAdjustmentEnabled: $regressionAdjustmentEnabled, sequentialTestingEnabled: $sequentialTestingEnabled, sequentialTestingTuningParameter: $sequentialTestingTuningParameter, differenceType: $differenceType, attributionModel: $attributionModel, lookbackOverride: $lookbackOverride, metricOverrides: $metricOverrides, customMetricSlices: $customMetricSlices, segment: $segment, queryFilter: $queryFilter, skipPartialData: $skipPartialData, shareLevel: $shareLevel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single report
#
# GET /v1/reports/{id}
# operationId: getReport
export def "reports get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<report: record<id: string, dateCreated: string, dateUpdated: string, title: string, description: string, type: string, status: string, shareLevel: string, shareUrl: string, experimentId: string, snapshotId: string, snapshotStatus: string, snapshotError: string, analysisSettings: record<statsEngine: string, goalMetrics: list, secondaryMetrics: list, guardrailMetrics: list, activationMetric: string, metricOverrides: list, customMetricSlices: list, dimension: string, differenceType: string, dateStarted: string, dateEnded: string, regressionAdjustmentEnabled: bool, sequentialTestingEnabled: bool, sequentialTestingTuningParameter: float, attributionModel: string, lookbackOverride: any, trackingKey: string, exposureQueryId: string, segment: string, queryFilter: string, skipPartialData: bool>, experimentMetadata: record<type: string, variations: list, phases: list>, results: record<id: string, dateUpdated: string, experimentId: string, phase: string, dateStart: string, dateEnd: string, dimension: record, settings: record, queryIds: list, results: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/reports/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Refresh a report by re-running its analysis
#
# POST /v1/reports/{id}/refresh
# operationId: postReportRefresh
export def "reports-refresh post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<report: record<id: string, dateCreated: string, dateUpdated: string, title: string, description: string, type: string, status: string, shareLevel: string, shareUrl: string, experimentId: string, snapshotId: string, snapshotStatus: string, snapshotError: string, analysisSettings: record<statsEngine: string, goalMetrics: list, secondaryMetrics: list, guardrailMetrics: list, activationMetric: string, metricOverrides: list, customMetricSlices: list, dimension: string, differenceType: string, dateStarted: string, dateEnded: string, regressionAdjustmentEnabled: bool, sequentialTestingEnabled: bool, sequentialTestingTuningParameter: float, attributionModel: string, lookbackOverride: any, trackingKey: string, exposureQueryId: string, segment: string, queryFilter: string, skipPartialData: bool>, experimentMetadata: record<type: string, variations: list, phases: list>, results: record<id: string, dateUpdated: string, experimentId: string, phase: string, dateStart: string, dateEnd: string, dimension: record, settings: record, queryIds: list, results: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/reports/($id)/refresh")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update report metadata (title, description, visibility)
#
# PUT /v1/reports/{id}/metadata
# operationId: putReportMetadata
export def "reports-metadata put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # Report title
  --description: string # Report description
  --status: string@status-completer-2 # UI lifecycle marker for the report
  --shareLevel: string@shareLevel-completer-1 # Visibility of the report. Setting to `public` enables a shareable `shareUrl`; setting back to `organization` or `private` revokes public access (the share token is preserved, so re-publishing exposes the same URL).
  --editLevel: string@editLevel-completer # Who can edit the report in the GrowthBook UI. `organization` allows any org member with the `createAnalyses` permission; `private` restricts editing to the report owner.
]: any -> record<report: record<id: string, dateCreated: string, dateUpdated: string, title: string, description: string, type: string, status: string, shareLevel: string, shareUrl: string, experimentId: string, snapshotId: string, snapshotStatus: string, snapshotError: string, analysisSettings: record<statsEngine: string, goalMetrics: list, secondaryMetrics: list, guardrailMetrics: list, activationMetric: string, metricOverrides: list, customMetricSlices: list, dimension: string, differenceType: string, dateStarted: string, dateEnded: string, regressionAdjustmentEnabled: bool, sequentialTestingEnabled: bool, sequentialTestingTuningParameter: float, attributionModel: string, lookbackOverride: any, trackingKey: string, exposureQueryId: string, segment: string, queryFilter: string, skipPartialData: bool>, experimentMetadata: record<type: string, variations: list, phases: list>, results: record<id: string, dateUpdated: string, experimentId: string, phase: string, dateStart: string, dateEnd: string, dimension: record, settings: record, queryIds: list, results: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/reports/($id)/metadata")
  let body = {title: $title, description: $description, status: $status, shareLevel: $shareLevel, editLevel: $editLevel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update report analysis settings
#
# PUT /v1/reports/{id}/settings
# operationId: putReportSettings
# --metricOverrides item shape: {id: string, windowType?: "conversion"|"lookback"|"", windowHours?: float, delayHours?: float, winRisk?: float, loseRisk?: float, properPriorOverride?: bool, properPriorEnabled?: bool, properPriorMean?: float, properPriorStdDev?: float, regressionAdjustmentOverride?: bool, regressionAdjustmentEnabled?: bool, regressionAdjustmentDays?: float}
# --customMetricSlices item shape: {slices: list}
# --variations item shape: {id: string, name?: string, key?: string, weight?: float}
export def "reports-settings put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --statsEngine: string@statsEngine-completer # Stats engine override
  --goalMetrics: list # Goal metric IDs
  --secondaryMetrics: list # Secondary metric IDs
  --guardrailMetrics: list # Guardrail metric IDs
  --activationMetric: string # Activation metric ID
  --metricOverrides: list # Per-metric window, risk, and regression-adjustment overrides — item shape: {id: string, windowType?: "conversion"|"lookback"|"", windowHours?: float, delayHours?: float, winRisk?: float, loseRisk?: float, properPriorOverride?: bool, properPriorEnabled?: bool, properPriorMean?: float, properPriorStdDev?: float, regressionAdjustmentOverride?: bool, regressionAdjustmentEnabled?: bool, regressionAdjustmentDays?: float}
  --customMetricSlices: list # Custom metric slice definitions — item shape: {slices: list}
  --dimension: string # Dimension to cut results by
  --differenceType: string@differenceType-completer # How lifts are expressed in results
  --dateStarted: string # Analysis start date (ISO 8601) (format: date-time)
  --dateEnded: any # Analysis end date (ISO 8601). Pass `null` to clear the end date and analyze through today.
  --regressionAdjustmentEnabled: oneof<nothing, bool> # Enable CUPED regression adjustment
  --sequentialTestingEnabled: oneof<nothing, bool> # Enable sequential testing
  --sequentialTestingTuningParameter: float # Tuning parameter for sequential testing (frequentist only)
  --attributionModel: string@attributionModel-completer # Metric conversion window attribution model
  --lookbackOverride: any # Lookback window when `attributionModel` is `lookbackOverride`
  --segment: string # Segment ID to filter users by
  --queryFilter: string # Raw SQL WHERE clause added to the exposure query
  --skipPartialData: oneof<nothing, bool> # When true, exclude users who have not completed the full conversion window
  --variations: list # Override variation names, keys, or traffic weights used in this report. Weights are merged into the latest phase. Changes take effect on the next refresh. — item shape: {id: string, name?: string, key?: string, weight?: float}
  --coverage: float # Traffic coverage (0–1) for the latest phase. Used when computing scaled impact.
]: any -> record<report: record<id: string, dateCreated: string, dateUpdated: string, title: string, description: string, type: string, status: string, shareLevel: string, shareUrl: string, experimentId: string, snapshotId: string, snapshotStatus: string, snapshotError: string, analysisSettings: record<statsEngine: string, goalMetrics: list, secondaryMetrics: list, guardrailMetrics: list, activationMetric: string, metricOverrides: list, customMetricSlices: list, dimension: string, differenceType: string, dateStarted: string, dateEnded: string, regressionAdjustmentEnabled: bool, sequentialTestingEnabled: bool, sequentialTestingTuningParameter: float, attributionModel: string, lookbackOverride: any, trackingKey: string, exposureQueryId: string, segment: string, queryFilter: string, skipPartialData: bool>, experimentMetadata: record<type: string, variations: list, phases: list>, results: record<id: string, dateUpdated: string, experimentId: string, phase: string, dateStart: string, dateEnd: string, dimension: record, settings: record, queryIds: list, results: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/reports/($id)/settings")
  let body = {statsEngine: $statsEngine, goalMetrics: $goalMetrics, secondaryMetrics: $secondaryMetrics, guardrailMetrics: $guardrailMetrics, activationMetric: $activationMetric, metricOverrides: $metricOverrides, customMetricSlices: $customMetricSlices, dimension: $dimension, differenceType: $differenceType, dateStarted: $dateStarted, dateEnded: $dateEnded, regressionAdjustmentEnabled: $regressionAdjustmentEnabled, sequentialTestingEnabled: $sequentialTestingEnabled, sequentialTestingTuningParameter: $sequentialTestingTuningParameter, attributionModel: $attributionModel, lookbackOverride: $lookbackOverride, segment: $segment, queryFilter: $queryFilter, skipPartialData: $skipPartialData, variations: $variations, coverage: $coverage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all namespaces
#
# GET /v1/namespaces
# operationId: listNamespaces
export def "namespaces listNamespaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
]: nothing -> record<namespaces: table<id: string, displayName: string, description: string, status: string, format: string, hashAttribute: string, seed: string>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/namespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a namespace
#
# POST /v1/namespaces
# operationId: postNamespace
export def "namespaces post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  displayName: string # Human-readable display name. Must be unique within the organization.
  --description: string
  --status: string@status-completer-3
  --format: string@format-completer-1 # Namespace format. Defaults to 'multiRange', which supports multiple ranges per experiment and a configurable hash attribute.
  --hashAttribute: string # Required when format is 'multiRange'. The user attribute (e.g. 'id', 'device_id') used to assign users to namespace buckets.
]: any -> record<namespace: record<id: string, displayName: string, description: string, status: string, format: string, hashAttribute: string, seed: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/namespaces")
  let body = {displayName: $displayName, description: $description, status: $status, format: $format, hashAttribute: $hashAttribute} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single namespace
#
# GET /v1/namespaces/{id}
# operationId: getNamespace
export def "namespaces get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<namespace: record<id: string, displayName: string, description: string, status: string, format: string, hashAttribute: string, seed: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/namespaces/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a namespace
#
# PUT /v1/namespaces/{id}
# operationId: putNamespace
export def "namespaces put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string # Human-readable display name.
  --description: string # Namespace description.
  --status: string@status-completer-3 # Set to 'inactive' to disable the namespace.
  --hashAttribute: string # Only applies to multiRange namespaces. Changes which user attribute is used for bucket hashing going forward.
]: any -> record<namespace: record<id: string, displayName: string, description: string, status: string, format: string, hashAttribute: string, seed: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/namespaces/($id)")
  let body = {displayName: $displayName, description: $description, status: $status, hashAttribute: $hashAttribute} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a namespace
#
# DELETE /v1/namespaces/{id}
# operationId: deleteNamespace
export def "namespaces delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/namespaces/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get namespace membership
#
# GET /v1/namespaces/{id}/memberships
# operationId: getNamespaceMemberships
export def "namespaces-memberships get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of items to return (default: 10)
  --offset: int # How many items to skip (use in conjunction with limit for pagination) (default: 0)
]: nothing -> record<experiments: table<id: string, name: string, trackingKey: string, status: string, ranges: list>, limit: int, offset: int, count: int, total: int, hasMore: bool, nextOffset: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/namespaces/($id)/memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rotate namespace seed
#
# POST /v1/namespaces/{id}/rotateSeed
# operationId: postNamespaceRotateSeed
export def "namespaces-rotate-seed post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --seed: string # A specific value to use as the new seed. If omitted, a random value is generated.
]: any -> record<namespace: record<id: string, displayName: string, description: string, status: string, format: string, hashAttribute: string, seed: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/namespaces/($id)/rotateSeed")
  let body = {seed: $seed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/transform-copy
#
# operationId: postCopyTransform
export def "transform-copy post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  visualChangesetId: string
  copy: string
  mode: string@mode-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/transform-copy")
  let body = {visualChangesetId: $visualChangesetId, copy: $copy, mode: $mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/visual-editor/ai/edit
#
# operationId: postVisualEditorAIEdit
# --elementContext item shape: {selector: string, tagName: string, textSnippet: string, outerHTML: string, attrs: record, computedStyles?: record}
# --domDigest shape: {url: string, title: string, structural?: list, headings?: list, buttons?: list, links?: list, inputs?: list, images?: list}
# --conversationHistory item shape: {role: "user"|"assistant", text: string}
export def "visual-editor-ai-edit post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  prompt: string
  --elementContext: list # default: [] — item shape: {selector: string, tagName: string, textSnippet: string, outerHTML: string, attrs: record, computedStyles?: record}
  variationId: string
  visualChangesetId: string
  --domDigest: record # shape: {url: string, title: string, structural?: list, headings?: list, buttons?: list, links?: list, inputs?: list, images?: list}
  --conversationHistory: list # item shape: {role: "user"|"assistant", text: string}
  --locale: string
  --streamingMode: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/visual-editor/ai/edit")
  let body = {prompt: $prompt, elementContext: $elementContext, variationId: $variationId, visualChangesetId: $visualChangesetId, domDigest: $domDigest, conversationHistory: $conversationHistory, locale: $locale, streamingMode: $streamingMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/visual-editor/ai/edit/resume
#
# operationId: postVisualEditorAIEditResume
export def "visual-editor-ai-edit-resume post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  jobId: string
  callId: string
  --body-result: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/visual-editor/ai/edit/resume")
  let body = {jobId: $jobId, callId: $callId, result: $body_result} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/visual-editor/ai/suggestions
#
# operationId: postVisualEditorAISuggestions
# --pageHints shape: {url?: string, title?: string, description?: string, headings?: list}
export def "visual-editor-ai-suggestions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  visualChangesetId: string
  --pageHints: record # shape: {url?: string, title?: string, description?: string, headings?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/visual-editor/ai/suggestions")
  let body = {visualChangesetId: $visualChangesetId, pageHints: $pageHints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/visual-editor/ai/image-gen
#
# operationId: postVisualEditorAIImageGen
# --referenceImage shape: {data: string, mimeType: "image/png"|"image/jpeg"|"image/gif"|"image/webp"}
export def "visual-editor-ai-image-gen post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  prompt: string
  --aspectRatio: string
  --count: int
  visualChangesetId: string
  --referenceImage: record # shape: {data: string, mimeType: "image/png"|"image/jpeg"|"image/gif"|"image/webp"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/visual-editor/ai/image-gen")
  let body = {prompt: $prompt, aspectRatio: $aspectRatio, count: $count, visualChangesetId: $visualChangesetId, referenceImage: $referenceImage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/visual-editor/ai/promote-image
#
# operationId: postVisualEditorAIPromoteImage
export def "visual-editor-ai-promote-image post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  visualChangesetId: string
  filePath: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/visual-editor/ai/promote-image")
  let body = {visualChangesetId: $visualChangesetId, filePath: $filePath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/visual-editor/ai/upload-signed-url
#
# operationId: postVisualEditorAIUploadSignedUrl
export def "visual-editor-ai-upload-signed-url post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  contentType: string@contentType-completer-1
  visualChangesetId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/visual-editor/ai/upload-signed-url")
  let body = {contentType: $contentType, visualChangesetId: $visualChangesetId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/visual-editor/add-variant
#
# operationId: postVisualEditorAddVariant
export def "visual-editor-add-variant post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  visualChangesetId: string
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/visual-editor/add-variant")
  let body = {visualChangesetId: $visualChangesetId, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/visual-editor/create-experiment
#
# operationId: postVisualEditorCreateExperiment
# --urlPatterns item shape: {include?: bool, type?: "simple"|"regex", pattern: string}
export def "visual-editor-create-experiment post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  pageUrl: string # format: uri
  urlPatterns: list # item shape: {include?: bool, type?: "simple"|"regex", pattern: string}
  --project: string
  hashAttribute: string
  --hypothesis: string
  --description: string
  --type: string@type-completer # default: standard
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/visual-editor/create-experiment")
  let body = {name: $name, pageUrl: $pageUrl, urlPatterns: $urlPatterns, project: $project, hashAttribute: $hashAttribute, hypothesis: $hypothesis, description: $description, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/visual-editor/create-changeset
#
# operationId: postVisualEditorCreateChangeset
# --urlPatterns item shape: {include?: bool, type?: "simple"|"regex", pattern: string}
export def "visual-editor-create-changeset post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  visualChangesetId: string
  pageUrl: string # format: uri
  urlPatterns: list # item shape: {include?: bool, type?: "simple"|"regex", pattern: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/visual-editor/create-changeset")
  let body = {visualChangesetId: $visualChangesetId, pageUrl: $pageUrl, urlPatterns: $urlPatterns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/visual-editor/rename-experiment
#
# operationId: postVisualEditorRenameExperiment
export def "visual-editor-rename-experiment post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  visualChangesetId: string
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/visual-editor/rename-experiment")
  let body = {visualChangesetId: $visualChangesetId, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/visual-editor/bootstrap
#
# operationId: getVisualEditorBootstrap
export def "visual-editor-bootstrap get" [
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
  let full_url = (build-url $base "/v1/visual-editor/bootstrap")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/visual-editor/library/images
#
# operationId: getVisualEditorLibraryImages
export def "visual-editor-library-images get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/visual-editor/library/images" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single dashboard
#
# GET /v1/dashboards/{id}
# operationId: getDashboard
export def "dashboards get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dashboard: record<id: string, uid: string, organization: string, experimentId: string, isDefault: bool, isDeleted: bool, userId: string, editLevel: string, shareLevel: string, enableAutoUpdates: bool, updateSchedule: any, title: string, grid: record<cols: int, rowHeight: int>, projects: list<string>, nextUpdate: string, lastUpdated: string, dateCreated: string, dateUpdated: string, blocks: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dashboards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a single dashboard
#
# DELETE /v1/dashboards/{id}
# operationId: deleteDashboard
export def "dashboards delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dashboards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single dashboard
#
# PUT /v1/dashboards/{id}
# operationId: updateDashboard
export def "dashboards updateDashboard" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The display name of the Dashboard
  --editLevel: string@editLevel-completer-1 # Dashboards that are "published" are editable by organization members with appropriate permissions
  --shareLevel: string@shareLevel-completer-2 # General Dashboards only. Dashboards that are "published" are viewable by organization members with appropriate permissions
  --enableAutoUpdates: oneof<nothing, bool> # If enabled for a General Dashboard, also requires an updateSchedule
  --updateSchedule: any # General Dashboards only. Experiment Dashboards update based on the parent experiment instead
  --projects: list # General Dashboards only, Experiment Dashboards use the experiment's projects
  --blocks: list
]: any -> record<dashboard: record<id: string, uid: string, organization: string, experimentId: string, isDefault: bool, isDeleted: bool, userId: string, editLevel: string, shareLevel: string, enableAutoUpdates: bool, updateSchedule: any, title: string, grid: record<cols: int, rowHeight: int>, projects: list<string>, nextUpdate: string, lastUpdated: string, dateCreated: string, dateUpdated: string, blocks: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dashboards/($id)")
  let body = {title: $title, editLevel: $editLevel, shareLevel: $shareLevel, enableAutoUpdates: $enableAutoUpdates, updateSchedule: $updateSchedule, projects: $projects, blocks: $blocks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a single dashboard
#
# POST /v1/dashboards
# operationId: createDashboard
export def "dashboards createDashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string # The display name of the Dashboard
  editLevel: string@editLevel-completer-1 # Dashboards that are "published" are editable by organization members with appropriate permissions
  shareLevel: string@shareLevel-completer-2 # General Dashboards only. Dashboards that are "published" are viewable by organization members with appropriate permissions
  --enableAutoUpdates: oneof<nothing, bool> # If enabled for a General Dashboard, also requires an updateSchedule
  --updateSchedule: any # General Dashboards only. Experiment Dashboards update based on the parent experiment instead
  --experimentId: string # The parent experiment for an Experiment Dashboard, or undefined for a general dashboard
  --projects: list # General Dashboards only, Experiment Dashboards use the experiment's projects
  blocks: list
]: any -> record<dashboard: record<id: string, uid: string, organization: string, experimentId: string, isDefault: bool, isDeleted: bool, userId: string, editLevel: string, shareLevel: string, enableAutoUpdates: bool, updateSchedule: any, title: string, grid: record<cols: int, rowHeight: int>, projects: list<string>, nextUpdate: string, lastUpdated: string, dateCreated: string, dateUpdated: string, blocks: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dashboards")
  let body = {title: $title, editLevel: $editLevel, shareLevel: $shareLevel, enableAutoUpdates: $enableAutoUpdates, updateSchedule: $updateSchedule, experimentId: $experimentId, projects: $projects, blocks: $blocks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all dashboards
#
# GET /v1/dashboards
# operationId: listDashboards
export def "dashboards listDashboards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dashboards: table<id: string, uid: string, organization: string, experimentId: string, isDefault: bool, isDeleted: bool, userId: string, editLevel: string, shareLevel: string, enableAutoUpdates: bool, updateSchedule: any, title: string, grid: record, projects: list, nextUpdate: string, lastUpdated: string, dateCreated: string, dateUpdated: string, blocks: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dashboards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all dashboards for an experiment
#
# GET /v1/dashboards/by-experiment/{experimentId}
# operationId: getDashboardsForExperiment
export def "dashboards-by-experiment get" [
  experimentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dashboards: table<id: string, uid: string, organization: string, experimentId: string, isDefault: bool, isDeleted: bool, userId: string, editLevel: string, shareLevel: string, enableAutoUpdates: bool, updateSchedule: any, title: string, grid: record, projects: list, nextUpdate: string, lastUpdated: string, dateCreated: string, dateUpdated: string, blocks: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dashboards/by-experiment/($experimentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single customField
#
# POST /v1/custom-fields
# operationId: createCustomField
export def "custom-fields createCustomField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # The unique key for the custom field
  name: string # The display name of the custom field
  --description: string
  --placeholder: string
  --defaultValue: any
  type: string@type-completer-4 # The type of value this custom field will take
  --values: string
  --required: oneof<nothing, bool>
  --projects: list
  sections: list # What types of objects this custom field is applicable to (feature, experiment)
]: any -> record<customField: record<id: string, dateCreated: string, dateUpdated: string, name: string, description: string, placeholder: string, defaultValue: any, type: string, values: string, required: bool, creator: string, projects: list<string>, sections: list<string>, active: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/custom-fields")
  let body = {id: $id, name: $name, description: $description, placeholder: $placeholder, defaultValue: $defaultValue, type: $type, values: $values, required: $required, projects: $projects, sections: $sections} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all custom fields
#
# GET /v1/custom-fields
# operationId: listCustomFields
export def "custom-fields listCustomFields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --projectId: string
]: nothing -> table<id: string, dateCreated: string, dateUpdated: string, name: string, description: string, placeholder: string, defaultValue: any, type: string, values: string, required: bool, creator: string, projects: list<string>, sections: list<string>, active: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/custom-fields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a single customField
#
# DELETE /v1/custom-fields/{id}
# operationId: deleteCustomField
export def "custom-fields delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --index: string
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "index" $index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/custom-fields/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single customField
#
# GET /v1/custom-fields/{id}
# operationId: getCustomField
export def "custom-fields get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<customField: record<id: string, dateCreated: string, dateUpdated: string, name: string, description: string, placeholder: string, defaultValue: any, type: string, values: string, required: bool, creator: string, projects: list<string>, sections: list<string>, active: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/custom-fields/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single customField
#
# PUT /v1/custom-fields/{id}
# operationId: updateCustomField
export def "custom-fields updateCustomField" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The display name of the custom field
  --description: string
  --placeholder: string
  --defaultValue: any
  --values: string
  --required: oneof<nothing, bool>
  --projects: list
  --sections: list # What types of objects this custom field is applicable to (feature, experiment)
  --active: oneof<nothing, bool>
]: any -> record<customField: record<id: string, dateCreated: string, dateUpdated: string, name: string, description: string, placeholder: string, defaultValue: any, type: string, values: string, required: bool, creator: string, projects: list<string>, sections: list<string>, active: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/custom-fields/($id)")
  let body = {name: $name, description: $description, placeholder: $placeholder, defaultValue: $defaultValue, values: $values, required: $required, projects: $projects, sections: $sections, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single metricGroup
#
# GET /v1/metric-groups/{id}
# operationId: getMetricGroup
export def "metric-groups get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<metricGroup: record<id: string, dateCreated: string, dateUpdated: string, owner: string, ownerEmail: string, name: string, description: string, tags: list<string>, projects: list<string>, metrics: list<string>, datasource: string, archived: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/metric-groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a single metricGroup
#
# DELETE /v1/metric-groups/{id}
# operationId: deleteMetricGroup
export def "metric-groups delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/metric-groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single metricGroup
#
# PUT /v1/metric-groups/{id}
# operationId: updateMetricGroup
export def "metric-groups updateMetricGroup" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: string
  --tags: list
  --projects: list
  --metrics: list
  --datasource: string
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization.
  --archived: oneof<nothing, bool>
]: any -> record<metricGroup: record<id: string, dateCreated: string, dateUpdated: string, owner: string, ownerEmail: string, name: string, description: string, tags: list<string>, projects: list<string>, metrics: list<string>, datasource: string, archived: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/metric-groups/($id)")
  let body = {name: $name, description: $description, tags: $tags, projects: $projects, metrics: $metrics, datasource: $datasource, owner: $owner, archived: $archived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a single metricGroup
#
# POST /v1/metric-groups
# operationId: createMetricGroup
export def "metric-groups createMetricGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  description: string
  --tags: list
  projects: list
  metrics: list
  datasource: string
  --owner: string # The userId or email address of the owner. If an email address is provided, it will be used to look up the userId of the matching organization member. If an ID is provided, it will be validated as existing in the organization.
  --archived: oneof<nothing, bool>
]: any -> record<metricGroup: record<id: string, dateCreated: string, dateUpdated: string, owner: string, ownerEmail: string, name: string, description: string, tags: list<string>, projects: list<string>, metrics: list<string>, datasource: string, archived: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/metric-groups")
  let body = {name: $name, description: $description, tags: $tags, projects: $projects, metrics: $metrics, datasource: $datasource, owner: $owner, archived: $archived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all metricGroups
#
# GET /v1/metric-groups
# operationId: listMetricGroups
export def "metric-groups listMetricGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<metricGroups: table<id: string, dateCreated: string, dateUpdated: string, owner: string, ownerEmail: string, name: string, description: string, tags: list, projects: list, metrics: list, datasource: string, archived: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/metric-groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single team
#
# GET /v1/teams/{id}
# operationId: getTeam
export def "teams get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<team: record<id: string, dateCreated: string, dateUpdated: string, name: string, createdBy: string, description: string, role: string, limitAccessByEnvironment: bool, environments: list<string>, projectRoles: list<record>, members: list<string>, managedByIdp: bool, managedBy: any, defaultProject: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single team
#
# PUT /v1/teams/{id}
# operationId: updateTeam
# --projectRoles item shape: {role: string, limitAccessByEnvironment: bool, environments: list, teams?: list, project: string}
export def "teams updateTeam" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --createdBy: string
  --description: string
  --role: string # The global role for members of this team
  --limitAccessByEnvironment: oneof<nothing, bool>
  --environments: list # An empty array means 'all environments'
  --projectRoles: list # item shape: {role: string, limitAccessByEnvironment: bool, environments: list, teams?: list, project: string}
  --managedBy: any
  --defaultProject: string
]: any -> record<team: record<id: string, dateCreated: string, dateUpdated: string, name: string, createdBy: string, description: string, role: string, limitAccessByEnvironment: bool, environments: list<string>, projectRoles: list<record>, members: list<string>, managedByIdp: bool, managedBy: any, defaultProject: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($id)")
  let body = {name: $name, createdBy: $createdBy, description: $description, role: $role, limitAccessByEnvironment: $limitAccessByEnvironment, environments: $environments, projectRoles: $projectRoles, managedBy: $managedBy, defaultProject: $defaultProject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a single team
#
# DELETE /v1/teams/{id}
# operationId: deleteTeam
export def "teams delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deleteMembers: string # When 'true', enables deleting a team that contains members
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteMembers" $deleteMembers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single team
#
# POST /v1/teams
# operationId: createTeam
# --projectRoles item shape: {role: string, limitAccessByEnvironment: bool, environments: list, teams?: list, project: string}
export def "teams createTeam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --createdBy: string
  description: string
  role: string # The global role for members of this team
  --limitAccessByEnvironment: oneof<nothing, bool>
  --environments: list # An empty array means 'all environments'
  --projectRoles: list # item shape: {role: string, limitAccessByEnvironment: bool, environments: list, teams?: list, project: string}
  --managedBy: any
  --defaultProject: string
]: any -> record<team: record<id: string, dateCreated: string, dateUpdated: string, name: string, createdBy: string, description: string, role: string, limitAccessByEnvironment: bool, environments: list<string>, projectRoles: list<record>, members: list<string>, managedByIdp: bool, managedBy: any, defaultProject: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/teams")
  let body = {name: $name, createdBy: $createdBy, description: $description, role: $role, limitAccessByEnvironment: $limitAccessByEnvironment, environments: $environments, projectRoles: $projectRoles, managedBy: $managedBy, defaultProject: $defaultProject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all teams
#
# GET /v1/teams
# operationId: listTeams
export def "teams listTeams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<teams: table<id: string, dateCreated: string, dateUpdated: string, name: string, createdBy: string, description: string, role: string, limitAccessByEnvironment: bool, environments: list, projectRoles: list, members: list, managedByIdp: bool, managedBy: any, defaultProject: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/teams")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add members to team
#
# POST /v1/teams/{id}/members
# operationId: addTeamMembers
export def "teams-members addTeamMembers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  members: list
]: any -> record<status: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($id)/members")
  let body = {members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove members from team
#
# DELETE /v1/teams/{id}/members
# operationId: removeTeamMember
export def "teams-members removeTeamMember" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  members: list
]: any -> record<status: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($id)/members")
  let body = {members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single experimentTemplate
#
# GET /v1/experiment-templates/{id}
# operationId: getExperimentTemplate
export def "experiment-templates get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<experimentTemplate: record<id: string, dateCreated: string, dateUpdated: string, project: string, owner: string, ownerEmail: string, templateMetadata: record<name: string, description: string>, type: string, hypothesis: string, description: string, tags: list<string>, customFields: record, datasource: string, exposureQueryId: string, hashAttribute: string, fallbackAttribute: string, disableStickyBucketing: bool, goalMetrics: list<string>, secondaryMetrics: list<string>, guardrailMetrics: list<string>, activationMetric: string, statsEngine: string, segment: string, skipPartialData: bool, targeting: record<coverage: float, savedGroups: list, prerequisites: list, condition: string>, customMetricSlices: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/experiment-templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a single experimentTemplate
#
# DELETE /v1/experiment-templates/{id}
# operationId: deleteExperimentTemplate
export def "experiment-templates delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/experiment-templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single experimentTemplate
#
# PUT /v1/experiment-templates/{id}
# operationId: updateExperimentTemplate
# --templateMetadata shape: {name: string, description?: string}
# --targeting shape: {coverage: float, savedGroups?: list, prerequisites?: list, condition: string}
# --customMetricSlices item shape: {slices: list}
export def "experiment-templates updateExperimentTemplate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --project: string
  --templateMetadata: record # shape: {name: string, description?: string}
  --type: string@type-completer-5
  --hypothesis: string
  --description: string
  --tags: list
  --customFields: record
  --datasource: string
  --exposureQueryId: string
  --hashAttribute: string
  --fallbackAttribute: string
  --disableStickyBucketing: oneof<nothing, bool>
  --goalMetrics: list
  --secondaryMetrics: list
  --guardrailMetrics: list
  --activationMetric: string
  --statsEngine: string@statsEngine-completer
  --segment: string
  --skipPartialData: oneof<nothing, bool>
  --targeting: record # shape: {coverage: float, savedGroups?: list, prerequisites?: list, condition: string}
  --customMetricSlices: list # item shape: {slices: list}
]: any -> record<experimentTemplate: record<id: string, dateCreated: string, dateUpdated: string, project: string, owner: string, ownerEmail: string, templateMetadata: record<name: string, description: string>, type: string, hypothesis: string, description: string, tags: list<string>, customFields: record, datasource: string, exposureQueryId: string, hashAttribute: string, fallbackAttribute: string, disableStickyBucketing: bool, goalMetrics: list<string>, secondaryMetrics: list<string>, guardrailMetrics: list<string>, activationMetric: string, statsEngine: string, segment: string, skipPartialData: bool, targeting: record<coverage: float, savedGroups: list, prerequisites: list, condition: string>, customMetricSlices: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/experiment-templates/($id)")
  let body = {project: $project, templateMetadata: $templateMetadata, type: $type, hypothesis: $hypothesis, description: $description, tags: $tags, customFields: $customFields, datasource: $datasource, exposureQueryId: $exposureQueryId, hashAttribute: $hashAttribute, fallbackAttribute: $fallbackAttribute, disableStickyBucketing: $disableStickyBucketing, goalMetrics: $goalMetrics, secondaryMetrics: $secondaryMetrics, guardrailMetrics: $guardrailMetrics, activationMetric: $activationMetric, statsEngine: $statsEngine, segment: $segment, skipPartialData: $skipPartialData, targeting: $targeting, customMetricSlices: $customMetricSlices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a single experimentTemplate
#
# POST /v1/experiment-templates
# operationId: createExperimentTemplate
# --templateMetadata shape: {name: string, description?: string}
# --targeting shape: {coverage: float, savedGroups?: list, prerequisites?: list, condition: string}
# --customMetricSlices item shape: {slices: list}
export def "experiment-templates createExperimentTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --project: string
  templateMetadata: record # shape: {name: string, description?: string}
  type: string@type-completer-5
  --hypothesis: string
  --description: string
  --tags: list
  --customFields: record
  datasource: string
  exposureQueryId: string
  --hashAttribute: string
  --fallbackAttribute: string
  --disableStickyBucketing: oneof<nothing, bool>
  --goalMetrics: list
  --secondaryMetrics: list
  --guardrailMetrics: list
  --activationMetric: string
  statsEngine: string@statsEngine-completer
  --segment: string
  --skipPartialData: oneof<nothing, bool>
  targeting: record # shape: {coverage: float, savedGroups?: list, prerequisites?: list, condition: string}
  --customMetricSlices: list # item shape: {slices: list}
]: any -> record<experimentTemplate: record<id: string, dateCreated: string, dateUpdated: string, project: string, owner: string, ownerEmail: string, templateMetadata: record<name: string, description: string>, type: string, hypothesis: string, description: string, tags: list<string>, customFields: record, datasource: string, exposureQueryId: string, hashAttribute: string, fallbackAttribute: string, disableStickyBucketing: bool, goalMetrics: list<string>, secondaryMetrics: list<string>, guardrailMetrics: list<string>, activationMetric: string, statsEngine: string, segment: string, skipPartialData: bool, targeting: record<coverage: float, savedGroups: list, prerequisites: list, condition: string>, customMetricSlices: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/experiment-templates")
  let body = {project: $project, templateMetadata: $templateMetadata, type: $type, hypothesis: $hypothesis, description: $description, tags: $tags, customFields: $customFields, datasource: $datasource, exposureQueryId: $exposureQueryId, hashAttribute: $hashAttribute, fallbackAttribute: $fallbackAttribute, disableStickyBucketing: $disableStickyBucketing, goalMetrics: $goalMetrics, secondaryMetrics: $secondaryMetrics, guardrailMetrics: $guardrailMetrics, activationMetric: $activationMetric, statsEngine: $statsEngine, segment: $segment, skipPartialData: $skipPartialData, targeting: $targeting, customMetricSlices: $customMetricSlices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all experimentTemplates
#
# GET /v1/experiment-templates
# operationId: listExperimentTemplates
export def "experiment-templates listExperimentTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --projectId: string
]: nothing -> record<experimentTemplates: table<id: string, dateCreated: string, dateUpdated: string, project: string, owner: string, ownerEmail: string, templateMetadata: record, type: string, hypothesis: string, description: string, tags: list, customFields: record, datasource: string, exposureQueryId: string, hashAttribute: string, fallbackAttribute: string, disableStickyBucketing: bool, goalMetrics: list, secondaryMetrics: list, guardrailMetrics: list, activationMetric: string, statsEngine: string, segment: string, skipPartialData: bool, targeting: record, customMetricSlices: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/experiment-templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk create or update experiment templates
#
# POST /v1/experiment-templates/bulk-import
# operationId: bulkImportExperimentTemplates
# --templates item shape: {id: string, data: record}
export def "experiment-templates-bulk-import bulkImportExperimentTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  templates: list # item shape: {id: string, data: record}
]: any -> record<added: int, updated: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/experiment-templates/bulk-import")
  let body = {templates: $templates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a Metric based visualization
#
# POST /v1/product-analytics/metric-exploration
# operationId: postMetricExploration
# --dateRange shape: {predefined: "today"|"last7Days"|"last30Days"|"last90Days"|"customLookback"|"customDateRange", lookbackValue?: any, lookbackUnit?: any, startDate?: any, endDate?: any}
# --dataset shape: {type: string, values: list}
export def "product-analytics-metric-exploration post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache: string@cache-completer # Controls cache behavior for this exploration: `preferred` (default) returns a cached result if one exists, otherwise runs a new query; `never` always runs a new query, ignoring any cached results; `required` only returns a cached result, if none exists returns exploration: null with a message
  datasource: string # ID of the datasource to query
  dimensions: list
  chartType: string@chartType-completer
  dateRange: record # shape: {predefined: "today"|"last7Days"|"last30Days"|"last90Days"|"customLookback"|"customDateRange", lookbackValue?: any, lookbackUnit?: any, startDate?: any, endDate?: any}
  --showAs: string@showAs-completer
  type: string
  dataset: record # shape: {type: string, values: list}
]: any -> record<exploration: any, query: any, explorationUrl: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/product-analytics/metric-exploration" $qp)
  let body = {datasource: $datasource, dimensions: $dimensions, chartType: $chartType, dateRange: $dateRange, showAs: $showAs, type: $type, dataset: $dataset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Run a Fact Table based visualization
#
# POST /v1/product-analytics/fact-table-exploration
# operationId: postFactTableExploration
# --dateRange shape: {predefined: "today"|"last7Days"|"last30Days"|"last90Days"|"customLookback"|"customDateRange", lookbackValue?: any, lookbackUnit?: any, startDate?: any, endDate?: any}
# --dataset shape: {type: string, factTableId: any, values: list}
export def "product-analytics-fact-table-exploration post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache: string@cache-completer # Controls cache behavior for this exploration: `preferred` (default) returns a cached result if one exists, otherwise runs a new query; `never` always runs a new query, ignoring any cached results; `required` only returns a cached result, if none exists returns exploration: null with a message
  datasource: string # ID of the datasource to query
  dimensions: list
  chartType: string@chartType-completer
  dateRange: record # shape: {predefined: "today"|"last7Days"|"last30Days"|"last90Days"|"customLookback"|"customDateRange", lookbackValue?: any, lookbackUnit?: any, startDate?: any, endDate?: any}
  --showAs: string@showAs-completer
  type: string
  dataset: record # shape: {type: string, factTableId: any, values: list}
]: any -> record<exploration: any, query: any, explorationUrl: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/product-analytics/fact-table-exploration" $qp)
  let body = {datasource: $datasource, dimensions: $dimensions, chartType: $chartType, dateRange: $dateRange, showAs: $showAs, type: $type, dataset: $dataset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a Data Source based visualization
#
# POST /v1/product-analytics/data-source-exploration
# operationId: postDataSourceExploration
# --dateRange shape: {predefined: "today"|"last7Days"|"last30Days"|"last90Days"|"customLookback"|"customDateRange", lookbackValue?: any, lookbackUnit?: any, startDate?: any, endDate?: any}
# --dataset shape: {type: string, table: string, path: string, timestampColumn: string, columnTypes: record, values: list}
export def "product-analytics-data-source-exploration post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache: string@cache-completer # Controls cache behavior for this exploration: `preferred` (default) returns a cached result if one exists, otherwise runs a new query; `never` always runs a new query, ignoring any cached results; `required` only returns a cached result, if none exists returns exploration: null with a message
  datasource: string # ID of the datasource to query
  dimensions: list
  chartType: string@chartType-completer
  dateRange: record # shape: {predefined: "today"|"last7Days"|"last30Days"|"last90Days"|"customLookback"|"customDateRange", lookbackValue?: any, lookbackUnit?: any, startDate?: any, endDate?: any}
  --showAs: string@showAs-completer
  type: string
  dataset: record # shape: {type: string, table: string, path: string, timestampColumn: string, columnTypes: record, values: list}
]: any -> record<exploration: any, query: any, explorationUrl: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/product-analytics/data-source-exploration" $qp)
  let body = {datasource: $datasource, dimensions: $dimensions, chartType: $chartType, dateRange: $dateRange, showAs: $showAs, type: $type, dataset: $dataset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single rampScheduleTemplate
#
# GET /v1/ramp-schedule-templates/{id}
# operationId: getRampScheduleTemplate
export def "ramp-schedule-templates get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rampScheduleTemplate: record<id: string, dateCreated: string, dateUpdated: string, name: string, steps: list<record>, endPatch: record<coverage: float, condition: string, savedGroups: list, prerequisites: list, allEnvironments: bool, environments: list>, official: bool, monitoringConfig: any, lockdownConfig: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedule-templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a single rampScheduleTemplate
#
# DELETE /v1/ramp-schedule-templates/{id}
# operationId: deleteRampScheduleTemplate
export def "ramp-schedule-templates delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedule-templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single rampScheduleTemplate
#
# PUT /v1/ramp-schedule-templates/{id}
# operationId: updateRampScheduleTemplate
# --steps item shape: {interval: any, approvalNotes?: any, monitored?: bool, holdConditions?: record, actions: list}
# --endPatch shape: {coverage?: float, condition?: string, savedGroups?: list, prerequisites?: list, allEnvironments?: bool, environments?: list}
# --lockdownConfig shape: {mode: "none"|"locked"}
export def "ramp-schedule-templates updateRampScheduleTemplate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --steps: list # item shape: {interval: any, approvalNotes?: any, monitored?: bool, holdConditions?: record, actions: list}
  --endPatch: record # shape: {coverage?: float, condition?: string, savedGroups?: list, prerequisites?: list, allEnvironments?: bool, environments?: list}
  --official: oneof<nothing, bool>
  --monitoringConfig: any
  --lockdownConfig: record # shape: {mode: "none"|"locked"}
]: any -> record<rampScheduleTemplate: record<id: string, dateCreated: string, dateUpdated: string, name: string, steps: list<record>, endPatch: record<coverage: float, condition: string, savedGroups: list, prerequisites: list, allEnvironments: bool, environments: list>, official: bool, monitoringConfig: any, lockdownConfig: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedule-templates/($id)")
  let body = {name: $name, steps: $steps, endPatch: $endPatch, official: $official, monitoringConfig: $monitoringConfig, lockdownConfig: $lockdownConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a single rampScheduleTemplate
#
# POST /v1/ramp-schedule-templates
# operationId: createRampScheduleTemplate
# --steps item shape: {interval: any, approvalNotes?: any, monitored?: bool, holdConditions?: record, actions: list}
# --endPatch shape: {coverage?: float, condition?: string, savedGroups?: list, prerequisites?: list, allEnvironments?: bool, environments?: list}
# --lockdownConfig shape: {mode: "none"|"locked"}
export def "ramp-schedule-templates createRampScheduleTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  steps: list # item shape: {interval: any, approvalNotes?: any, monitored?: bool, holdConditions?: record, actions: list}
  --endPatch: record # shape: {coverage?: float, condition?: string, savedGroups?: list, prerequisites?: list, allEnvironments?: bool, environments?: list}
  --official: oneof<nothing, bool>
  --monitoringConfig: any
  --lockdownConfig: record # shape: {mode: "none"|"locked"}
]: any -> record<rampScheduleTemplate: record<id: string, dateCreated: string, dateUpdated: string, name: string, steps: list<record>, endPatch: record<coverage: float, condition: string, savedGroups: list, prerequisites: list, allEnvironments: bool, environments: list>, official: bool, monitoringConfig: any, lockdownConfig: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ramp-schedule-templates")
  let body = {name: $name, steps: $steps, endPatch: $endPatch, official: $official, monitoringConfig: $monitoringConfig, lockdownConfig: $lockdownConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all rampScheduleTemplates
#
# GET /v1/ramp-schedule-templates
# operationId: listRampScheduleTemplates
export def "ramp-schedule-templates listRampScheduleTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rampScheduleTemplates: table<id: string, dateCreated: string, dateUpdated: string, name: string, steps: list, endPatch: record, official: bool, monitoringConfig: any, lockdownConfig: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ramp-schedule-templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single rampSchedule
#
# GET /v1/ramp-schedules/{id}
# operationId: getRampSchedule
export def "ramp-schedules get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rampSchedule: record<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: list<record>, startActions: list<record>, steps: list<record>, endActions: list<record>, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record<mode: string>, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a single rampSchedule
#
# DELETE /v1/ramp-schedules/{id}
# operationId: deleteRampSchedule
export def "ramp-schedules delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single rampSchedule
#
# PUT /v1/ramp-schedules/{id}
# operationId: updateRampSchedule
# --steps item shape: {interval: any, actions?: list, approvalNotes?: any, monitored?: bool, holdConditions?: record}
# --startActions item shape: {targetType?: string, targetId?: string, patch?: record}
# --endActions item shape: {targetType?: string, targetId?: string, patch?: record}
# --lockdownConfig shape: {mode: "none"|"locked"}
export def "ramp-schedules updateRampSchedule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --steps: list # item shape: {interval: any, actions?: list, approvalNotes?: any, monitored?: bool, holdConditions?: record}
  --startActions: list # item shape: {targetType?: string, targetId?: string, patch?: record}
  --endActions: list # item shape: {targetType?: string, targetId?: string, patch?: record}
  --startDate: any
  --cutoffDate: any
  --monitoringConfig: any
  --experimentHealthAction: string@experimentHealthAction-completer
  --lockdownConfig: record # When mode is 'locked', blocks all feature edits while the ramp is actively running. — shape: {mode: "none"|"locked"}
]: any -> record<rampSchedule: record<id: string, dateCreated: string, dateUpdated: string, name: string, entityType: string, entityId: string, targets: list<record>, startActions: list<record>, steps: list<record>, endActions: list<record>, startDate: any, cutoffDate: any, status: string, currentStepIndex: int, startedAt: any, phaseStartedAt: any, pausedAt: any, nextStepAt: any, nextProcessAt: any, elapsedMs: any, lockdownConfig: record<mode: string>, monitoringConfig: any, experimentHealthAction: string, currentStepEnteredAt: any, stepApproval: any, monitoringStartDate: any, lastRollbackAt: any, lastRollbackReason: any, monitoringStatus: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ramp-schedules/($id)")
  let body = {name: $name, steps: $steps, startActions: $startActions, endActions: $endActions, startDate: $startDate, cutoffDate: $cutoffDate, monitoringConfig: $monitoringConfig, experimentHealthAction: $experimentHealthAction, lockdownConfig: $lockdownConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
