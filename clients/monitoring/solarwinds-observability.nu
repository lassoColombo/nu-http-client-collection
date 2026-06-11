# Auto-generated client for SolarWinds Observability v1.0.16
# Source: https://api.na-01.cloud.solarwinds.com/v1/openapi.json
# Auth: --token flag or $env.SOLARWINDS_OBSERVABILITY_TOKEN

const BASE_URL = "https://api.na-01.cloud.solarwinds.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SOLARWINDS_OBSERVABILITY_TOKEN | default "" }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.na-01.cloud.solarwinds.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def direction-completer [] { ["backward" "forward" "tail"] }
def status-completer [] { ["down" "up" "up,down"] }
def aggregateBy-completer [] { ["AVG" "COUNT" "LAST" "MAX" "MIN" "SUM"] }
def preGroupByMethod-completer [] { ["AVG" "COUNT" "LAST" "MAX" "MIN" "SUM"] }
def seriesType-completer [] { ["SCALAR" "TIMESERIES"] }
def type-completer [] { ["ingestion"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "changeevents createChangeEvent" } } | get name | first)
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

# Create an event
#
# POST /v1/changeevents
# operationId: createChangeEvent
# --links item shape: {rel: string, href: string, label?: string}
export def "changeevents createChangeEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # Optional ID of the event. It is recommended to leave this empty when creating a new event so that a unique ID will be generated (format: int64, e.g. 1731676626)
  name: string # The name of the event. Can be used as a category or type of event. Does not need to be unique. (e.g. app-deploys)
  title: string # A short, high-level summary of the event. (e.g. deployed v45)
  --timestamp: int # Timestamp of the event in seconds since the epoch. Defaults to the current time. (format: int64, e.g. 1731676626)
  --body-source: string # Description of the event's origination. For example, a hostname, user, or application name. (e.g. foo3.example.com)
  --description: string # Extra metadata about the event describing the specifics of the event.
  --parentEventId: int # The id of the parent event (format: int64)
  --tags: record # A set of key-value pairs that describe the event (e.g. {app: foo, environment: production})
  --links: list # A set of links to related resources (e.g. [{href: https://example.com, rel: self}]) — item shape: {rel: string, href: string, label?: string}
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/changeevents")
  let body = {id: $id, name: $name, title: $title, timestamp: $timestamp, source: $body_source, description: $description, parentEventId: $parentEventId, tags: $tags, links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Activate AWS Integration
#
# POST /v1/cloud/aws/controlTower/activate
# operationId: activateAwsIntegration
export def "cloud-aws-control-tower-activate activateAwsIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  managementAccountId: string # AWS Control Tower Management Account ID.
  accountId: string # AWS Accounts ID to be integrated.
  --enable: string@bool-completer # True to enable the integration, false to disable.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/cloud/aws/controlTower/activate")
  let body = {managementAccountId: $managementAccountId, accountId: $accountId, enable: $enable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Organizational Structure
#
# POST /v1/cloud/aws/controlTower/createOrgStructure
# operationId: createOrgStructure
# --structure item shape: {child_id: string, child_name: string, parent_id?: string}
export def "cloud-aws-control-tower-create-org-structure createOrgStructure" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  mgmtAccountId: string # AWS Control Tower Management Account ID.
  structure: list # Organisational Structure of the AWS Account. — item shape: {child_id: string, child_name: string, parent_id?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/cloud/aws/controlTower/createOrgStructure")
  let body = {mgmtAccountId: $mgmtAccountId, structure: $structure} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update AWS Integration
#
# POST /v1/cloud/aws/controlTower/update
# operationId: updateAwsIntegration
export def "cloud-aws-control-tower-update updateAwsIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  managementAccountId: string # AWS Control Tower Management Account ID.
  accountId: string # AWS Accounts ID to be integrated.
  accountName: string # Name of the AWS Account.
  roleArn: string # Role ARN to be assumed by the AWS Account.
  --orgUnitId: string # AWS Account ID.
  --orgUnitName: string # AWS Organizational Unit Name.
  --parentOrgUnitId: string # Immediate Parent Organization Unit ID of the AWS Account to be integrated.
]: any -> record<selectedRegions: list<string>, externalId: string, integrationId: string, integrationType: string, isNewAccount: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/cloud/aws/controlTower/update")
  let body = {managementAccountId: $managementAccountId, accountId: $accountId, accountName: $accountName, roleArn: $roleArn, orgUnitId: $orgUnitId, orgUnitName: $orgUnitName, parentOrgUnitId: $parentOrgUnitId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate Management Account Onboarding
#
# GET /v1/cloud/aws/controlTower/validateOnboarding
# operationId: validateMgmtAccountOnboarding
export def "cloud-aws-control-tower-validate-onboarding validateMgmtAccountOnboarding" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  managementAccountId: string # AWS Control Tower Management Account ID.
]: any -> record<isOnboarded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/cloud/aws/controlTower/validateOnboarding")
  let body = {managementAccountId: $managementAccountId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add database observability to a database
#
# POST /v1/dbo/databases
# operationId: observeDatabase
# --configOptions item shape: {key: string, value: string}
# --tags item shape: {key: string, value: string}
export def "dbo-databases observeDatabase" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name for the observed database entity
  agentId: string # Swo Agent ID where the plugin(s) for observing database server should run
  dbType: any # Database server type: mysql/mongo/mssql/pgsql/redis
  authMethod: any # Auth method to be used by the agent to connect to database server
  --captureMethod: any # Method for capturing metrics from database server: sniffer/poll/profiler/slow-log, ignored for SqlServer and Redis Sniffer is supported for mysql, mongo, redis and pgsql. Poll is supported for mysql, mssql, pgsql. profiler and slow-log are supported for mongo.
  --configOptions: list # Optional advanced configuration options for plugins, e.g. disable-sampling set to true — item shape: {key: string, value: string}
  dbConnOptions: any # Options specifying how plugins connect to database server
  --tags: list # Tags for observed database entity — item shape: {key: string, value: string}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dbo/databases")
  let body = {name: $name, agentId: $agentId, dbType: $dbType, authMethod: $authMethod, captureMethod: $captureMethod, configOptions: $configOptions, dbConnOptions: $dbConnOptions, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get organization-level configuration for database observability agents/plugins
#
# GET /v1/dbo/databases/config
# operationId: getConfig
export def "dbo-databases-config get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<configOptions: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dbo/databases/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set organization-level configuration for database observability agents/plugins
#
# POST /v1/dbo/databases/config
# operationId: setConfig
export def "dbo-databases-config setConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dbo/databases/config")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get public key for encrypting database credentials locally
#
# GET /v1/dbo/databases/credentials/public-key
# operationId: getPublicKey
export def "dbo-databases-credentials-public-key get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<publicKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dbo/databases/credentials/public-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an observed database
#
# PATCH /v1/dbo/databases/{entityId}
# operationId: updateDatabase
# --configOptions item shape: {key: string, value: string}
# --tags item shape: {key: string, value: string}
export def "dbo-databases updateDatabase" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name for the observed database entity
  --configOptions: list # Optional advanced configuration options for plugins, e.g. disable-sampling set to true. An existing config option can be removed by setting its value to empty string. — item shape: {key: string, value: string}
  --dbConnOptions: any # Options specifying how plugins connect to database server, authentication method change is not supported
  --tags: list # Tags for observed database entity. An existing tag can be removed by setting its value to empty string. — item shape: {key: string, value: string}
  --deployedOn: list # Host entity/entities where database server is deployed on
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dbo/databases/($entityId)")
  let body = {name: $name, configOptions: $configOptions, dbConnOptions: $dbConnOptions, tags: $tags, deployedOn: $deployedOn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an observed database
#
# DELETE /v1/dbo/databases/{entityId}
# operationId: deleteDatabase
export def "dbo-databases delete" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dbo/databases/($entityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get configuration of plugins observing a database
#
# GET /v1/dbo/databases/{entityId}/pluginConfig
# operationId: getPluginConfig
export def "dbo-databases-plugin-config get" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pluginConfig: table<pluginName: string, configOptions: list, dbConnOptions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dbo/databases/($entityId)/pluginConfig")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get status of plugins observing a database
#
# GET /v1/dbo/databases/{entityId}/plugins
# operationId: getPlugins
export def "dbo-databases-plugins get" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<plugins: table<pluginName: string, deploymentStatus: string, healthStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dbo/databases/($entityId)/plugins")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply an operation on a database observability plugin
#
# POST /v1/dbo/databases/{entityId}/plugins/operation/{operation}
# operationId: pluginOperation
export def "dbo-databases-plugins-operation pluginOperation" [
  entityId: string
  operation: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dbo/databases/($entityId)/plugins/operation/($operation)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unobserve an observed database
#
# PUT /v1/dbo/databases/{entityId}/unobserve
# operationId: unobserveDatabase
export def "dbo-databases-unobserve unobserveDatabase" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dbo/databases/($entityId)/unobserve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of existing synthetic probes
#
# GET /v1/dem/probes
# operationId: listProbes
export def "dem-probes listProbes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<probes: table<id: string, name: string, active: bool, platform: record, region: string, country: string, city: string, coordinates: record, ipv4Addresses: list, ipv6Addresses: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dem/probes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get DEM settings
#
# GET /v1/dem/settings
# operationId: getDemSettings
export def "dem-settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<availabilityOutageConfiguration: record<failingTestLocations: record, consecutiveForDown: int>, transactionOutageConfiguration: record<failingTestLocations: record, consecutiveForDown: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dem/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set DEM settings
#
# PUT /v1/dem/settings
# operationId: setDemSettings
export def "dem-settings setDemSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --availabilityOutageConfiguration: any # Configure outage conditions for Website/URI entities.
  --transactionOutageConfiguration: any # Configure outage conditions for Synthetic Transaction entities.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dem/settings")
  let body = {availabilityOutageConfiguration: $availabilityOutageConfiguration, transactionOutageConfiguration: $transactionOutageConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create transaction monitoring configuration
#
# POST /v1/dem/transactions
# operationId: createTransaction
# --tags item shape: {key: string, value: string}
export def "dem-transactions createTransaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the transaction, which must be unique within the organization. The name must not contain any control characters, any white space other than space (U+0020), or any consecutive, leading or trailing spaces. (e.g. Solarwinds)
  --description: string # Description of the transaction. (e.g. Opens Solarwinds homepage)
  --relatedEntityId: string # Id of a related entity to which the transaction is connected.
  testDefinition: any # Test definition for the transaction.
  --tags: list # Entity tags. Tag is a key-value pair, where there may be only single tag value for the same key. — item shape: {key: string, value: string}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dem/transactions")
  let body = {name: $name, description: $description, relatedEntityId: $relatedEntityId, testDefinition: $testDefinition, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get transaction monitoring configuration
#
# GET /v1/dem/transactions/{entityId}
# operationId: getTransaction
export def "dem-transactions get" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, status: record, name: string, description: string, relatedEntityId: string, testDefinition: record<testFrom: record<type: record, values: list>, platformOptions: record, outageConfiguration: record, testIntervalInSeconds: record, windowSize: record<width: int, height: int>, userAgent: string, commands: list<record>>, tags: table<key: string, value: string>, lastOutageStartTime: string, lastOutageEndTime: string, lastTestTime: string, lastErrorTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dem/transactions/($entityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update transaction monitoring configuration
#
# PUT /v1/dem/transactions/{entityId}
# operationId: updateTransaction
# --tags item shape: {key: string, value: string}
export def "dem-transactions updateTransaction" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the transaction, which must be unique within the organization. The name must not contain any control characters, any white space other than space (U+0020), or any consecutive, leading or trailing spaces. (e.g. Solarwinds)
  --description: string # Description of the transaction. (e.g. Opens Solarwinds homepage)
  --relatedEntityId: string # Id of a related entity to which the transaction is connected.
  testDefinition: any # Test definition for the transaction.
  --tags: list # Entity tags. Tag is a key-value pair, where there may be only single tag value for the same key. — item shape: {key: string, value: string}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dem/transactions/($entityId)")
  let body = {name: $name, description: $description, relatedEntityId: $relatedEntityId, testDefinition: $testDefinition, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete transaction
#
# DELETE /v1/dem/transactions/{entityId}
# operationId: deleteTransaction
export def "dem-transactions delete" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dem/transactions/($entityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause monitoring of the transaction
#
# PUT /v1/dem/transactions/{entityId}/pauseMonitoring
# operationId: pauseTransactionMonitoring
export def "dem-transactions-pause-monitoring pauseTransactionMonitoring" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dem/transactions/($entityId)/pauseMonitoring")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unpause monitoring of the transaction
#
# PUT /v1/dem/transactions/{entityId}/unpauseMonitoring
# operationId: unpauseTransactionMonitoring
export def "dem-transactions-unpause-monitoring unpauseTransactionMonitoring" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dem/transactions/($entityId)/unpauseMonitoring")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create URI monitoring configuration
#
# POST /v1/dem/uris
# operationId: createUri
# --tags item shape: {key: string, value: string}
export def "dem-uris createUri" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the URI, which must be unique within the organization. The name must also not contain any control characters, any white space other than space (U+0020), or any consecutive, leading or trailing spaces. (e.g. solarwinds.com)
  ipOrDomain: string # IP/domain of the URI. (e.g. solarwinds.com)
  availabilityCheckSettings: any # Availability tests configuration for the URI.
  --tags: list # Tags associated with the URI for categorization. — item shape: {key: string, value: string}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dem/uris")
  let body = {name: $name, ipOrDomain: $ipOrDomain, availabilityCheckSettings: $availabilityCheckSettings, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get URI monitoring configuration
#
# GET /v1/dem/uris/{entityId}
# operationId: getUri
export def "dem-uris get" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, status: record, name: string, ipOrDomain: string, availabilityCheckSettings: record<platformOptions: record, testFrom: record<type: record, values: list>, testIntervalInSeconds: record, outageConfiguration: record, dns: record, ping: record, tcp: record, udp: record, protocol: record>, tags: table<key: string, value: string>, lastOutageStartTime: string, lastOutageEndTime: string, lastTestTime: string, lastErrorTime: string, lastResponseTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dem/uris/($entityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update URI monitoring configuration
#
# PUT /v1/dem/uris/{entityId}
# operationId: updateUri
# --tags item shape: {key: string, value: string}
export def "dem-uris updateUri" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the URI, which must be unique within the organization. The name must also not contain any control characters, any white space other than space (U+0020), or any consecutive, leading or trailing spaces. (e.g. solarwinds.com)
  ipOrDomain: string # IP/domain of the URI. (e.g. solarwinds.com)
  availabilityCheckSettings: any # Availability tests configuration for the URI.
  --tags: list # Tags associated with the URI for categorization. — item shape: {key: string, value: string}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dem/uris/($entityId)")
  let body = {name: $name, ipOrDomain: $ipOrDomain, availabilityCheckSettings: $availabilityCheckSettings, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete URI
#
# DELETE /v1/dem/uris/{entityId}
# operationId: deleteUri
export def "dem-uris delete" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dem/uris/($entityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get outage statuses
#
# GET /v1/dem/uris/{entityId}/outageStatuses
# operationId: getUriOutageStatuses
export def "dem-uris-outage-statuses get" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Start of timespan to get results for, inclusive (format: date-time)
  --endTime: string # End of timespan to get results for, exclusive (format: date-time)
  --direction: string@direction-completer # sort direction: 'backward' and 'tail' both sort from oldest to newest, 'forward' sorts from newest to oldest (default: backward)
  --pageSize: int # Number of items in a response page. Default varies by API. (format: int32)
  --skipToken: string # Token for the requested page.
]: nothing -> record<statuses: table<startTime: string, endTime: string, status: string, resultId: string, analysisId: string>, pageInfo: record<prevPage: string, nextPage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "skipToken" $skipToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/dem/uris/($entityId)/outageStatuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause monitoring of the URI
#
# PUT /v1/dem/uris/{entityId}/pauseMonitoring
# operationId: pauseUriMonitoring
export def "dem-uris-pause-monitoring pauseUriMonitoring" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dem/uris/($entityId)/pauseMonitoring")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get test results
#
# GET /v1/dem/uris/{entityId}/testResults
# operationId: getUriTestResults
export def "dem-uris-test-results get" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Start of timespan to get results for, inclusive (format: date-time)
  --endTime: string # End of timespan to get results for, exclusive (format: date-time)
  --direction: string@direction-completer # sort direction: 'backward' and 'tail' both sort from oldest to newest, 'forward' sorts from newest to oldest (default: backward)
  --minResponse: int # Minimal result response time to return, inclusive, defaults to -1 (format: int32)
  --maxResponse: int # Maximal result response time to return, exclusive, defaults to infinity (format: int32)
  --probes: string # Ids of probes to return results from (comma-separated list). Defaults to all probes.
  --status: string@status-completer # Test result statuses to include. Defaults to all statuses
  --pageSize: int # Number of items in a response page. Default varies by API. (format: int32)
  --skipToken: string # Token for the requested page.
]: nothing -> record<results: table<time: string, probe: record, monitor: record, responseTime: int, status: string, phase: string, description: string, message: string, analysisId: string, validationsId: string>, pageInfo: record<prevPage: string, nextPage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "minResponse" $minResponse "scalar") (serialize-qp "maxResponse" $maxResponse "scalar") (serialize-qp "probes" $probes "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "skipToken" $skipToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/dem/uris/($entityId)/testResults" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unpause monitoring of the URI
#
# PUT /v1/dem/uris/{entityId}/unpauseMonitoring
# operationId: unpauseUriMonitoring
export def "dem-uris-unpause-monitoring unpauseUriMonitoring" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dem/uris/($entityId)/unpauseMonitoring")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create website monitoring configuration
#
# POST /v1/dem/websites
# operationId: createWebsite
# --availabilityCheckSettings shape: {platformOptions?: record, testFrom?: any, testIntervalInSeconds: any, outageConfiguration?: record, checkForString?: record, protocols: list, ssl?: record, customHeaders?: list, allowInsecureRenegotiation?: bool, postData?: string, authentication?: record}
# --tags item shape: {key: string, value: string}
# --rum shape: {apdexTimeInSeconds?: int, spa: bool}
export def "dem-websites createWebsite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the website, which must be unique within the organization. The website must also not contain any control characters, any white space other than space (U+0020), or any consecutive, leading or trailing spaces. (e.g. solarwinds.com)
  --body-url: string # URL of the website. Must be a valid URL with no leading or trailing white space. Must not contain invalid port number (>65535). (e.g. https://www.solarwinds.com)
  --availabilityCheckSettings: record # Use this field to configure availability tests for the website. (nullable) — shape: {platformOptions?: record, testFrom?: any, testIntervalInSeconds: any, outageConfiguration?: record, checkForString?: record, protocols: list, ssl?: record, customHeaders?: list, allowInsecureRenegotiation?: bool, postData?: string, authentication?: record}
  --tags: list # Entity tags. Tag is a key-value pair, where there may be only single tag value for the same key. — item shape: {key: string, value: string}
  --rum: record #     Use this field to configure real user monitoring (RUM) for the website.     You are required to configure at least availability monitoring or real user monitoring to be able to create website. (e.g. {apdexTimeInSeconds: 4, spa: true}) — shape: {apdexTimeInSeconds?: int, spa: bool}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dem/websites")
  let body = {name: $name, url: $body_url, availabilityCheckSettings: $availabilityCheckSettings, tags: $tags, rum: $rum} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get website monitoring configuration
#
# GET /v1/dem/websites/{entityId}
# operationId: getWebsite
export def "dem-websites get" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, status: record, name: string, url: string, monitoringOptions: record<isAvailabilityActive: bool, isRumActive: bool>, availabilityCheckSettings: record, tags: table<key: string, value: string>, rum: record<apdexTimeInSeconds: int, snippet: string, spa: bool>, lastOutageStartTime: string, lastOutageEndTime: string, lastTestTime: string, lastErrorTime: string, lastResponseTime: int, nextOnDemandAvailabilityTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dem/websites/($entityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update website monitoring configuration
#
# PUT /v1/dem/websites/{entityId}
# operationId: updateWebsite
# --availabilityCheckSettings shape: {platformOptions?: record, testFrom?: any, testIntervalInSeconds: any, outageConfiguration?: record, checkForString?: record, protocols: list, ssl?: record, customHeaders?: list, allowInsecureRenegotiation?: bool, postData?: string, authentication?: record}
# --tags item shape: {key: string, value: string}
# --rum shape: {apdexTimeInSeconds?: int, spa: bool}
export def "dem-websites updateWebsite" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the website, which must be unique within the organization. The website must also not contain any control characters, any white space other than space (U+0020), or any consecutive, leading or trailing spaces. (e.g. solarwinds.com)
  --body-url: string # URL of the website. Must be a valid URL with no leading or trailing white space. Must not contain invalid port number (>65535). (e.g. https://www.solarwinds.com)
  --availabilityCheckSettings: record # Use this field to configure availability tests for the website. (nullable) — shape: {platformOptions?: record, testFrom?: any, testIntervalInSeconds: any, outageConfiguration?: record, checkForString?: record, protocols: list, ssl?: record, customHeaders?: list, allowInsecureRenegotiation?: bool, postData?: string, authentication?: record}
  --tags: list # Entity tags. Tag is a key-value pair, where there may be only single tag value for the same key. — item shape: {key: string, value: string}
  --rum: record #     Use this field to configure real user monitoring (RUM) for the website.     You are required to configure at least availability monitoring or real user monitoring to be able to create website. (e.g. {apdexTimeInSeconds: 4, spa: true}) — shape: {apdexTimeInSeconds?: int, spa: bool}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dem/websites/($entityId)")
  let body = {name: $name, url: $body_url, availabilityCheckSettings: $availabilityCheckSettings, tags: $tags, rum: $rum} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete website
#
# DELETE /v1/dem/websites/{entityId}
# operationId: deleteWebsite
export def "dem-websites delete" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dem/websites/($entityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get outage statuses
#
# GET /v1/dem/websites/{entityId}/outageStatuses
# operationId: getWebsiteOutageStatuses
export def "dem-websites-outage-statuses get" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Start of timespan to get results for, inclusive (format: date-time)
  --endTime: string # End of timespan to get results for, exclusive (format: date-time)
  --direction: string@direction-completer # sort direction: 'backward' and 'tail' both sort from oldest to newest, 'forward' sorts from newest to oldest (default: backward)
  --pageSize: int # Number of items in a response page. Default varies by API. (format: int32)
  --skipToken: string # Token for the requested page.
]: nothing -> record<statuses: table<startTime: string, endTime: string, status: string, resultId: string, analysisId: string>, pageInfo: record<prevPage: string, nextPage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "skipToken" $skipToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/dem/websites/($entityId)/outageStatuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause monitoring of a website
#
# PUT /v1/dem/websites/{entityId}/pauseMonitoring
# operationId: pauseWebsiteMonitoring
export def "dem-websites-pause-monitoring pauseWebsiteMonitoring" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dem/websites/($entityId)/pauseMonitoring")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get test results
#
# GET /v1/dem/websites/{entityId}/testResults
# operationId: getWebsiteTestResults
export def "dem-websites-test-results get" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Start of timespan to get results for, inclusive (format: date-time)
  --endTime: string # End of timespan to get results for, exclusive (format: date-time)
  --direction: string@direction-completer # sort direction: 'backward' and 'tail' both sort from oldest to newest, 'forward' sorts from newest to oldest (default: backward)
  --minResponse: int # Minimal result response time to return, inclusive, defaults to -1 (format: int32)
  --maxResponse: int # Maximal result response time to return, exclusive, defaults to infinity (format: int32)
  --probes: string # Ids of probes to return results from (comma-separated list). Defaults to all probes.
  --status: string@status-completer # Test result statuses to include. Defaults to all statuses
  --pageSize: int # Number of items in a response page. Default varies by API. (format: int32)
  --skipToken: string # Token for the requested page.
]: nothing -> record<results: table<time: string, probe: record, monitor: record, responseTime: int, status: string, phase: string, description: string, message: string, analysisId: string, validationsId: string>, pageInfo: record<prevPage: string, nextPage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "minResponse" $minResponse "scalar") (serialize-qp "maxResponse" $maxResponse "scalar") (serialize-qp "probes" $probes "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "skipToken" $skipToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/dem/websites/($entityId)/testResults" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unpause monitoring of a website
#
# PUT /v1/dem/websites/{entityId}/unpauseMonitoring
# operationId: unpauseWebsiteMonitoring
export def "dem-websites-unpause-monitoring unpauseWebsiteMonitoring" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dem/websites/($entityId)/unpauseMonitoring")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of entities by type. A returned empty list indicates no entities matched the given parameters.
#
# GET /v1/entities
# operationId: listEntities
export def "entities listEntities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # The entity type to search. If omitted or empty, the search includes all entity types.
  --name: string # The entity name to search for. Searches are case-insensitive and match any value containing the provided string.
  --pageSize: int # Number of items in a response page. Default varies by API. (format: int32)
  --skipToken: string # Token for the requested page.
]: nothing -> record<entities: table<id: string, type: string, name: string, displayName: string, createdTime: string, updatedTime: string, lastSeenTime: string, inMaintenance: bool, healthscore: record, healthState: record, tags: record, attributes: record>, pageInfo: record<prevPage: string, nextPage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "skipToken" $skipToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/entities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create website
#
# POST /v1/entities/websites
# DEPRECATED
# operationId: createWebsiteDeprecated
# --availabilityCheckSettings shape: {platformOptions?: record, testFrom?: any, testIntervalInSeconds: any, outageConfiguration?: record, checkForString?: record, protocols: list, ssl?: record, customHeaders?: list, allowInsecureRenegotiation?: bool, postData?: string, authentication?: record}
# --tags item shape: {key: string, value: string}
# --rum shape: {apdexTimeInSeconds?: int, spa: bool}
@deprecated
export def "entities-websites createWebsiteDeprecated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the website, which must be unique within the organization. The website must also not contain any control characters, any white space other than space (U+0020), or any consecutive, leading or trailing spaces. (e.g. solarwinds.com)
  --body-url: string # URL of the website. Must be a valid URL with no leading or trailing white space. Must not contain invalid port number (>65535). (e.g. https://www.solarwinds.com)
  --availabilityCheckSettings: record # Use this field to configure availability tests for the website. (nullable) — shape: {platformOptions?: record, testFrom?: any, testIntervalInSeconds: any, outageConfiguration?: record, checkForString?: record, protocols: list, ssl?: record, customHeaders?: list, allowInsecureRenegotiation?: bool, postData?: string, authentication?: record}
  --tags: list # Entity tags. Tag is a key-value pair, where there may be only single tag value for the same key. — item shape: {key: string, value: string}
  --rum: record #     Use this field to configure real user monitoring (RUM) for the website.     You are required to configure at least availability monitoring or real user monitoring to be able to create website. (e.g. {apdexTimeInSeconds: 4, spa: true}) — shape: {apdexTimeInSeconds?: int, spa: bool}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/entities/websites")
  let body = {name: $name, url: $body_url, availabilityCheckSettings: $availabilityCheckSettings, tags: $tags, rum: $rum} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get website
#
# GET /v1/entities/websites/{entityId}
# DEPRECATED
# operationId: getWebsiteDeprecated
@deprecated
export def "entities-websites get" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, status: record, name: string, url: string, monitoringOptions: record<isAvailabilityActive: bool, isRumActive: bool>, availabilityCheckSettings: record, tags: table<key: string, value: string>, rum: record<apdexTimeInSeconds: int, snippet: string, spa: bool>, lastOutageStartTime: string, lastOutageEndTime: string, lastTestTime: string, lastErrorTime: string, lastResponseTime: int, nextOnDemandAvailabilityTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/entities/websites/($entityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update website
#
# PUT /v1/entities/websites/{entityId}
# DEPRECATED
# operationId: updateWebsiteDeprecated
# --availabilityCheckSettings shape: {platformOptions?: record, testFrom?: any, testIntervalInSeconds: any, outageConfiguration?: record, checkForString?: record, protocols: list, ssl?: record, customHeaders?: list, allowInsecureRenegotiation?: bool, postData?: string, authentication?: record}
# --tags item shape: {key: string, value: string}
# --rum shape: {apdexTimeInSeconds?: int, spa: bool}
@deprecated
export def "entities-websites updateWebsiteDeprecated" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the website, which must be unique within the organization. The website must also not contain any control characters, any white space other than space (U+0020), or any consecutive, leading or trailing spaces. (e.g. solarwinds.com)
  --body-url: string # URL of the website. Must be a valid URL with no leading or trailing white space. Must not contain invalid port number (>65535). (e.g. https://www.solarwinds.com)
  --availabilityCheckSettings: record # Use this field to configure availability tests for the website. (nullable) — shape: {platformOptions?: record, testFrom?: any, testIntervalInSeconds: any, outageConfiguration?: record, checkForString?: record, protocols: list, ssl?: record, customHeaders?: list, allowInsecureRenegotiation?: bool, postData?: string, authentication?: record}
  --tags: list # Entity tags. Tag is a key-value pair, where there may be only single tag value for the same key. — item shape: {key: string, value: string}
  --rum: record #     Use this field to configure real user monitoring (RUM) for the website.     You are required to configure at least availability monitoring or real user monitoring to be able to create website. (e.g. {apdexTimeInSeconds: 4, spa: true}) — shape: {apdexTimeInSeconds?: int, spa: bool}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/entities/websites/($entityId)")
  let body = {name: $name, url: $body_url, availabilityCheckSettings: $availabilityCheckSettings, tags: $tags, rum: $rum} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete website
#
# DELETE /v1/entities/websites/{entityId}
# DEPRECATED
# operationId: deleteWebsiteDeprecated
@deprecated
export def "entities-websites delete" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/entities/websites/($entityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause monitoring of a website
#
# PUT /v1/entities/websites/{entityId}/pauseMonitoring
# DEPRECATED
# operationId: pauseWebsiteMonitoringDeprecated
@deprecated
export def "entities-websites-pause-monitoring pauseWebsiteMonitoringDeprecated" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/entities/websites/($entityId)/pauseMonitoring")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unpause monitoring of a website
#
# PUT /v1/entities/websites/{entityId}/unpauseMonitoring
# DEPRECATED
# operationId: unpauseWebsiteMonitoringDeprecated
@deprecated
export def "entities-websites-unpause-monitoring unpauseWebsiteMonitoringDeprecated" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/entities/websites/($entityId)/unpauseMonitoring")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an entity by ID
#
# GET /v1/entities/{id}
# operationId: getEntityById
export def "entities get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, name: string, displayName: string, createdTime: string, updatedTime: string, lastSeenTime: string, inMaintenance: bool, healthscore: record<score: int, category: string>, healthState: record<state: string>, tags: record, attributes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/entities/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an entity by ID
#
# PUT /v1/entities/{id}
# operationId: updateEntityById
export def "entities updateEntityById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --displayName: string # Entity display name / alias. This value is equal to name unless it is explicitly overridden. (nullable, e.g. SyslogTest)
  tags: record # Entity tags. Tag is a key-value pair, where there may be only a single tag value for the same key. (e.g. {gg.tk.token: test, kfi.tk.token: qa-test})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/entities/($id)")
  let body = {displayName: $displayName, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search logs
#
# GET /v1/logs
# operationId: searchLogs
export def "logs searchLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # A search query string
  --group: string # Filter logs by a specific group name
  --entityId: string # Filter logs by a specific entity id
  --startTime: string # Timestamp in ISO 8601 format in UTC timezone: yyyy-MM-ddTHH:mm:ssZ (format: date-time)
  --endTime: string # Timestamp in ISO 8601 format in UTC timezone: yyyy-MM-ddTHH:mm:ssZ (format: date-time)
  --direction: string # Search direction: backward, forward, or tail. Backward sorts logs from oldest to newest, forward sorts logs from newest to oldest, and tail sorts from oldest to newest. (default: backward)
  --pageSize: int # Number of items in a response page. Default varies by API. (format: int32)
  --skipToken: string # Token for the requested page.
]: nothing -> record<logs: table<id: string, time: string, message: string, hostname: string, severity: string, program: string>, pageInfo: record<prevPage: string, nextPage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "entityId" $entityId "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "skipToken" $skipToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve location and metadata of log archives
#
# GET /v1/logs/archives
# operationId: listLogArchives
export def "logs-archives listLogArchives" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # List archives beginning at this time. Timestamp in ISO 8601 format in UTC timezone: yyyy-MM-ddTHH:mm:ssZ. Must be within the the last year.
  --endTime: string # List archives ending at this time. Timestamp in ISO 8601 format in UTC timezone: yyyy-MM-ddTHH:mm:ssZ. Must be within the the last year.
  --pageSize: int # Number of items in a response page. Default varies by API. (format: int32)
  --skipToken: string # Token for the requested page.
]: nothing -> record<logArchives: table<id: string, name: string, downloadUrl: string, archivedTimestamp: string, archiveSize: float>, pageInfo: record<prevPage: string, nextPage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "skipToken" $skipToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/logs/archives" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all entity types
#
# GET /v1/metadata/entities/types
# operationId: listEntityTypes
export def "metadata-entities-types listEntityTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<types: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/metadata/entities/types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List metrics metadata for an entity type
#
# GET /v1/metadata/entities/types/{type}/metrics
# operationId: listMetricsForEntityType
export def "metadata-entities-types-metrics listMetricsForEntityType" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Timestamp in ISO 8601 format in UTC timezone: yyyy-MM-ddTHH:mm:ssZ (format: date-time)
  --endTime: string # Timestamp in ISO 8601 format in UTC timezone: yyyy-MM-ddTHH:mm:ssZ (format: date-time)
]: nothing -> record<type: string, metrics: table<name: string, displayName: string, description: string, units: string, formula: string, lastReportedTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/metadata/entities/types/($type)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List metrics
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
  --name: string # Metric name.
  --startTime: string # Timestamp in ISO 8601 format in UTC timezone: yyyy-MM-ddTHH:mm:ssZ (format: date-time)
  --endTime: string # Timestamp in ISO 8601 format in UTC timezone: yyyy-MM-ddTHH:mm:ssZ (format: date-time)
  --pageSize: int # Number of items in a response page. Default varies by API. (format: int32)
  --skipToken: string # Token for the requested page.
]: nothing -> record<metricsInfo: table<name: string, displayName: string, description: string, units: string, formula: string, lastReportedTime: string>, pageInfo: record<prevPage: string, nextPage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "skipToken" $skipToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create composite metric
#
# POST /v1/metrics
# operationId: createCompositeMetric
export def "metrics createCompositeMetric" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the composite metric. (e.g. composite.custom.system.disk.io.rate)
  --displayName: string # Display name of the composite metric. A short description of the metric. (nullable, e.g. Disk IO rate)
  --description: string # Description of the composite metric. A detailed description of the metric. (nullable, e.g. Disk bytes transferred per second)
  formula: string # PromQL query to calculate the composite metric. (e.g. rate(system.disk.io[5m]))
  --units: string # Unit of the composite metric. (nullable, e.g. bytes/s)
]: any -> record<name: string, displayName: string, description: string, formula: string, units: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/metrics")
  let body = {name: $name, displayName: $displayName, description: $description, formula: $formula, units: $units} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List measurements for a batch of metrics
#
# POST /v1/metrics/measurements
# operationId: listMultiMetricMeasurements
# --metrics item shape: {id?: string, name: string, filter?: string, groupBy?: list, aggregateBy?: any, preGroupBy?: list, preGroupByMethod?: any, seriesType?: any, fillMethod?: any, fillIfEmpty?: bool}
export def "metrics-measurements listMultiMetricMeasurements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forcePositional: string@bool-completer # Forces a positional response; see the operation description. (default: false)
  --pageSize: int # Number of items in a response page. Default varies by API. (format: int32)
  --skipToken: string # Token for the requested page.
  metrics: list # List of metric measurement requests. — item shape: {id?: string, name: string, filter?: string, groupBy?: list, aggregateBy?: any, preGroupBy?: list, preGroupByMethod?: any, seriesType?: any, fillMethod?: any, fillIfEmpty?: bool}
  --startTime: string # Timestamp in ISO 8601 format in UTC timezone: yyyy-MM-ddTHH:mm:ssZ (format: date-time)
  --endTime: string # Timestamp in ISO 8601 format in UTC timezone: yyyy-MM-ddTHH:mm:ssZ (format: date-time)
]: any -> record<metrics: table<id: string, name: string, groupings: list, bucketSizeInSeconds: int>, pageInfo: record<prevPage: string, nextPage: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forcePositional" $forcePositional "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "skipToken" $skipToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/metrics/measurements" $qp)
  let body = {metrics: $metrics, startTime: $startTime, endTime: $endTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update composite metric
#
# PUT /v1/metrics/{name}
# operationId: updateCompositeMetric
export def "metrics updateCompositeMetric" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --displayName: string # Display name of the composite metric. A short description of the metric. (nullable, e.g. Disk IO rate)
  --description: string # Description of the composite metric. A detailed description of the metric. (nullable, e.g. Disk bytes transferred per second)
  formula: string # PromQL query to calculate the composite metric. (e.g. rate(system.disk.io[5m]))
  --units: string # Unit of the composite metric. (nullable, e.g. bytes/s)
]: any -> record<name: string, displayName: string, description: string, formula: string, units: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/metrics/($name)")
  let body = {displayName: $displayName, description: $description, formula: $formula, units: $units} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete composite metric
#
# DELETE /v1/metrics/{name}
# operationId: deleteCompositeMetric
export def "metrics delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/metrics/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metric info by name
#
# GET /v1/metrics/{name}
# operationId: getMetricByName
export def "metrics get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, displayName: string, description: string, units: string, formula: string, lastReportedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/metrics/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List metric attribute names
#
# GET /v1/metrics/{name}/attributes
# operationId: listMetricAttributes
export def "metrics-attributes listMetricAttributes" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Timestamp in ISO 8601 format in UTC timezone: yyyy-MM-ddTHH:mm:ssZ (format: date-time)
  --endTime: string # Timestamp in ISO 8601 format in UTC timezone: yyyy-MM-ddTHH:mm:ssZ (format: date-time)
  --pageSize: int # Number of items in a response page. Default varies by API. (format: int32)
  --skipToken: string # Token for the requested page.
]: nothing -> record<names: list<string>, pageInfo: record<prevPage: string, nextPage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "skipToken" $skipToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/metrics/($name)/attributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List metric attribute values
#
# GET /v1/metrics/{name}/attributes/{attributeName}
# operationId: listMetricAttributeValues
export def "metrics-attributes listMetricAttributeValues" [
  name: string
  attributeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Timestamp in ISO 8601 format in UTC timezone: yyyy-MM-ddTHH:mm:ssZ (format: date-time)
  --endTime: string # Timestamp in ISO 8601 format in UTC timezone: yyyy-MM-ddTHH:mm:ssZ (format: date-time)
  --pageSize: int # Number of items in a response page. Default varies by API. (format: int32)
  --skipToken: string # Token for the requested page.
]: nothing -> record<name: string, values: list<string>, pageInfo: record<prevPage: string, nextPage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "skipToken" $skipToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/metrics/($name)/attributes/($attributeName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List metric measurement values, grouped by attributes, filtered by the filter. An empty list indicates no data points are available for the given parameters.
#
# GET /v1/metrics/{name}/measurements
# operationId: listMetricMeasurements
export def "metrics-measurements listMetricMeasurements" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # Query to filter the measurement values. e.g id: [id1,id2] category: moderate
  --groupBy: string # Comma-delimited list of attribute names to group measurements by. e.g id, category
  --aggregateBy: string@aggregateBy-completer # Aggregation method used to group measurements. Defaults to AVG.
  --preGroupBy: string # Secondary grouping to allow aggregating data points inside individual buckets. Has to be set together with `preGroupByMethod`.
  --preGroupByMethod: string@preGroupByMethod-completer # Secondary aggregation to allow aggregating data points inside individual buckets. Has to be set together with `preGroupBy`.
  --seriesType: string@seriesType-completer # Indicates what type of data to return. Defaults to TIMESERIES.
  --startTime: string # Timestamp in ISO 8601 format in UTC timezone: yyyy-MM-ddTHH:mm:ssZ (format: date-time)
  --endTime: string # Timestamp in ISO 8601 format in UTC timezone: yyyy-MM-ddTHH:mm:ssZ (format: date-time)
  --pageSize: int # Number of items in a response page. Default varies by API. (format: int32)
  --skipToken: string # Token for the requested page.
]: nothing -> record<groupings: table<attributes: list, measurements: list>, bucketSizeInSeconds: int, pageInfo: record<prevPage: string, nextPage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "groupBy" $groupBy "scalar") (serialize-qp "aggregateBy" $aggregateBy "scalar") (serialize-qp "preGroupBy" $preGroupBy "scalar") (serialize-qp "preGroupByMethod" $preGroupByMethod "scalar") (serialize-qp "seriesType" $seriesType "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "skipToken" $skipToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/metrics/($name)/measurements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create ingestion token
#
# POST /v1/tokens
# operationId: createToken
# --tags shape: {server: string, tag_without_value: string}
export def "tokens createToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the token.
  tags: record # Tags to associate with the token. — shape: {server: string, tag_without_value: string}
  type: string@type-completer # Type of token. Currently only 'ingestion' is supported.
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tokens")
  let body = {name: $name, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
