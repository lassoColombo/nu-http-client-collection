# Auto-generated client for Codacy API v3.1.0
# Source: https://api.codacy.com/api/api-docs/swagger.yaml
# Auth: --token flag or $env.CODACY_API_TOKEN

const BASE_URL = "https://app.codacy.com/api/v3"
const DEFAULT_AUTH = "api-token"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CODACY_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "api-token" => { {headers: {api-token: $token_val}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["https://app.codacy.com/api/v3"] }
def auth-scheme-completer [] { ["api-token"] }

# Completers for enum parameters
def status-completer [] { ["all" "fixed" "new"] }
def filter-completer [] { ["withCoverageChanges"] }
def sortColumn-completer [] { ["deltaCoverage" "filename" "totalCoverage"] }
def columnOrder-completer [] { ["asc" "desc"] }
def securityIssueMinimumSeverity-completer [] { ["Error" "High" "Info" "Warning"] }
def reason-completer [] { ["AcceptedUse" "ExternalCode" "FalsePositive" "NotExploitable" "TestCode"] }
def filter-completer-1 [] { ["AllSynced" "NotSynced" "Synced"] }
def permission-completer [] { ["RepoAdmin" "RepoRead" "RepoWrite"] }
def joinMode-completer [] { ["adminAuto" "auto" "request"] }
def type-completer [] { ["Account" "Organization"] }
def period-completer [] { ["day" "month" "week"] }
def complianceType-completer [] { ["ai-risk"] }
def sort-completer [] { ["DetectedAt" "Status"] }
def reportFormat-completer [] { ["json"] }
def sortColumn-completer-1 [] { ["ossfScore" "severity"] }
def elementType-completer [] { ["dependency" "file" "finding" "issue"] }
def targetType-completer [] { ["graphql" "openapi" "webapp"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "version get" } } | get name | first)
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

# Return the version of the Codacy installation
#
# GET /version
# operationId: getVersion
export def "version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organization repositories with analysis information for the authenticated user
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories
# operationId: listOrganizationRepositoriesWithAnalysis
@deprecated --flag repositories
export def "analysis-organizations-repositories listOrganizationRepositoriesWithAnalysis" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
  --repositories: string # **Deprecated:** Use [searchOrganizationRepositoriesWithAnalysis](#searchorganizationrepositorieswithanalysis) instead. (DEPRECATED, e.g. codacy-eslint,codacy-pmd)
  --segments: string # Filter by a comma-separated list of segment identifiers (e.g. 1,2,3)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<lastAnalysedCommit: record, grade: int, gradeLetter: string, issuesPercentage: int, issuesCount: int, loc: int, complexFilesPercentage: int, complexFilesCount: int, duplicationPercentage: int, repository: record, branch: record, selectedBranch: record, coverage: record, goals: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "repositories" $repositories "scalar") (serialize-qp "segments" $segments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search organization repositories with analysis information for the authenticated user
#
# POST /search/analysis/organizations/{provider}/{remoteOrganizationName}/repositories
# operationId: searchOrganizationRepositoriesWithAnalysis
export def "search-analysis-organizations-repositories searchOrganizationRepositoriesWithAnalysis" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --names: list # List of repository names
]: any -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<lastAnalysedCommit: record, grade: int, gradeLetter: string, issuesPercentage: int, issuesCount: int, loc: int, complexFilesPercentage: int, complexFilesCount: int, duplicationPercentage: int, repository: record, branch: record, selectedBranch: record, coverage: record, goals: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/analysis/organizations/($provider)/($remoteOrganizationName)/repositories" $qp)
  let body = {names: $names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a repository with analysis information for the authenticated user
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}
# operationId: getRepositoryWithAnalysis
export def "analysis-organizations-repositories get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # Name of a [repository branch enabled on Codacy](https://docs.codacy.com/repositories-configure/managing-branches/), as returned by the endpoint [listRepositoryBranches](#listrepositorybranches). By default, uses the main branch defined on the Codacy repository settings.  (e.g. master)
]: nothing -> record<data: record<lastAnalysedCommit: record<sha: string, id: int, commitTimestamp: string, authorName: string, authorEmail: string, message: string, startedAnalysis: string, endedAnalysis: string, isMergeCommit: bool, gitHref: string, parents: list>, grade: int, gradeLetter: string, issuesPercentage: int, issuesCount: int, loc: int, complexFilesPercentage: int, complexFilesCount: int, duplicationPercentage: int, repository: record<repositoryId: int, provider: string, owner: string, name: string, fullPath: string, visibility: string, remoteIdentifier: string, lastUpdated: string, permission: string, problems: list, languages: list, defaultBranch: record, badges: record, codingStandardId: int, codingStandardName: string, standards: list, addedState: string, gatePolicyId: int, gatePolicyName: string>, branch: record<id: int, name: string, isDefault: bool, isEnabled: bool, lastUpdated: string, branchType: string, lastCommit: string>, selectedBranch: record<id: int, name: string, isDefault: bool, isEnabled: bool, lastUpdated: string, branchType: string, lastCommit: string>, coverage: record<filesUncovered: int, filesWithLowCoverage: int, coveragePercentage: int, coveragePercentageWithDecimals: float, numberTotalFiles: int, numberCoveredLines: int, numberCoverableLines: int>, goals: record<maxIssuePercentage: int, maxDuplicatedFilesPercentage: int, minCoveragePercentage: int, maxComplexFilesPercentage: int, fileDuplicationBlockThreshold: int, fileComplexityValueThreshold: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get analysis tools settings of a repository
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/tools
# operationId: listRepositoryTools
export def "analysis-organizations-repositories-tools listRepositoryTools" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<uuid: string, name: string, isClientSide: bool, settings: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/tools")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get tools with conflicts in a repository
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/tools/conflicts
# operationId: listRepositoryToolConflicts
export def "analysis-organizations-repositories-tools-conflicts listRepositoryToolConflicts" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/tools/conflicts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Configure an analysis tool by enabling and disabling its patterns for a repository. This endpoint will apply the changes without verifying if the repository belongs to a coding standard.
#
# PATCH /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/tools/{toolUuid}
# operationId: configureTool
# --patterns item shape: {id: string, enabled: bool, parameters?: list}
export def "analysis-organizations-repositories-tools configureTool" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  toolUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Whether to enable or disable the tool.
  --useConfigurationFile: string@bool-completer # Marks the tool as using a configuration file or not.
  --patterns: list # The patterns to enable or disable. — item shape: {id: string, enabled: bool, parameters?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/tools/($toolUuid)")
  let body = {enabled: $enabled, useConfigurationFile: $useConfigurationFile, patterns: $patterns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Patterns configuration for (repository, tool). Uses standard if applied, repository settings otherwise.
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/tools/{toolUuid}/patterns
# operationId: listRepositoryToolPatterns
export def "analysis-organizations-repositories-tools-patterns listRepositoryToolPatterns" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  toolUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --languages: string # Comma-separated list of programming languages to filter results by (e.g. Scala,Java,Javascript)
  --categories: string # Filter by a comma-separated list of code pattern categories. Valid values are `Security`, `ErrorProne`, `CodeStyle`, `Compatibility`, `UnusedCode`, `Complexity`, `Comprehensibility`, `Documentation`, `BestPractice`, and `Performance`.  (e.g. Security,ErrorProne)
  --severityLevels: string # Filter by a comma-separated list of code pattern severity levels. Valid values are `Error`, `High`, `Warning`, and `Info`. (e.g. Error,Warning)
  --tags: string # Filter by a comma-separated list of pattern tags (e.g. React,Angular)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
  --enabled: string@bool-completer # Filter by pattern status. Set to `true` to return only enabled patterns, or `false` to return only disabled patterns
  --recommended: string@bool-completer # Filter by recommended status. Set to `true` to return only recommended patterns, or `false` to return only non-recommended patterns
  --qp-sort: string # Field used to sort the tool's code patterns. Valid values are `category`, `recommended`, and `severity`. (e.g. category)
  --direction: string # Sort direction. Possible values are 'asc' (ascending) or 'desc' (descending). (e.g. desc)
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<data: table<patternDefinition: record, enabled: bool, isCustom: bool, parameters: list, enabledBy: list>, pagination: record<cursor: string, limit: int, total: int>, meta: record<totalEnabled: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languages" $languages "scalar") (serialize-qp "categories" $categories "scalar") (serialize-qp "severityLevels" $severityLevels "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "enabled" $enabled "scalar") (serialize-qp "recommended" $recommended "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/tools/($toolUuid)/patterns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk updates the code patterns of a tool in a repository. Use filters to specify the code patterns to update, or omit the filters to update all code patterns.
#
# PATCH /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/tools/{toolUuid}/patterns
# operationId: updateRepositoryToolPatterns
export def "analysis-organizations-repositories-tools-patterns updateRepositoryToolPatterns" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  toolUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --languages: string # Comma-separated list of programming languages to filter results by (e.g. Scala,Java,Javascript)
  --categories: string # Filter by a comma-separated list of code pattern categories. Valid values are `Security`, `ErrorProne`, `CodeStyle`, `Compatibility`, `UnusedCode`, `Complexity`, `Comprehensibility`, `Documentation`, `BestPractice`, and `Performance`.  (e.g. Security,ErrorProne)
  --severityLevels: string # Filter by a comma-separated list of code pattern severity levels. Valid values are `Error`, `High`, `Warning`, and `Info`. (e.g. Error,Warning)
  --tags: string # Filter by a comma-separated list of pattern tags (e.g. React,Angular)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
  --recommended: string@bool-completer # Filter by recommended status. Set to `true` to return only recommended patterns, or `false` to return only non-recommended patterns
  --enabled: string@bool-completer # True enables the code patterns, and False disables them.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languages" $languages "scalar") (serialize-qp "categories" $categories "scalar") (serialize-qp "severityLevels" $severityLevels "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "recommended" $recommended "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/tools/($toolUuid)/patterns" $qp)
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Patterns configuration for (repository, tool, pattern). Uses standard if applied, repository settings otherwise.
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/tools/{toolUuid}/patterns/{patternId}
# operationId: getRepositoryToolPattern
export def "analysis-organizations-repositories-tools-patterns get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  toolUuid: string
  patternId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<patternDefinition: record<id: string, title: string, category: string, subCategory: string, level: string, severityLevel: string, description: string, explanation: string, enabled: bool, languages: list, timeToFix: int, parameters: list, rationale: string, solution: string, goodExamples: list, badExamples: list, tags: list>, enabled: bool, isCustom: bool, parameters: list<record>, enabledBy: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/tools/($toolUuid)/patterns/($patternId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patterns overview for tool. Uses standard if applied, repository settings otherwise.
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/tools/{toolUuid}/patterns/overview
# operationId: toolPatternsOverview
export def "analysis-organizations-repositories-tools-patterns-overview toolPatternsOverview" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  toolUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --languages: string # Comma-separated list of programming languages to filter results by (e.g. Scala,Java,Javascript)
  --categories: string # Filter by a comma-separated list of code pattern categories. Valid values are `Security`, `ErrorProne`, `CodeStyle`, `Compatibility`, `UnusedCode`, `Complexity`, `Comprehensibility`, `Documentation`, `BestPractice`, and `Performance`.  (e.g. Security,ErrorProne)
  --severityLevels: string # Filter by a comma-separated list of code pattern severity levels. Valid values are `Error`, `High`, `Warning`, and `Info`. (e.g. Error,Warning)
  --tags: string # Filter by a comma-separated list of pattern tags (e.g. React,Angular)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
  --enabled: string@bool-completer # Filter by pattern status. Set to `true` to return only enabled patterns, or `false` to return only disabled patterns
  --recommended: string@bool-completer # Filter by recommended status. Set to `true` to return only recommended patterns, or `false` to return only non-recommended patterns
]: nothing -> record<data: record<counts: record<languages: list, categories: list, severities: list, tags: list, totalRecommended: int, totalEnabled: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languages" $languages "scalar") (serialize-qp "categories" $categories "scalar") (serialize-qp "severityLevels" $severityLevels "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "enabled" $enabled "scalar") (serialize-qp "recommended" $recommended "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/tools/($toolUuid)/patterns/overview" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patterns with Coding Standards conflicts for tool.
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/tools/{toolUuid}/conflicts
# operationId: listRepositoryToolPatternConflicts
export def "analysis-organizations-repositories-tools-conflicts listRepositoryToolPatternConflicts" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  toolUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<patternId: string, conflicts: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/tools/($toolUuid)/conflicts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the analysis progress of a repository
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/analysis-progress
# operationId: getFirstAnalysisOverview
export def "analysis-organizations-repositories-analysis-progress get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # Name of a [repository branch enabled on Codacy](https://docs.codacy.com/repositories-configure/managing-branches/), as returned by the endpoint [listRepositoryBranches](#listrepositorybranches). By default, uses the main branch defined on the Codacy repository settings.  (e.g. master)
]: nothing -> record<data: table<action: string, complete: bool>, isStuck: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/analysis-progress" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Recover a stuck repository
#
# POST /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/recover
# operationId: recoverRepository
export def "analysis-organizations-repositories-recover recoverRepository" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # Name of a [repository branch enabled on Codacy](https://docs.codacy.com/repositories-configure/managing-branches/), as returned by the endpoint [listRepositoryBranches](#listrepositorybranches). By default, uses the main branch defined on the Codacy repository settings.  (e.g. master)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/recover" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add repository autoconfiguration run
#
# POST /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/autoconfig
# operationId: addAutoconfig
export def "analysis-organizations-repositories-autoconfig addAutoconfig" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/autoconfig")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get autoconfig run status
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/autoconfig/status
# operationId: getAutoconfigStatus
export def "analysis-organizations-repositories-autoconfig-status get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<status: string, requestedAt: string, updatedAt: string, error: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/autoconfig/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List pull requests from a repository that the user has access to
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/pull-requests
# operationId: listRepositoryPullRequests
export def "analysis-organizations-repositories-pull-requests listRepositoryPullRequests" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
  --includeNotAnalyzed: string@bool-completer # If true, also return pull requests that weren't analyzed (default: false)
]: nothing -> record<data: table<isUpToStandards: bool, isAnalysing: bool, pullRequest: record, newIssues: int, fixedIssues: int, deltaComplexity: int, deltaClonesCount: int, deltaCoverageWithDecimals: float, deltaCoverage: int, diffCoverage: float, coverage: record, quality: record, meta: record>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "includeNotAnalyzed" $includeNotAnalyzed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/pull-requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get pull request from a repository
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/pull-requests/{pullRequestNumber}
# operationId: getRepositoryPullRequest
export def "analysis-organizations-repositories-pull-requests get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  pullRequestNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<isUpToStandards: bool, isAnalysing: bool, pullRequest: record<id: int, number: int, updated: string, status: string, repository: string, title: string, owner: record<name: string, avatarUrl: string, username: string, email: string>, headCommitSha: string, commonAncestorCommitSha: string, originBranch: string, targetBranch: string, gitHref: string>, newIssues: int, fixedIssues: int, deltaComplexity: int, deltaClonesCount: int, deltaCoverageWithDecimals: float, deltaCoverage: int, diffCoverage: float, coverage: record<deltaCoverage: float, diffCoverage: record<value: float, coveredLines: int, coverableLines: int, cause: string>, isUpToStandards: bool, resultReasons: list<record>>, quality: record<newIssues: int, fixedIssues: int, deltaComplexity: int, deltaClonesCount: int, isUpToStandards: bool, resultReasons: list<record>>, meta: record<analyzable: bool, reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/pull-requests/($pullRequestNumber)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get pull request coverage information from a repository
#
# GET /coverage/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/pull-requests/{pullRequestNumber}
# operationId: getRepositoryPullRequestCoverage
export def "coverage-organizations-repositories-pull-requests get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  pullRequestNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<pullRequest: record<id: int, number: int, updated: string, status: string, repository: string, title: string, owner: record, headCommitSha: string, commonAncestorCommitSha: string, originBranch: string, targetBranch: string, gitHref: string>, coverage: record<deltaCoverage: float, diffCoverage: record, isUpToStandards: bool, resultReasons: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coverage/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/pull-requests/($pullRequestNumber)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get pull request files coverage information from a repository
#
# GET /coverage/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/pull-requests/{pullRequestNumber}/files
# operationId: getRepositoryPullRequestFilesCoverage
export def "coverage-organizations-repositories-pull-requests-files get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  pullRequestNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<fileName: string, coverage: float, variation: float, diff: record, diffLineHits: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coverage/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/pull-requests/($pullRequestNumber)/files")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Triggers the reanalysis of the latest coverage report uploaded for the pull request
#
# GET /coverage/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/pull-requests/{pullRequestNumber}/reanalyze
# operationId: reanalyzeCoverage
export def "coverage-organizations-repositories-pull-requests-reanalyze reanalyzeCoverage" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  pullRequestNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coverage/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/pull-requests/($pullRequestNumber)/reanalyze")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return analysis results for the commits in a pull request
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/pull-requests/{pullRequestNumber}/commits
# operationId: getPullRequestCommits
export def "analysis-organizations-repositories-pull-requests-commits get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  pullRequestNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<commit: record, coverage: record, quality: record, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/pull-requests/($pullRequestNumber)/commits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bypass analysis status in a pull request
#
# POST /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/pull-requests/{pullRequestNumber}/bypass
# operationId: bypassPullRequestAnalysis
export def "analysis-organizations-repositories-pull-requests-bypass bypassPullRequestAnalysis" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  pullRequestNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/pull-requests/($pullRequestNumber)/bypass")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Triggers an AI review for a pull request
#
# POST /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/pull-requests/{pullRequestNumber}/ai-reviewer/trigger
# operationId: triggerPullRequestAiReview
export def "analysis-organizations-repositories-pull-requests-ai-reviewer-trigger triggerPullRequestAiReview" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  pullRequestNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/pull-requests/($pullRequestNumber)/ai-reviewer/trigger")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all coverage reports uploaded for the common ancestor commit and head commit of a pull request branch
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/pull-requests/{pullRequestNumber}/coverage/status
# operationId: getPullRequestCoverageReports
export def "analysis-organizations-repositories-pull-requests-coverage-status get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  pullRequestNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<headCommit: record<commitId: int, commitSha: string, reports: list>, commonAncestorCommit: record<commitId: int, commitSha: string, reports: list>, origin: record<commitId: int, commitSha: string, reports: list>, target: record<commitId: int, commitSha: string, reports: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/pull-requests/($pullRequestNumber)/coverage/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List issues found in a pull request
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/pull-requests/{pullRequestNumber}/issues
# operationId: listPullRequestIssues
export def "analysis-organizations-repositories-pull-requests-issues listPullRequestIssues" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  pullRequestNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer # Filter issues by status. Valid values are `all`, `new`, or `fixed`. (e.g. all)
  --onlyPotential: string@bool-completer # Set to `true` to return only potential issues (e.g. true)
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<analyzed: bool, data: table<commitIssue: record, deltaType: string>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "onlyPotential" $onlyPotential "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/pull-requests/($pullRequestNumber)/issues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List duplicate code blocks found in a pull request
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/pull-requests/{pullRequestNumber}/clones
# operationId: listPullRequestClones
export def "analysis-organizations-repositories-pull-requests-clones listPullRequestClones" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  pullRequestNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer # Filter issues by status. Valid values are `all`, `new`, or `fixed`. (e.g. all)
  --onlyPotential: string@bool-completer # Set to `true` to return only potential issues (e.g. true)
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<data: table<id: int, status: string, clones: list>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "onlyPotential" $onlyPotential "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/pull-requests/($pullRequestNumber)/clones" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List duplicate code blocks found in a commit
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/commits/{commitUuid}/clones
# operationId: listCommitClones
export def "analysis-organizations-repositories-commits-clones listCommitClones" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  commitUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer # Filter issues by status. Valid values are `all`, `new`, or `fixed`. (e.g. all)
  --onlyPotential: string@bool-completer # Set to `true` to return only potential issues (e.g. true)
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<data: table<id: int, status: string, clones: list>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "onlyPotential" $onlyPotential "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/commits/($commitUuid)/clones" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get analysis logs for a pull request
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/pull-requests/{pullRequestNumber}/logs
# operationId: listPullRequestLogs
export def "analysis-organizations-repositories-pull-requests-logs listPullRequestLogs" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  pullRequestNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<headCommitSha: string, commonAncestorCommitSha: string, start: string, end: string, totalAnalysisTime: int, steps: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/pull-requests/($pullRequestNumber)/logs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get analysis logs for a commit
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/commits/{commitUuid}/logs
# operationId: listCommitLogs
export def "analysis-organizations-repositories-commits-logs listCommitLogs" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  commitUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<headCommitSha: string, commonAncestorCommitSha: string, start: string, end: string, totalAnalysisTime: int, steps: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/commits/($commitUuid)/logs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get quality settings for the specific repository
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/quality-settings
# DEPRECATED
# operationId: getRepositoryQualitySettings
@deprecated
export def "analysis-organizations-repositories-quality-settings get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<issueThreshold: int, duplicationThreshold: int, coverageThreshold: int, complexityThreshold: int, fileDuplicationThreshold: int, fileComplexityThreshold: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/quality-settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List files of a commit with analysis results
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/commits/{commitUuid}/files
# operationId: listCommitFiles
export def "analysis-organizations-repositories-commits-files listCommitFiles" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  commitUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # Name of a [repository branch enabled on Codacy](https://docs.codacy.com/repositories-configure/managing-branches/), as returned by the endpoint [listRepositoryBranches](#listrepositorybranches). By default, uses the main branch defined on the Codacy repository settings.  (e.g. master)
  --filter: string@filter-completer # Optional field to filter the results. The possible values are empty (default, return files changed in the commit or with coverage changes) or `withCoverageChanges` (return files with coverage changes)
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --search: string # Filter files that include this string anywhere in their relative path (e.g. file.js)
  --sortColumn: string@sortColumn-completer # Field used to sort the results. The possible values are `deltaCoverage` (to sort by the coverage variation value of the files), `totalCoverage` (to sort by the total coverage value of the files) or `filename` (default - to sort by the name of the files)  (default: filename)
  --columnOrder: string@columnOrder-completer # Sort direction. The possible values are `asc` (ascending - default) or `desc` (descending). (default: asc)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<file: record, coverage: record, quality: record, comparedWithCommit: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "sortColumn" $sortColumn "scalar") (serialize-qp "columnOrder" $columnOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/commits/($commitUuid)/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List files of a pull request with analysis results
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/pull-requests/{pullRequestNumber}/files
# operationId: listPullRequestFiles
export def "analysis-organizations-repositories-pull-requests-files listPullRequestFiles" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  pullRequestNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --sortColumn: string@sortColumn-completer # Field used to sort the results. The possible values are `deltaCoverage` (to sort by the coverage variation value of the files), `totalCoverage` (to sort by the total coverage value of the files) or `filename` (default - to sort by the name of the files)  (default: filename)
  --columnOrder: string@columnOrder-completer # Sort direction. The possible values are `asc` (ascending - default) or `desc` (descending). (default: asc)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<file: record, coverage: record, quality: record, comparedWithCommit: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sortColumn" $sortColumn "scalar") (serialize-qp "columnOrder" $columnOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/pull-requests/($pullRequestNumber)/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Follow a repository that was already added to Codacy
#
# POST /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/follow
# operationId: followAddedRepository
export def "organizations-repositories-follow followAddedRepository" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/follow")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unfollow a repository
#
# DELETE /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/follow
# operationId: unfollowRepository
export def "organizations-repositories-follow unfollowRepository" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/follow")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get quality settings for the specific repository
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/settings/quality/repository
# operationId: getQualitySettingsForRepository
export def "organizations-repositories-settings-quality-repository get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<maxIssuePercentage: int, maxDuplicatedFilesPercentage: int, minCoveragePercentage: int, maxComplexFilesPercentage: int, fileDuplicationBlockThreshold: int, fileComplexityValueThreshold: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/settings/quality/repository")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update quality goals settings for the specific repository
#
# PUT /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/settings/quality/repository
# operationId: updateRepositoryQualitySettings
export def "organizations-repositories-settings-quality-repository updateRepositoryQualitySettings" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxIssuePercentage: int # The repository will be considered unhealthy if the percentage of issues is over this threshold (format: int32, e.g. 1)
  --maxDuplicatedFilesPercentage: int # The repository will be considered unhealthy if the percentage of duplication of files is over this threshold (format: int32, e.g. 1)
  --minCoveragePercentage: int # The repository will be considered unhealthy if the coverage percentage is under this threshold (format: int32, e.g. 1)
  --maxComplexFilesPercentage: int # The repository will be considered unhealthy if the percentage of complexity of files is over this threshold (format: int32, e.g. 1)
  --fileDuplicationBlockThreshold: int # A file in this repository will be considered duplicated when the number of cloned blocks is over this threshold. This value cannot be negative (format: int32, e.g. 1)
  --fileComplexityValueThreshold: int # A file in this repository will be considered complex when its complexity value is over this threshold. This value cannot be negative (format: int32, e.g. 1)
]: any -> record<data: record<maxIssuePercentage: int, maxDuplicatedFilesPercentage: int, minCoveragePercentage: int, maxComplexFilesPercentage: int, fileDuplicationBlockThreshold: int, fileComplexityValueThreshold: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/settings/quality/repository")
  let body = {maxIssuePercentage: $maxIssuePercentage, maxDuplicatedFilesPercentage: $maxDuplicatedFilesPercentage, minCoveragePercentage: $minCoveragePercentage, maxComplexFilesPercentage: $maxComplexFilesPercentage, fileDuplicationBlockThreshold: $fileDuplicationBlockThreshold, fileComplexityValueThreshold: $fileComplexityValueThreshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Regenerate the user SSH key that Codacy uses to clone the repository
#
# POST /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/settings/ssh-user-key
# operationId: regenerateUserSshKey
export def "organizations-repositories-settings-ssh-user-key regenerateUserSshKey" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<publicSshKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/settings/ssh-user-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Regenerate the SSH key that Codacy uses to clone the repository
#
# POST /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/settings/ssh-repository-key
# operationId: regenerateRepositorySshKey
export def "organizations-repositories-settings-ssh-repository-key regenerateRepositorySshKey" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<publicSshKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/settings/ssh-repository-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the public SSH key for the repository
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/settings/stored-ssh-key
# operationId: getRepositoryPublicSshKey
export def "organizations-repositories-settings-stored-ssh-key get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<publicSshKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/settings/stored-ssh-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Synchronize repository name and visibility with Git provider
#
# POST /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/settings/sync
# operationId: syncRepositoryWithProvider
export def "organizations-repositories-settings-sync syncRepositoryWithProvider" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/settings/sync")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the status of the repository setting **Run analysis on your build server**
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/settings/analysis
# operationId: getBuildServerAnalysisSetting
export def "organizations-repositories-settings-analysis get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<buildServerAnalysisSetting: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/settings/analysis")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the status of the repository setting **Run analysis on your build server**
#
# PATCH /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/settings/analysis
# operationId: updateBuildServerAnalysisSetting
export def "organizations-repositories-settings-analysis updateBuildServerAnalysisSetting" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --buildServerAnalysisSetting: string@bool-completer # If true, Codacy waits for your build server to upload the results of the local analysis before resuming the analysis of your commits. If false, Codacy analyzes your commits directly on its cloud infrastructure.
]: any -> record<buildServerAnalysisSetting: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/settings/analysis")
  let body = {buildServerAnalysisSetting: $buildServerAnalysisSetting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the list of all languages with their extensions and enabled status
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/settings/languages
# operationId: getRepositoryLanguages
export def "organizations-repositories-settings-languages get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<languages: table<name: string, codacyDefaults: list, extensions: list, defaultFiles: list, enabled: bool, detected: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/settings/languages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Configure language settings for this repo
#
# PATCH /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/settings/languages
# operationId: patchRepositoryLanguageResponseSettings
# --languages item shape: {name: string, extensions?: list, enabled?: bool}
export def "organizations-repositories-settings-languages patch" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  languages: list # List of languages for this repository — item shape: {name: string, extensions?: list, enabled?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/settings/languages")
  let body = {languages: $languages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the list of supported file extensions associated with each language in a repository
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/settings/file-extensions
# DEPRECATED
# operationId: getFileExtensionsSettings
@deprecated
export def "organizations-repositories-settings-file-extensions get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<languagesExtensions: table<name: string, codacyDefaults: list, extensions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/settings/file-extensions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the custom file extensions for a repository
#
# PATCH /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/settings/file-extensions
# DEPRECATED
# operationId: patchFileExtensionsSettings
# --languagesExtensions item shape: {name: string, extensions: list}
@deprecated
export def "organizations-repositories-settings-file-extensions patch" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  languagesExtensions: list # List of custom file extensions to associate with each language for a repository — item shape: {name: string, extensions: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/settings/file-extensions")
  let body = {languagesExtensions: $languagesExtensions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get quality settings for the commits of a repository
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/settings/quality/commits
# operationId: getCommitQualitySettings
export def "organizations-repositories-settings-quality-commits get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<qualityGate: record<issueThreshold: record, securityIssueThreshold: int, securityIssueMinimumSeverity: string, duplicationThreshold: int, coverageThreshold: int, coverageThresholdWithDecimals: float, diffCoverageThreshold: int, complexityThreshold: int>, repositoryGatePolicyInfo: record<id: int, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/settings/quality/commits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update quality settings for the commits of a repository
#
# PUT /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/settings/quality/commits
# operationId: updateCommitQualitySettings
# --issueThreshold shape: {threshold: int, minimumSeverity?: "Info"|"Warning"|"High"|"Error"}
export def "organizations-repositories-settings-quality-commits updateCommitQualitySettings" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --issueThreshold: record # The quality gate will fail if there are new issues of the specified severity over this threshold (if no severity is specified all severity levels are considered). This value cannot be negative — shape: {threshold: int, minimumSeverity?: "Info"|"Warning"|"High"|"Error"}
  --securityIssueThreshold: int # The quality gate will fail if the number of new security issues is over this threshold. This value cannot be negative (format: int32, e.g. 1)
  --securityIssueMinimumSeverity: string@securityIssueMinimumSeverity-completer # Issue severity level. These values map to our UI as follows - Info to Minor, Warning to Medium, High to High, Error to Critical. (e.g. Error)
  --duplicationThreshold: int # The quality gate will fail if there are new duplicated blocks over this threshold (format: int32, e.g. 1)
  --coverageThreshold: int # Deprecated, use `coverageThresholdWithDecimals` instead (format: int32, e.g. 1)
  --coverageThresholdWithDecimals: float # The quality gate will fail if coverage percentage varies less than this threshold. This value should be at most 1.00 (format: double, e.g. -0.02)
  --diffCoverageThreshold: int # The quality gate will fail if diff coverage is under this threshold. This value should be at least 0 and at most 100 (format: int32, e.g. 70)
  --complexityThreshold: int # The quality gate will fail if the complexity value is over this threshold. This value cannot be negative (format: int32, e.g. 1)
]: any -> record<data: record<qualityGate: record<issueThreshold: record, securityIssueThreshold: int, securityIssueMinimumSeverity: string, duplicationThreshold: int, coverageThreshold: int, coverageThresholdWithDecimals: float, diffCoverageThreshold: int, complexityThreshold: int>, repositoryGatePolicyInfo: record<id: int, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/settings/quality/commits")
  let body = {issueThreshold: $issueThreshold, securityIssueThreshold: $securityIssueThreshold, securityIssueMinimumSeverity: $securityIssueMinimumSeverity, duplicationThreshold: $duplicationThreshold, coverageThreshold: $coverageThreshold, coverageThresholdWithDecimals: $coverageThresholdWithDecimals, diffCoverageThreshold: $diffCoverageThreshold, complexityThreshold: $complexityThreshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset quality settings for the commits of a repository to Codacy’s default values
#
# POST /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/settings/quality/commits/reset
# operationId: resetCommitsQualitySettings
export def "organizations-repositories-settings-quality-commits-reset resetCommitsQualitySettings" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<qualityGate: record<issueThreshold: record, securityIssueThreshold: int, securityIssueMinimumSeverity: string, duplicationThreshold: int, coverageThreshold: int, coverageThresholdWithDecimals: float, diffCoverageThreshold: int, complexityThreshold: int>, repositoryGatePolicyInfo: record<id: int, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/settings/quality/commits/reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset quality settings for the pull requests of a repository to Codacy’s default values
#
# POST /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/settings/quality/pull-requests/reset
# operationId: resetPullRequestsQualitySettings
export def "organizations-repositories-settings-quality-pull-requests-reset resetPullRequestsQualitySettings" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<qualityGate: record<issueThreshold: record, securityIssueThreshold: int, securityIssueMinimumSeverity: string, duplicationThreshold: int, coverageThreshold: int, coverageThresholdWithDecimals: float, diffCoverageThreshold: int, complexityThreshold: int>, repositoryGatePolicyInfo: record<id: int, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/settings/quality/pull-requests/reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset quality settings for the repository to Codacy’s default values
#
# POST /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/settings/quality/repository/reset
# operationId: resetRepositoryQualitySettings
export def "organizations-repositories-settings-quality-repository-reset resetRepositoryQualitySettings" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<maxIssuePercentage: int, maxDuplicatedFilesPercentage: int, minCoveragePercentage: int, maxComplexFilesPercentage: int, fileDuplicationBlockThreshold: int, fileComplexityValueThreshold: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/settings/quality/repository/reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get quality settings for the pull requests of a repository
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/settings/quality/pull-requests
# operationId: getPullRequestQualitySettings
export def "organizations-repositories-settings-quality-pull-requests get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<qualityGate: record<issueThreshold: record, securityIssueThreshold: int, securityIssueMinimumSeverity: string, duplicationThreshold: int, coverageThreshold: int, coverageThresholdWithDecimals: float, diffCoverageThreshold: int, complexityThreshold: int>, repositoryGatePolicyInfo: record<id: int, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/settings/quality/pull-requests")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update quality settings for the pull requests of a repository
#
# PUT /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/settings/quality/pull-requests
# operationId: updatePullRequestQualitySettings
# --issueThreshold shape: {threshold: int, minimumSeverity?: "Info"|"Warning"|"High"|"Error"}
export def "organizations-repositories-settings-quality-pull-requests updatePullRequestQualitySettings" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --issueThreshold: record # The quality gate will fail if there are new issues of the specified severity over this threshold (if no severity is specified all severity levels are considered). This value cannot be negative — shape: {threshold: int, minimumSeverity?: "Info"|"Warning"|"High"|"Error"}
  --securityIssueThreshold: int # The quality gate will fail if the number of new security issues is over this threshold. This value cannot be negative (format: int32, e.g. 1)
  --securityIssueMinimumSeverity: string@securityIssueMinimumSeverity-completer # Issue severity level. These values map to our UI as follows - Info to Minor, Warning to Medium, High to High, Error to Critical. (e.g. Error)
  --duplicationThreshold: int # The quality gate will fail if there are new duplicated blocks over this threshold (format: int32, e.g. 1)
  --coverageThreshold: int # Deprecated, use `coverageThresholdWithDecimals` instead (format: int32, e.g. 1)
  --coverageThresholdWithDecimals: float # The quality gate will fail if coverage percentage varies less than this threshold. This value should be at most 1.00 (format: double, e.g. -0.02)
  --diffCoverageThreshold: int # The quality gate will fail if diff coverage is under this threshold. This value should be at least 0 and at most 100 (format: int32, e.g. 70)
  --complexityThreshold: int # The quality gate will fail if the complexity value is over this threshold. This value cannot be negative (format: int32, e.g. 1)
]: any -> record<data: record<qualityGate: record<issueThreshold: record, securityIssueThreshold: int, securityIssueMinimumSeverity: string, duplicationThreshold: int, coverageThreshold: int, coverageThresholdWithDecimals: float, diffCoverageThreshold: int, complexityThreshold: int>, repositoryGatePolicyInfo: record<id: int, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/settings/quality/pull-requests")
  let body = {issueThreshold: $issueThreshold, securityIssueThreshold: $securityIssueThreshold, securityIssueMinimumSeverity: $securityIssueMinimumSeverity, duplicationThreshold: $duplicationThreshold, coverageThreshold: $coverageThreshold, coverageThresholdWithDecimals: $coverageThresholdWithDecimals, diffCoverageThreshold: $diffCoverageThreshold, complexityThreshold: $complexityThreshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List organization pull requests from repositories that the user has access to
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/pull-requests
# operationId: listOrganizationPullRequests
@deprecated --flag repositories
export def "analysis-organizations-pull-requests listOrganizationPullRequests" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
  --repositories: string # **Deprecated:** Use [searchOrganizationRepositoriesWithAnalysis](#searchorganizationrepositorieswithanalysis) instead. (DEPRECATED, e.g. codacy-eslint,codacy-pmd)
]: nothing -> record<data: table<isUpToStandards: bool, isAnalysing: bool, pullRequest: record, newIssues: int, fixedIssues: int, deltaComplexity: int, deltaClonesCount: int, deltaCoverageWithDecimals: float, deltaCoverage: int, diffCoverage: float, coverage: record, quality: record, meta: record>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "repositories" $repositories "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/pull-requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List commit analysis statistics for the last n days that have analysis data
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/commit-statistics
# operationId: listCommitAnalysisStats
export def "analysis-organizations-repositories-commit-statistics listCommitAnalysisStats" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # Name of a [repository branch enabled on Codacy](https://docs.codacy.com/repositories-configure/managing-branches/), as returned by the endpoint [listRepositoryBranches](#listrepositorybranches). By default, uses the main branch defined on the Codacy repository settings.  (e.g. master)
  --days: int # Number of days of data to return (1-365, defaults to 31) (format: int32, default: 31, e.g. 31)
]: nothing -> record<data: table<repositoryId: int, commitId: int, numberIssues: int, numberLoc: int, issuesPerCategory: list, issuePercentage: int, totalComplexity: int, numberComplexFiles: int, complexFilesPercentage: int, filesChangedToIncreaseComplexity: int, numberDuplicatedLines: int, duplicationPercentage: int, coveragePercentage: int, coveragePercentageWithDecimals: float, numberFilesUncovered: int, techDebt: int, totalFilesAdded: int, totalFilesRemoved: int, totalFilesChanged: int, commitTimestamp: string, commitAuthorName: string, commitShortUUID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "days" $days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/commit-statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List analysis category overviews for a repository that the user has access to
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/category-overviews
# operationId: listCategoryOverviews
export def "analysis-organizations-repositories-category-overviews listCategoryOverviews" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # Name of a [repository branch enabled on Codacy](https://docs.codacy.com/repositories-configure/managing-branches/), as returned by the endpoint [listRepositoryBranches](#listrepositorybranches). By default, uses the main branch defined on the Codacy repository settings.  (e.g. master)
]: nothing -> record<data: table<commitId: int, category: record, percentage: float, totalResults: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/category-overviews" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List issues in a repository
#
# POST /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/issues/search
# operationId: searchRepositoryIssues
export def "analysis-organizations-repositories-issues-search searchRepositoryIssues" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --branchName: string # Name of a [repository branch enabled on Codacy](https://docs.codacy.com/repositories-configure/managing-branches/), as returned by the endpoint [listRepositoryBranches](#listrepositorybranches). By default, uses the main branch defined on the Codacy repository settings.  (e.g. a-feature-branch-name)
  --patternIds: list # Set of code pattern identifiers, as returned by the endpoint [listPatterns](#listpatterns) (e.g. [ESLint_@typescript-eslint_consistent-indexed-object-style, ESLint_@typescript-eslint_no-redeclare])
  --toolUuids: list # Set of tool UUIDs to filter issues by the tools that detected them (e.g. [847feb32-9ff2-11ea-bb37-0242ac130002, cf05f3aa-fd23-4586-8cce-5571b1904586])
  --languages: list # Set of language names, without spaces (e.g. [Java, Scala, CSS, ObjectiveC])
  --categories: list # Set of issue categories (e.g. [Security, CodeStyle])
  --levels: list # Set of issue severity levels (e.g. [Error, Warning])
  --tags: list # Set of issue pattern tags (e.g. [react, angular])
  --authorEmails: list # Set of commit author email addresses (e.g. [example@mail.com, another@mail.com])
  --potentialFalsePositives: string@bool-completer # If true, only issues that are potential false positives will be included in the search,  if false, only issues that are not potential false positives will be included in the search.  (e.g. true)
]: any -> record<data: table<issueId: string, resultDataId: int, filePath: string, fileId: int, patternInfo: record, toolInfo: record, lineNumber: int, message: string, suggestion: string, language: string, lineText: string, commitInfo: record, falsePositiveProbability: int, falsePositiveReason: string, falsePositiveThreshold: int>, pagination: record<cursor: string, limit: int, total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/issues/search" $qp)
  let body = {branchName: $branchName, patternIds: $patternIds, toolUuids: $toolUuids, languages: $languages, categories: $categories, levels: $levels, tags: $tags, authorEmails: $authorEmails, potentialFalsePositives: $potentialFalsePositives} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk ignore issues in a repository
#
# POST /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/issues/bulk-ignore
# operationId: bulkIgnoreIssues
export def "analysis-organizations-repositories-issues-bulk-ignore bulkIgnoreIssues" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  issueIds: list # List of issue ids to ignore
  --reason: string # Optional reason for ignoring
  --comment: string # Optional comment
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/issues/bulk-ignore")
  let body = {issueIds: $issueIds, reason: $reason, comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an overview of the issues in a repository
#
# POST /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/issues/overview
# operationId: issuesOverview
export def "analysis-organizations-repositories-issues-overview issuesOverview" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branchName: string # Name of a [repository branch enabled on Codacy](https://docs.codacy.com/repositories-configure/managing-branches/), as returned by the endpoint [listRepositoryBranches](#listrepositorybranches). By default, uses the main branch defined on the Codacy repository settings.  (e.g. a-feature-branch-name)
  --patternIds: list # Set of code pattern identifiers, as returned by the endpoint [listPatterns](#listpatterns) (e.g. [ESLint_@typescript-eslint_consistent-indexed-object-style, ESLint_@typescript-eslint_no-redeclare])
  --toolUuids: list # Set of tool UUIDs to filter issues by the tools that detected them (e.g. [847feb32-9ff2-11ea-bb37-0242ac130002, cf05f3aa-fd23-4586-8cce-5571b1904586])
  --languages: list # Set of language names, without spaces (e.g. [Java, Scala, CSS, ObjectiveC])
  --categories: list # Set of issue categories (e.g. [Security, CodeStyle])
  --levels: list # Set of issue severity levels (e.g. [Error, Warning])
  --tags: list # Set of issue pattern tags (e.g. [react, angular])
  --authorEmails: list # Set of commit author email addresses (e.g. [example@mail.com, another@mail.com])
  --potentialFalsePositives: string@bool-completer # If true, only issues that are potential false positives will be included in the search,  if false, only issues that are not potential false positives will be included in the search.  (e.g. true)
]: any -> record<data: record<counts: record<categories: list, languages: list, levels: list, tags: list, patterns: list, authors: list, potentialFalsePositives: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/issues/overview")
  let body = {branchName: $branchName, patternIds: $patternIds, toolUuids: $toolUuids, languages: $languages, categories: $categories, levels: $levels, tags: $tags, authorEmails: $authorEmails, potentialFalsePositives: $potentialFalsePositives} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get information about an open issue in a repository
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/issues/{issueId}
# operationId: getIssue
export def "analysis-organizations-repositories-issues get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  issueId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<issueId: string, resultDataId: int, filePath: string, fileId: int, patternInfo: record<id: string, title: string, category: string, subCategory: string, level: string, severityLevel: string>, toolInfo: record<uuid: string, name: string>, lineNumber: int, message: string, suggestion: string, language: string, lineText: string, commitInfo: record<sha: string, commiter: string, commiterName: string, timestamp: string>, falsePositiveProbability: int, falsePositiveReason: string, falsePositiveThreshold: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/issues/($issueId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ignore or unignore an issue
#
# PATCH /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/issues/{issueId}
# operationId: updateIssueState
export def "analysis-organizations-repositories-issues updateIssueState" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  issueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ignored: string@bool-completer # True if the issue is ignored
  --reason: string@reason-completer # Predefined reason for ignoring the issue (e.g. FalsePositive)
  --comment: string # Optional comment justifying the ignore action
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/issues/($issueId)")
  let body = {ignored: $ignored, reason: $reason, comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Ignore the false positive result in an issue
#
# PATCH /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/issues/{issueId}/false-positive/ignore
# operationId: ignoreFalsePositive
export def "analysis-organizations-repositories-issues-false-positive-ignore ignoreFalsePositive" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  issueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/issues/($issueId)/false-positive/ignore")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List ignored issues in a repository
#
# POST /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/ignoredIssues/search
# operationId: searchRepositoryIgnoredIssues
export def "analysis-organizations-repositories-ignored-issues-search searchRepositoryIgnoredIssues" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --branchName: string # Name of a [repository branch enabled on Codacy](https://docs.codacy.com/repositories-configure/managing-branches/), as returned by the endpoint [listRepositoryBranches](#listrepositorybranches). By default, uses the main branch defined on the Codacy repository settings.  (e.g. a-feature-branch-name)
  --patternIds: list # Set of code pattern identifiers, as returned by the endpoint [listPatterns](#listpatterns) (e.g. [ESLint_@typescript-eslint_consistent-indexed-object-style, ESLint_@typescript-eslint_no-redeclare])
  --toolUuids: list # Set of tool UUIDs to filter issues by the tools that detected them (e.g. [847feb32-9ff2-11ea-bb37-0242ac130002, cf05f3aa-fd23-4586-8cce-5571b1904586])
  --languages: list # Set of language names, without spaces (e.g. [Java, Scala, CSS, ObjectiveC])
  --categories: list # Set of issue categories (e.g. [Security, CodeStyle])
  --levels: list # Set of issue severity levels (e.g. [Error, Warning])
  --tags: list # Set of issue pattern tags (e.g. [react, angular])
  --authorEmails: list # Set of commit author email addresses (e.g. [example@mail.com, another@mail.com])
  --potentialFalsePositives: string@bool-completer # If true, only issues that are potential false positives will be included in the search,  if false, only issues that are not potential false positives will be included in the search.  (e.g. true)
  --ignoreReasons: list
]: any -> record<data: table<issueId: string, reason: string, comment: string, ignoredByName: string, ignoredTimestamp: string, filePath: string, fileId: int, patternInfo: record, toolInfo: record, lineNumber: int, message: string, language: string, lineText: string, commitInfo: record, falsePositiveProbability: int, falsePositiveReason: string, falsePositiveThreshold: int>, pagination: record<cursor: string, limit: int, total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/ignoredIssues/search" $qp)
  let body = {branchName: $branchName, patternIds: $patternIds, toolUuids: $toolUuids, languages: $languages, categories: $categories, levels: $levels, tags: $tags, authorEmails: $authorEmails, potentialFalsePositives: $potentialFalsePositives, ignoreReasons: $ignoreReasons} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return analysis results for the commits in a branch
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/commits
# operationId: listRepositoryCommits
export def "analysis-organizations-repositories-commits listRepositoryCommits" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # Name of a [repository branch enabled on Codacy](https://docs.codacy.com/repositories-configure/managing-branches/), as returned by the endpoint [listRepositoryBranches](#listrepositorybranches). By default, uses the main branch defined on the Codacy repository settings.  (e.g. master)
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<commit: record, coverage: record, quality: record, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/commits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get analysis results for a commit
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/commits/{commitUuid}
# operationId: getCommit
export def "analysis-organizations-repositories-commits get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  commitUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<commit: record<sha: string, id: int, commitTimestamp: string, authorName: string, authorEmail: string, message: string, startedAnalysis: string, endedAnalysis: string, isMergeCommit: bool, gitHref: string, parents: list<string>>, coverage: record<totalCoveragePercentage: float, deltaCoveragePercentage: float, isUpToStandards: bool, resultReasons: list<record>>, quality: record<newIssues: int, fixedIssues: int, deltaComplexity: int, deltaClonesCount: int, isUpToStandards: bool, resultReasons: list<record>>, meta: record<analyzable: bool, reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/commits/($commitUuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get analysis statistics of a commit
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/commits/{commitUuid}/deltaStatistics
# operationId: getCommitDeltaStatistics
export def "analysis-organizations-repositories-commits-delta-statistics get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  commitUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<commitUuid: string, newIssues: int, fixedIssues: int, deltaComplexity: int, deltaCoverage: int, deltaCoverageWithDecimals: float, deltaClonesCount: int, analyzed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/commits/($commitUuid)/deltaStatistics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the issues introduced or fixed by a commit
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/commits/{srcCommitUuid}/deltaIssues
# operationId: listCommitDeltaIssues
export def "analysis-organizations-repositories-commits-delta-issues listCommitDeltaIssues" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  srcCommitUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --targetCommitUuid: string # UUID or SHA string that identifies the target commit (e.g. 2957025d42e8daadf937d4044516f991d21deea4)
  --status: string@status-completer # Filter issues by status. Valid values are `all`, `new`, or `fixed`. (e.g. all)
  --onlyPotential: string@bool-completer # Set to `true` to return only potential issues (e.g. true)
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<analyzed: bool, data: table<commitIssue: record, deltaType: string>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "targetCommitUuid" $targetCommitUuid "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "onlyPotential" $onlyPotential "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/commits/($srcCommitUuid)/deltaIssues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the authenticated user
#
# GET /user
# operationId: getUser
export def "user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: int, name: string, mainEmail: string, otherEmails: list<string>, isAdmin: bool, isActive: bool, created: string, intercomHash: string, zendeskHash: string, pylonHash: string, shouldDoClientQualification: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the authenticated user
#
# DELETE /user
# operationId: deleteUser
export def "user delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the authenticated user
#
# PATCH /user
# operationId: patchUser
export def "user patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # e.g. Foo
  --shouldDoClientQualification: string@bool-completer # e.g. false
]: any -> record<data: record<id: int, name: string, mainEmail: string, otherEmails: list<string>, isAdmin: bool, isActive: bool, created: string, intercomHash: string, zendeskHash: string, pylonHash: string, shouldDoClientQualification: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let body = {name: $name, shouldDoClientQualification: $shouldDoClientQualification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List organizations for the authenticated user
#
# GET /user/organizations
# operationId: listUserOrganizations
export def "user-organizations listUserOrganizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<identifier: int, remoteIdentifier: string, name: string, avatar: string, created: string, provider: string, joinMode: string, type: string, joinStatus: string, singleProviderLogin: bool, hasDastAccess: bool, hasScaEnabled: bool, imageSbomEnabled: bool, hasAiInventoryEnabled: bool, hasFalsePositiveAccess: bool, hasSilentFalsePositiveDetection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organizations for the authenticated user
#
# GET /user/organizations/{provider}
# operationId: listOrganizations
export def "user-organizations listOrganizations" [
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<identifier: int, remoteIdentifier: string, name: string, avatar: string, created: string, provider: string, joinMode: string, type: string, joinStatus: string, singleProviderLogin: bool, hasDastAccess: bool, hasScaEnabled: bool, imageSbomEnabled: bool, hasAiInventoryEnabled: bool, hasFalsePositiveAccess: bool, hasSilentFalsePositiveDetection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user/organizations/($provider)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization for the authenticated user
#
# GET /user/organizations/{provider}/{remoteOrganizationName}
# operationId: getUserOrganization
export def "user-organizations get" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<identifier: int, remoteIdentifier: string, name: string, avatar: string, created: string, provider: string, joinMode: string, type: string, joinStatus: string, singleProviderLogin: bool, hasDastAccess: bool, hasScaEnabled: bool, imageSbomEnabled: bool, hasAiInventoryEnabled: bool, hasFalsePositiveAccess: bool, hasSilentFalsePositiveDetection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/organizations/($provider)/($remoteOrganizationName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List emails for the authenticated user
#
# GET /user/emails
# operationId: listUserEmails
export def "user-emails listUserEmails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<mainEmail: record<email: string, isPrivate: bool>, otherEmails: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/emails")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove an email from user account
#
# POST /user/emails/remove
# operationId: removeUserEmail
export def "user-emails-remove removeUserEmail" [
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
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/emails/remove")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve email notification settings
#
# GET /user/emails/settings
# operationId: getEmailSettings
export def "user-emails-settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<perCommit: bool, perPullRequest: bool, onlyMyActivity: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/emails/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update email notification preferences
#
# PATCH /user/emails/settings
# operationId: updateEmailSettings
export def "user-emails-settings updateEmailSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perCommit: string@bool-completer # Whether to receive notifications for each commit (e.g. false)
  --perPullRequest: string@bool-completer # Whether to receive notifications for pull requests (e.g. true)
  --onlyMyActivity: string@bool-completer # Whether to only receive notifications for your own activity (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/emails/settings")
  let body = {perCommit: $perCommit, perPullRequest: $perPullRequest, onlyMyActivity: $onlyMyActivity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set an email as default
#
# POST /user/emails/set-default
# operationId: setDefaultEmail
export def "user-emails-set-default setDefaultEmail" [
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
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/emails/set-default")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List integrations for the authenticated user
#
# GET /user/integrations
# operationId: listUserIntegrations
export def "user-integrations listUserIntegrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<provider: string, host: string, lastAuthenticated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/integrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an integration for the authenticated user
#
# DELETE /user/integrations/{provider}
# operationId: deleteIntegration
export def "user-integrations delete" [
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/integrations/($provider)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization
#
# GET /organizations/{provider}/{remoteOrganizationName}
# operationId: getOrganization
export def "organizations get" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<organization: record<identifier: int, remoteIdentifier: string, name: string, avatar: string, created: string, provider: string, joinMode: string, type: string, joinStatus: string, singleProviderLogin: bool, hasDastAccess: bool, hasScaEnabled: bool, imageSbomEnabled: bool, hasAiInventoryEnabled: bool, hasFalsePositiveAccess: bool, hasSilentFalsePositiveDetection: bool>, membership: record<userRole: string>, billing: record<isPremium: bool, model: string, code: string, monthly: bool, price: int, pricedPerUser: bool>, paywall: record<organizationDashboard: bool, securityDashboard: bool>, organizationPayWall: record<organizationDashboard: bool>, analysisConfigurationMinimumPermission: string, subscriptions: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete organization
#
# DELETE /organizations/{provider}/{remoteOrganizationName}
# operationId: deleteOrganization
# --joinReason shape: {title: string, notes: list}
# --cancelReason shape: {title: string, notes: list}
export def "organizations delete" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  joinReason: record # shape: {title: string, notes: list}
  cancelReason: record # shape: {title: string, notes: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)")
  let body = {joinReason: $joinReason, cancelReason: $cancelReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get organization by provider installation id
#
# GET /organizations/{provider}/installation/{installationId}
# operationId: getOrganizationByInstallationId
export def "organizations-installation get" [
  provider: string
  installationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<identifier: int, remoteIdentifier: string, name: string, avatar: string, created: string, provider: string, joinMode: string, type: string, joinStatus: string, singleProviderLogin: bool, hasDastAccess: bool, hasScaEnabled: bool, imageSbomEnabled: bool, hasAiInventoryEnabled: bool, hasFalsePositiveAccess: bool, hasSilentFalsePositiveDetection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/installation/($installationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get detailed information about organization billing
#
# GET /organizations/{provider}/{remoteOrganizationName}/billing
# operationId: organizationDetailedBilling
export def "organizations-billing organizationDetailedBilling" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<numberOfSeats: int, numberOfPurchasedSeats: int, paymentPlan: record<isPremium: bool, model: string, code: string, monthly: bool, price: int, pricedPerUser: bool>, plan: record<isPremium: bool, model: string, code: string, monthly: bool, price: int, pricedPerUser: bool, alternatePeriodCode: string>, paymentGateway: string, priceInCents: int, pricePerSeatInCents: int, nextPaymentDate: string, invoiceDetails: record<firstName: string, lastName: string, email: string, country: string, vat: string, address: string, zip: string, state: string>, taxes: list<record>, subscriptions: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/billing")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the information about organization billing
#
# POST /organizations/{provider}/{remoteOrganizationName}/billing
# operationId: updateOrganizationDetailedBilling
export def "organizations-billing updateOrganizationDetailedBilling" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  firstName: string
  lastName: string
  billingEmail: string
  country: string
  vat: string
  address: string
  zip: string
  state: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/billing")
  let body = {firstName: $firstName, lastName: $lastName, billingEmail: $billingEmail, country: $country, vat: $vat, address: $address, zip: $zip, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get card information about organization billing
#
# GET /organizations/{provider}/{remoteOrganizationName}/billing/card
# operationId: organizationBillingCard
export def "organizations-billing-card organizationBillingCard" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<maskedNumber: string, last4: string, expiryMonth: int, expiryYear: int, holderName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/billing/card")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a card to the organization
#
# POST /organizations/{provider}/{remoteOrganizationName}/billing/card
# operationId: organizationBillingAddCard
export def "organizations-billing-card organizationBillingAddCard" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  cardToken: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/billing/card")
  let body = {cardToken: $cardToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a billing estimation
#
# GET /organizations/{provider}/{remoteOrganizationName}/billing/estimation
# operationId: organizationBillingEstimation
export def "organizations-billing-estimation organizationBillingEstimation" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --paymentPlanCode: string # Payment plan code (available codes can be retrieved using [listPaymentPlans](#listpaymentplans)) (e.g. standard-team)
  --promoCode: string # Optional promotional code to apply to the billing estimation.
]: nothing -> record<data: record<perSeatCents: int, seats: int, taxes: list<record>, discountCents: int, subTotalCents: int, totalCents: int, nextBilling: string, isMonthly: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paymentPlanCode" $paymentPlanCode "scalar") (serialize-qp "promoCode" $promoCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/billing/estimation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change the plan of an organization
#
# POST /organizations/{provider}/{remoteOrganizationName}/billing/change-plan
# operationId: changeOrganizationPlan
export def "organizations-billing-change-plan changeOrganizationPlan" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  code: string # The code that uniquely identifies the payment plan
  --promoCode: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/billing/change-plan")
  let body = {code: $code, promoCode: $promoCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sync the information about organization billing
#
# POST /organizations/{provider}/{remoteOrganizationName}/billing/sync
# operationId: syncMarketplaceBilling
export def "organizations-billing-sync syncMarketplaceBilling" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/billing/sync")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply default settings to all repositories
#
# POST /organizations/{provider}/{remoteOrganizationName}/integrations/providerSettings/apply
# operationId: applyProviderSettings
export def "organizations-integrations-provider-settings-apply applyProviderSettings" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/integrations/providerSettings/apply")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Git provider settings
#
# GET /organizations/{provider}/{remoteOrganizationName}/integrations/providerSettings
# operationId: getProviderSettings
export def "organizations-integrations-provider-settings get" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<commitStatus: bool, pullRequestComment: bool, pullRequestSummary: bool, coverageSummary: bool, suggestions: bool, aiEnhancedComments: bool, aiPullRequestReviewer: bool, aiPullRequestReviewerAutomatic: bool, pullRequestUnifiedSummary: bool, availableSettings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/integrations/providerSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update Git provider settings
#
# PATCH /organizations/{provider}/{remoteOrganizationName}/integrations/providerSettings
# operationId: updateProviderSettings
export def "organizations-integrations-provider-settings updateProviderSettings" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --commitStatus: string@bool-completer # Toggle the feature "Status checks"
  --pullRequestComment: string@bool-completer # Toggle the feature "Issue annotations"
  --pullRequestSummary: string@bool-completer # Toggle the feature "Issue summaries"
  --coverageSummary: string@bool-completer # Toggle the feature "Coverage summary" (GitHub only)
  --suggestions: string@bool-completer # Toggle the feature "Suggested fixes" (GitHub only)
  --aiEnhancedComments: string@bool-completer # Toggle the feature "AI-enhanced comments". If "Suggested fixes" (GitHub only) is also enabled, then the AI-enhanced comments also provide suggested fixes.
  --aiPullRequestReviewer: string@bool-completer # Toggle the feature "AI Pull Request Reviewer" (GitHub only). When enabled, Codacy will use AI to review pull requests and provide comments on code quality and potential issues.
  --aiPullRequestReviewerAutomatic: string@bool-completer # Toggle the feature "AI Pull Request Reviewer Automatic" (GitHub only). When enabled, Codacy will use AI to review pull requests and provide comments on code quality and potential issues automatically once, subsequent reviews will have to be explicitly requested.
  --pullRequestUnifiedSummary: string@bool-completer # Toggle the feature "Pull Request Unified Summary" (GitHub only). When enabled, Codacy provides a unified summary (coverage and analysis).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/integrations/providerSettings")
  let body = {commitStatus: $commitStatus, pullRequestComment: $pullRequestComment, pullRequestSummary: $pullRequestSummary, coverageSummary: $coverageSummary, suggestions: $suggestions, aiEnhancedComments: $aiEnhancedComments, aiPullRequestReviewer: $aiPullRequestReviewer, aiPullRequestReviewerAutomatic: $aiPullRequestReviewerAutomatic, pullRequestUnifiedSummary: $pullRequestUnifiedSummary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Git provider integration settings for a repository
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/integrations/providerSettings
# operationId: getRepositoryIntegrationsSettings
export def "organizations-repositories-integrations-provider-settings get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<settings: record<commitStatus: bool, pullRequestComment: bool, pullRequestSummary: bool, coverageSummary: bool, suggestions: bool, aiEnhancedComments: bool, aiPullRequestReviewer: bool, aiPullRequestReviewerAutomatic: bool, pullRequestUnifiedSummary: bool, availableSettings: list<string>>, integratedBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/integrations/providerSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Git provider integration settings for a repository
#
# PATCH /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/integrations/providerSettings
# operationId: updateRepositoryIntegrationsSettings
export def "organizations-repositories-integrations-provider-settings updateRepositoryIntegrationsSettings" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --commitStatus: string@bool-completer # Toggle the feature "Status checks"
  --pullRequestComment: string@bool-completer # Toggle the feature "Issue annotations"
  --pullRequestSummary: string@bool-completer # Toggle the feature "Issue summaries"
  --coverageSummary: string@bool-completer # Toggle the feature "Coverage summary" (GitHub only)
  --suggestions: string@bool-completer # Toggle the feature "Suggested fixes" (GitHub only)
  --aiEnhancedComments: string@bool-completer # Toggle the feature "AI-enhanced comments". If "Suggested fixes" (GitHub only) is also enabled, then the AI-enhanced comments also provide suggested fixes.
  --aiPullRequestReviewer: string@bool-completer # Toggle the feature "AI Pull Request Reviewer" (GitHub only). When enabled, Codacy will use AI to review pull requests and provide comments on code quality and potential issues.
  --aiPullRequestReviewerAutomatic: string@bool-completer # Toggle the feature "AI Pull Request Reviewer Automatic" (GitHub only). When enabled, Codacy will use AI to review pull requests and provide comments on code quality and potential issues automatically once, subsequent reviews will have to be explicitly requested.
  --pullRequestUnifiedSummary: string@bool-completer # Toggle the feature "Pull Request Unified Summary" (GitHub only). When enabled, Codacy provides a unified summary (coverage and analysis).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/integrations/providerSettings")
  let body = {commitStatus: $commitStatus, pullRequestComment: $pullRequestComment, pullRequestSummary: $pullRequestSummary, coverageSummary: $coverageSummary, suggestions: $suggestions, aiEnhancedComments: $aiEnhancedComments, aiPullRequestReviewer: $aiPullRequestReviewer, aiPullRequestReviewerAutomatic: $aiPullRequestReviewerAutomatic, pullRequestUnifiedSummary: $pullRequestUnifiedSummary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a [post-commit hook](https://docs.codacy.com/repositories-configure/integrations/post-commit-hooks/) for a repository
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/integrations/postCommitHook
# operationId: createPostCommitHook
export def "organizations-repositories-integrations-post-commit-hook createPostCommitHook" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/integrations/postCommitHook")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refresh the Git provider integration for a repository (GitLab and Bitbucket only)
#
# POST /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/integrations/refreshProvider
# operationId: refreshProviderRepositoryIntegration
export def "organizations-repositories-integrations-refresh-provider refreshProviderRepositoryIntegration" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/integrations/refreshProvider")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organization repositories for the authenticated user
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories
# operationId: listOrganizationRepositories
export def "organizations-repositories listOrganizationRepositories" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
  --filter: string@filter-completer-1 # Filter for which repositories to return. Use `Synced` for repositories the user has access to, `NotSynced` for repositories fetched from the provider, or `AllSynced` for all organization repositories (requires admin access) (e.g. Synced)
  --languages: string # Comma-separated list of programming languages to filter results by (e.g. Scala,Java,Javascript)
  --segments: string # Filter by a comma-separated list of segment identifiers (e.g. 1,2,3)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<repositoryId: int, provider: string, owner: string, name: string, fullPath: string, visibility: string, remoteIdentifier: string, lastUpdated: string, permission: string, problems: list, languages: list, defaultBranch: record, badges: record, codingStandardId: int, codingStandardName: string, standards: list, addedState: string, gatePolicyId: int, gatePolicyName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "languages" $languages "scalar") (serialize-qp "segments" $segments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the onboarding progress of an organization
#
# GET /onboarding/organizations/{provider}/{remoteOrganizationName}/progress
# operationId: retrieveOrganizationOnboardingProgress
export def "onboarding-organizations-progress retrieveOrganizationOnboardingProgress" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<step: string, isCompleted: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/onboarding/organizations/($provider)/($remoteOrganizationName)/progress")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List people of an organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/people
# operationId: listPeopleFromOrganization
export def "organizations-people listPeopleFromOrganization" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
  --onlyMembers: string@bool-completer # If true, returns only Codacy users. If false, returns also commit authors that are not Codacy users. (default: false, e.g. true)
]: nothing -> record<data: table<name: string, email: string, emails: list, userId: int, committerId: int, lastLogin: string, lastAnalysis: string, isActive: bool, canBeRemoved: bool, lastCommitId: int, providerId: string, providerLogin: string, isProviderRegistered: bool>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "onlyMembers" $onlyMembers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/people" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add people to organization
#
# POST /organizations/{provider}/{remoteOrganizationName}/people
# operationId: addPeopleToOrganization
export def "organizations-people addPeopleToOrganization" [
  provider: string
  remoteOrganizationName: string
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
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/people")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a CSV file listing the people of an organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/peopleCsv
# operationId: listPeopleFromOrganizationCsv
export def "organizations-people-csv listPeopleFromOrganizationCsv" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/peopleCsv")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Configure what your organization members can do across the Codacy platform
#
# PATCH /organizations/{provider}/{remoteOrganizationName}/analysisConfigurationMinimumPermission
# operationId: patchOrganizationSettings
export def "organizations-analysis-configuration-minimum-permission patch" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permission: string@permission-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/analysisConfigurationMinimumPermission")
  let body = {permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove people from an organization
#
# POST /organizations/{provider}/{remoteOrganizationName}/people/remove
# operationId: removePeopleFromOrganization
export def "organizations-people-remove removePeopleFromOrganization" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  emails: list # List of emails to add
]: any -> record<success: table<email: string, error: string>, failed: table<email: string, error: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/people/remove")
  let body = {emails: $emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the status of Codacy Git provider app permissions for an organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/gitProviderAppPermissions
# operationId: gitProviderAppPermissions
export def "organizations-git-provider-app-permissions gitProviderAppPermissions" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<contentPermission: bool, customPropertiesPermission: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/gitProviderAppPermissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List people suggestions for an organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/people/suggestions
# operationId: peopleSuggestionsForOrganization
export def "organizations-people-suggestions peopleSuggestionsForOrganization" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<commitEmail: string, totalProjects: int, totalCommits: int, lastCommit: string, projectCommitStats: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/people/suggestions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reanalyze a specific commit in a repository
#
# POST /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/reanalyzeCommit
# operationId: reanalyzeCommitById
export def "organizations-repositories-reanalyze-commit reanalyzeCommitById" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  commitUuid: string # UUID or SHA string that identifies the commit
  --cleanCache: string@bool-completer # If true, the cache will be cleaned before the analysis (e.g. false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/reanalyzeCommit")
  let body = {commitUuid: $commitUuid, cleanCache: $cleanCache} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch the specified repository
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}
# operationId: getRepository
export def "organizations-repositories get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<repositoryId: int, provider: string, owner: string, name: string, fullPath: string, visibility: string, remoteIdentifier: string, lastUpdated: string, permission: string, problems: list<record>, languages: list<string>, defaultBranch: record<id: int, name: string, isDefault: bool, isEnabled: bool, lastUpdated: string, branchType: string, lastCommit: string>, badges: record<grade: string, coverage: string>, codingStandardId: int, codingStandardName: string, standards: list<record>, addedState: string, gatePolicyId: int, gatePolicyName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the specified repository
#
# DELETE /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}
# operationId: deleteRepository
export def "organizations-repositories delete" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List people suggestions for a repository
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/people/suggestions
# operationId: peopleSuggestionsForRepository
export def "organizations-repositories-people-suggestions peopleSuggestionsForRepository" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<commitEmail: string, projectCommitStat: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/people/suggestions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List repository branches
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/branches
# operationId: listRepositoryBranches
export def "organizations-repositories-branches listRepositoryBranches" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Filter by branch status. Set to `true` to return only enabled branches, or `false` to return only disabled branches
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
  --qp-sort: string # Field used to sort the list of branches. The allowed values are 'name' and 'last-updated'. (e.g. category)
  --direction: string # Sort direction. Possible values are 'asc' (ascending) or 'desc' (descending). (e.g. desc)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<id: int, name: string, isDefault: bool, isEnabled: bool, lastUpdated: string, branchType: string, lastCommit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enabled" $enabled "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/branches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the settings for a repository branch
#
# PATCH /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/branches/{branchName}
# operationId: updateRepositoryBranchConfiguration
export def "organizations-repositories-branches updateRepositoryBranchConfiguration" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  branchName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isEnabled: string@bool-completer # True if Codacy should analyze the branch (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/branches/($branchName)")
  let body = {isEnabled: $isEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the join mode of an organization
#
# POST /organizations/{provider}/{remoteOrganizationName}/joinMode
# operationId: updateJoinMode
export def "organizations-join-mode updateJoinMode" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  joinMode: string@joinMode-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/joinMode")
  let body = {joinMode: $joinMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set branch as default
#
# POST /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/branches/{branchName}/setDefault
# operationId: setRepositoryBranchAsDefault
export def "organizations-repositories-branches-set-default setRepositoryBranchAsDefault" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  branchName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/branches/($branchName)/setDefault")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get branch required status checks
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/branches/{branchName}/required-checks
# operationId: getBranchRequiredChecks
export def "organizations-repositories-branches-required-checks get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  branchName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<quality: bool, diffCoverage: bool, coverageVariation: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/branches/($branchName)/required-checks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a pull request adding the Codacy analysis badge to the repository
#
# POST /organizations/gh/{remoteOrganizationName}/repositories/{repositoryName}/badge
# operationId: createBadgePullRequest
export def "organizations-gh-repositories-badge createBadgePullRequest" [
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/gh/($remoteOrganizationName)/repositories/($repositoryName)/badge")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if the user can leave the organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/people/leave/check
# operationId: checkIfUserCanLeave
export def "organizations-people-leave-check checkIfUserCanLeave" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<canLeave: bool, message: string, reason: record<actions: list<record>, code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/people/leave/check")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List requests to join an organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/join
# operationId: listOrganizationJoinRequests
export def "organizations-join listOrganizationJoinRequests" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<email: string, name: string, numberOfCommits: int, numberOfRepositories: int, lastActivity: string, creationDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/join" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Join an organization
#
# POST /organizations/{provider}/{remoteOrganizationName}/join
# operationId: joinOrganization
export def "organizations-join joinOrganization" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organizationIdentifier: int, joinStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/join")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Decline requests to join an organization
#
# DELETE /organizations/{provider}/{remoteOrganizationName}/join
# operationId: declineRequestsToJoinOrganization
export def "organizations-join declineRequestsToJoinOrganization" [
  provider: string
  remoteOrganizationName: string
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
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/join")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a request to join an organization
#
# DELETE /organizations/{provider}/{remoteOrganizationName}/join/{accountIdentifier}
# operationId: deleteOrganizationJoinRequest
export def "organizations-join delete" [
  provider: string
  remoteOrganizationName: string
  accountIdentifier: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/join/($accountIdentifier)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Clean organization cache for the authenticated user
#
# POST /organizations/{provider}/{remoteOrganizationName}/cache/clean
# operationId: cleanCache
export def "organizations-cache-clean cleanCache" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/cache/clean")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a repository to Codacy
#
# POST /repositories
# operationId: addRepository
export def "repositories addRepository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --caller: string # Optional identifier for the calling application or service.
  repositoryFullPath: string # Full path of the repository on the Git provider, starting at the organization. Separate each segment of the path with a slash (/). (e.g. codacy/codacy-analysis-cli)
  provider: string # Git provider hosting the repository (e.g. gh)
]: any -> record<repositoryId: int, provider: string, owner: string, name: string, fullPath: string, visibility: string, remoteIdentifier: string, lastUpdated: string, permission: string, problems: table<message: string, actions: list, code: string, severity: string>, languages: list<string>, defaultBranch: record<id: int, name: string, isDefault: bool, isEnabled: bool, lastUpdated: string, branchType: string, lastCommit: string>, badges: record<grade: string, coverage: string>, codingStandardId: int, codingStandardName: string, standards: table<id: int, name: string>, addedState: string, gatePolicyId: int, gatePolicyName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/repositories")
  let body = {repositoryFullPath: $repositoryFullPath, provider: $provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"caller": $caller} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add an organization to Codacy
#
# POST /organizations
# operationId: addOrganization
export def "organizations addOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  provider: string # Git provider hosting the repository (e.g. gh)
  remoteIdentifier: string
  name: string # e.g. FooOrganization
  type: string@type-completer # The type of Organization (e.g. Organization)
  --products: list
]: any -> record<organization: record<identifier: int, remoteIdentifier: string, name: string, avatar: string, created: string, provider: string, joinMode: string, type: string, joinStatus: string, singleProviderLogin: bool, hasDastAccess: bool, hasScaEnabled: bool, imageSbomEnabled: bool, hasAiInventoryEnabled: bool, hasFalsePositiveAccess: bool, hasSilentFalsePositiveDetection: bool>, warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizations")
  let body = {provider: $provider, remoteIdentifier: $remoteIdentifier, name: $name, type: $type, products: $products} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Enterprise account token
#
# DELETE /user/enterprise/integrations/{provider}
# operationId: deleteEnterpriseToken
export def "user-enterprise-integrations delete" [
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/enterprise/integrations/($provider)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Clean enterprise cache for the authenticated user
#
# POST /enterprises/{provider}/cache/clean
# operationId: cleanEnterpriseCache
export def "enterprises-cache-clean cleanEnterpriseCache" [
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enterprises/($provider)/cache/clean")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user configured enterprise provider account tokens on Codacy's platform
#
# GET /user/enterprise/integrations
# operationId: listUserEnterpriseProviderTokens
export def "user-enterprise-integrations listUserEnterpriseProviderTokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<provider: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/enterprise/integrations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an Enterprise account token
#
# POST /user/enterprise/integrations
# operationId: addEnterpriseToken
export def "user-enterprise-integrations addEnterpriseToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string
  provider: string # Git provider hosting the repository (e.g. gh)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/enterprise/integrations")
  let body = {token: $body_token, provider: $provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the [account API tokens](https://docs.codacy.com/codacy-api/api-tokens/) of the authenticated user
#
# GET /user/tokens
# operationId: getUserApiTokens
export def "user-tokens get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<id: int, token: string, expiresAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new [account API token](https://docs.codacy.com/codacy-api/api-tokens/) for the authenticated user
#
# POST /user/tokens
# operationId: createUserApiToken
export def "user-tokens createUserApiToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expiresAt: string # format: date-time, e.g. 2019-05-07T14:29:13.43Z
]: any -> record<id: int, token: string, expiresAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/tokens")
  let body = {expiresAt: $expiresAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an [account API token](https://docs.codacy.com/codacy-api/api-tokens/) for the authenticated user by ID
#
# DELETE /user/tokens/{tokenId}
# operationId: deleteUserApiToken
export def "user-tokens delete" [
  tokenId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/tokens/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete billing subscription for organization
#
# DELETE /billing/{provider}/{remoteOrganizationName}/subscription
# operationId: deleteSubscription
# --joinReason shape: {title: string, notes: list}
# --cancelReason shape: {title: string, notes: list}
export def "billing-subscription delete" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  joinReason: record # shape: {title: string, notes: list}
  cancelReason: record # shape: {title: string, notes: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/billing/($provider)/($remoteOrganizationName)/subscription")
  let body = {joinReason: $joinReason, cancelReason: $cancelReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List configured login providers on Codacy's platform
#
# GET /login/integrations
# operationId: listConfiguredLoginIntegrations
export def "login-integrations listConfiguredLoginIntegrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<provider: string, loginUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/login/integrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List provider integrations existing on Codacy's platform
#
# GET /provider/integrations
# operationId: listProviderIntegrations
export def "provider-integrations listProviderIntegrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<provider: string, redirectUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/provider/integrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get configuration status
#
# GET /configuration/status
# operationId: getConfigurationStatus
export def "configuration-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<statuses: list<string>, metadata: record<firstSignupDone: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/configuration/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Health check endpoint
#
# GET /health
# operationId: health
export def "health health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# (Codacy admins only) Search for an entity like Organization or Repository, supports ids and names
#
# GET /admin
# operationId: adminSearch
export def "admin adminSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
]: nothing -> record<data: table<slug: string, items: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# (Codacy admins only) Returns the requested admin entity
#
# GET /admin/{adminEntityGroupSlug}/{adminEntityIdentifier}
# operationId: getAdminEntity
export def "admin get" [
  adminEntityGroupSlug: string
  adminEntityIdentifier: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: int, groupSlug: string, displayName: string, details: record, relatedEntities: list<record>, availableResources: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/($adminEntityGroupSlug)/($adminEntityIdentifier)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# (Codacy admins only) Returns the requested resources of a given admin entity
#
# GET /admin/{adminEntityGroupSlug}/{adminEntityIdentifier}/{adminResourceSlug}
# operationId: listAdminEntityResources
export def "admin listAdminEntityResources" [
  adminEntityGroupSlug: string
  adminEntityIdentifier: int
  adminResourceSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<data: table<details: record, entityIdentification: record>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/($adminEntityGroupSlug)/($adminEntityIdentifier)/($adminResourceSlug)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# (Codacy admins only) Generates a license for self-hosted instances of Codacy
#
# POST /admin/license
# operationId: generateLicense
export def "admin-license generateLicense" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  numberOfSeats: int # format: int32, e.g. 100
  email: string # e.g. name@domain.com
  expirationDate: string # format: date-time, e.g. 2019-05-07T14:29:13.43Z
  --inactivityThreshold: int # format: int32, e.g. 4
  --autoAddAuthors: string@bool-completer
  --allowSeatsOverflow: string@bool-completer
]: any -> record<data: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/license")
  let body = {numberOfSeats: $numberOfSeats, email: $email, expirationDate: $expirationDate, inactivityThreshold: $inactivityThreshold, autoAddAuthors: $autoAddAuthors, allowSeatsOverflow: $allowSeatsOverflow} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# (Codacy admins only) Delete Codacy users based on a CSV file exported by GitHub Enterprise
#
# DELETE /admin/dormantAccounts
# operationId: deleteDormantAccounts
export def "admin-dormant-accounts delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<data: table<email: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/dormantAccounts")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "text/plain" $body
}

# Upload pen test reports for an organization (internal, Codacy admins only)
#
# POST /admin/security/penTest/reports
# operationId: uploadPenTestReport
export def "admin-security-pen-test-reports uploadPenTestReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  csvdata: string # The pen test report in CSV format (format: binary)
  provider: string # Git provider hosting the organization's repositories
  organizationName: string # The name of the organization to which the results belong
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/security/penTest/reports")
  let body = {csvdata: $csvdata, provider: $provider, organizationName: $organizationName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve the list of languages supported by available tools
#
# GET /languages/tools
# operationId: listLanguagesWithTools
export def "languages-tools listLanguagesWithTools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<name: string, fileExtensions: list, files: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/languages/tools")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the list of tools
#
# GET /tools
# operationId: listTools
export def "tools listTools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<data: table<uuid: string, name: string, version: string, shortName: string, documentationUrl: string, sourceCodeUrl: string, prefix: string, needsCompilation: bool, configurationFilenames: list, description: string, dockerImage: string, languages: list, clientSide: bool, standalone: bool, enabledByDefault: bool, configurable: bool>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the list of tool patterns
#
# GET /tools/{toolUuid}/patterns
# operationId: listPatterns
export def "tools-patterns listPatterns" [
  toolUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --enabled: string@bool-completer # Filter by enabled status. Set to `true` to return only enabled patterns, or `false` to return only disabled patterns.
]: nothing -> record<data: table<id: string, title: string, category: string, subCategory: string, level: string, severityLevel: string, description: string, explanation: string, enabled: bool, languages: list, timeToFix: int, parameters: list, rationale: string, solution: string, goodExamples: list, badExamples: list, tags: list>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "enabled" $enabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tools/($toolUuid)/patterns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add feedback relating to the tool pattern
#
# POST /tools/{toolUuid}/patterns/{patternId}/organizations/{provider}/{remoteOrganizationName}/feedback
# operationId: addPatternFeedback
export def "tools-patterns-organizations-feedback addPatternFeedback" [
  toolUuid: string
  patternId: string
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reactionFeedback: string@bool-completer # True if the enriched pattern in mention is considered good/relevant by the user
  --feedback: string # Feedback from the user to describe why enriched pattern is not considered good/relevant
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tools/($toolUuid)/patterns/($patternId)/organizations/($provider)/($remoteOrganizationName)/feedback")
  let body = {reactionFeedback: $reactionFeedback, feedback: $feedback} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a tool pattern
#
# GET /tools/{toolUuid}/patterns/{patternId}
# operationId: getPattern
export def "tools-patterns get" [
  toolUuid: string
  patternId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: string, title: string, category: string, subCategory: string, level: string, severityLevel: string, description: string, explanation: string, enabled: bool, languages: list<string>, timeToFix: int, parameters: list<record>, rationale: string, solution: string, goodExamples: list<string>, badExamples: list<string>, tags: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tools/($toolUuid)/patterns/($patternId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the list of duplication tools
#
# GET /duplicationTools
# operationId: listDuplicationTools
export def "duplication-tools listDuplicationTools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<dockerImage: string, languages: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/duplicationTools")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the list of metrics tools
#
# GET /metricsTools
# operationId: listMetricsTools
export def "metrics-tools listMetricsTools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<dockerImage: string, languages: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metricsTools")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start collecting metrics for an organization
#
# POST /organizations/{provider}/{remoteOrganizationName}/metrics/start
# operationId: initiateMetricsForOrganization
export def "organizations-metrics-start initiateMetricsForOrganization" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  metrics: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/metrics/start")
  let body = {metrics: $metrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve metrics that are ready for an organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/metrics/ready
# operationId: readyMetricsForOrganization
export def "organizations-metrics-ready readyMetricsForOrganization" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<organizationId: int, provider: string, organizationName: string, readyMetrics: list<string>, startedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/metrics/ready")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the latest value of a metric
#
# POST /organizations/{provider}/{remoteOrganizationName}/metrics/{metricName}/latest
# operationId: retrieveLatestMetricValue
# --entityFilter shape: {repositories?: list, segmentIds?: list}
# --dimensionsFilter item shape: {dimension: string, value: string}
export def "organizations-metrics-latest retrieveLatestMetricValue" [
  provider: string
  remoteOrganizationName: string
  metricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  entityFilter: record # shape: {repositories?: list, segmentIds?: list}
  --dimensionsFilter: list # item shape: {dimension: string, value: string}
]: any -> record<data: record<value: float, latestValue: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/metrics/($metricName)/latest")
  let body = {entityFilter: $entityFilter, dimensionsFilter: $dimensionsFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the latest metric values grouped by dimension
#
# POST /organizations/{provider}/{remoteOrganizationName}/metrics/{metricName}/latest-grouped
# operationId: retrieveLatestMetricGroupedValues
# --filter shape: {entityFilter: record, dimensionsFilter?: list}
# --groupBy shape: {groupBy: list, sortDirection?: string, limit?: int}
export def "organizations-metrics-latest-grouped retrieveLatestMetricGroupedValues" [
  provider: string
  remoteOrganizationName: string
  metricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filter: record # shape: {entityFilter: record, dimensionsFilter?: list}
  groupBy: record # shape: {groupBy: list, sortDirection?: string, limit?: int}
]: any -> record<data: table<group: record, value: float, latestValue: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/metrics/($metricName)/latest-grouped")
  let body = {filter: $filter, groupBy: $groupBy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve metric value for a specific period
#
# POST /organizations/{provider}/{remoteOrganizationName}/metrics/{metricName}/period
# operationId: retrieveValueForPeriod
# --filter shape: {entityFilter: record, dimensionsFilter?: list}
export def "organizations-metrics-period retrieveValueForPeriod" [
  provider: string
  remoteOrganizationName: string
  metricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filter: record # shape: {entityFilter: record, dimensionsFilter?: list}
  date: string # format: date-time
  period: string@period-completer # e.g. week
]: any -> record<data: record<value: float, latestValue: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/metrics/($metricName)/period")
  let body = {filter: $filter, date: $date, period: $period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve metric values for a specific period grouped by dimension
#
# POST /organizations/{provider}/{remoteOrganizationName}/metrics/{metricName}/period-grouped
# operationId: retrieveGroupedValuesForPeriod
# --filter shape: {entityFilter: record, dimensionsFilter?: list}
# --groupBy shape: {groupBy: list, sortDirection?: string, limit?: int}
export def "organizations-metrics-period-grouped retrieveGroupedValuesForPeriod" [
  provider: string
  remoteOrganizationName: string
  metricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filter: record # shape: {entityFilter: record, dimensionsFilter?: list}
  groupBy: record # shape: {groupBy: list, sortDirection?: string, limit?: int}
  date: string # format: date-time
  period: string@period-completer # e.g. week
]: any -> record<data: table<group: record, value: float, latestValue: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/metrics/($metricName)/period-grouped")
  let body = {filter: $filter, groupBy: $groupBy, date: $date, period: $period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve metric values for a time range
#
# POST /organizations/{provider}/{remoteOrganizationName}/metrics/{metricName}/timerange
# operationId: retrieveTimerangeMetricValues
# --filter shape: {entityFilter: record, dimensionsFilter?: list}
# --groupBy shape: {groupBy: list, sortDirection?: string, limit?: int}
export def "organizations-metrics-timerange retrieveTimerangeMetricValues" [
  provider: string
  remoteOrganizationName: string
  metricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filter: record # shape: {entityFilter: record, dimensionsFilter?: list}
  groupBy: record # shape: {groupBy: list, sortDirection?: string, limit?: int}
  --body-from: string # format: date-time
  --body-to: string # format: date-time
  --period: string@period-completer # e.g. week
]: any -> record<data: table<date: string, group: record, value: float, latestValue: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/metrics/($metricName)/timerange")
  let body = {filter: $filter, groupBy: $groupBy, from: $body_from, to: $body_to, period: $period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve metrics that are ready for each organization in an enterprise
#
# GET /enterprises/{provider}/{enterpriseName}/metrics/ready
# operationId: readyMetricsForEnterprise
export def "enterprises-metrics-ready readyMetricsForEnterprise" [
  provider: string
  enterpriseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<organizationId: int, organizationName: string, readyMetrics: list, startedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enterprises/($provider)/($enterpriseName)/metrics/ready")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve latest metric values for all organizations in an enterprise
#
# POST /enterprises/{provider}/{enterpriseName}/metrics/{metricName}/latest
# operationId: retrieveLatestMetricValueForEnterprise
# --dimensionsFilter item shape: {dimension: string, value: string}
export def "enterprises-metrics-latest retrieveLatestMetricValueForEnterprise" [
  provider: string
  enterpriseName: string
  metricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dimensionsFilter: list # item shape: {dimension: string, value: string}
]: any -> record<data: record<value: float, latestValue: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enterprises/($provider)/($enterpriseName)/metrics/($metricName)/latest")
  let body = {dimensionsFilter: $dimensionsFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve latest metric values grouped by dimension for all organizations in an enterprise
#
# POST /enterprises/{provider}/{enterpriseName}/metrics/{metricName}/latest-grouped
# operationId: retrieveLatestMetricGroupedValuesForEnterprise
# --groupBy shape: {groupBy: list, sortDirection?: string, limit?: int}
# --filter shape: {dimensionsFilter?: list}
export def "enterprises-metrics-latest-grouped retrieveLatestMetricGroupedValuesForEnterprise" [
  provider: string
  enterpriseName: string
  metricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  groupBy: record # shape: {groupBy: list, sortDirection?: string, limit?: int}
  filter: record # shape: {dimensionsFilter?: list}
]: any -> record<data: table<group: record, value: float, latestValue: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enterprises/($provider)/($enterpriseName)/metrics/($metricName)/latest-grouped")
  let body = {groupBy: $groupBy, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve metric values for a specific period for all organizations in an enterprise
#
# POST /enterprises/{provider}/{enterpriseName}/metrics/{metricName}/period
# operationId: retrieveValueForPeriodForEnterprise
# --filter shape: {dimensionsFilter?: list}
export def "enterprises-metrics-period retrieveValueForPeriodForEnterprise" [
  provider: string
  enterpriseName: string
  metricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filter: record # shape: {dimensionsFilter?: list}
  date: string # format: date-time
  period: string@period-completer # e.g. week
]: any -> record<data: record<value: float, latestValue: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enterprises/($provider)/($enterpriseName)/metrics/($metricName)/period")
  let body = {filter: $filter, date: $date, period: $period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve metric values grouped by dimension for a specific period for all organizations in an enterprise
#
# POST /enterprises/{provider}/{enterpriseName}/metrics/{metricName}/period-grouped
# operationId: retrieveGroupedValuesForPeriodForEnterprise
# --filter shape: {dimensionsFilter?: list}
# --groupBy shape: {groupBy: list, sortDirection?: string, limit?: int}
export def "enterprises-metrics-period-grouped retrieveGroupedValuesForPeriodForEnterprise" [
  provider: string
  enterpriseName: string
  metricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filter: record # shape: {dimensionsFilter?: list}
  groupBy: record # shape: {groupBy: list, sortDirection?: string, limit?: int}
  date: string # format: date-time
  period: string@period-completer # e.g. week
]: any -> record<data: table<group: record, value: float, latestValue: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enterprises/($provider)/($enterpriseName)/metrics/($metricName)/period-grouped")
  let body = {filter: $filter, groupBy: $groupBy, date: $date, period: $period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve metric values for a time range for all organizations in an enterprise
#
# POST /enterprises/{provider}/{enterpriseName}/metrics/{metricName}/timerange
# operationId: retrieveTimerangeMetricValuesForEnterprise
# --filter shape: {dimensionsFilter?: list}
# --groupBy shape: {groupBy: list, sortDirection?: string, limit?: int}
export def "enterprises-metrics-timerange retrieveTimerangeMetricValuesForEnterprise" [
  provider: string
  enterpriseName: string
  metricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filter: record # shape: {dimensionsFilter?: list}
  groupBy: record # shape: {groupBy: list, sortDirection?: string, limit?: int}
  --body-from: string # format: date-time
  --body-to: string # format: date-time
  --period: string@period-completer # e.g. week
]: any -> record<data: table<date: string, group: record, value: float, latestValue: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enterprises/($provider)/($enterpriseName)/metrics/($metricName)/timerange")
  let body = {filter: $filter, groupBy: $groupBy, from: $body_from, to: $body_to, period: $period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List files in a repository
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/files
# operationId: listFiles
export def "organizations-repositories-files listFiles" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # Name of a [repository branch enabled on Codacy](https://docs.codacy.com/repositories-configure/managing-branches/), as returned by the endpoint [listRepositoryBranches](#listrepositorybranches). By default, uses the main branch defined on the Codacy repository settings.  (e.g. master)
  --search: string # Filter files that include this string anywhere in their relative path (e.g. file.js)
  --qp-sort: string # Field used to sort the list of files. Valid values are `filename`, `issues`, `grade`, `duplication`, `complexity`, and `coverage`. (e.g. category)
  --direction: string # Sort direction. Possible values are 'asc' (ascending) or 'desc' (descending). (e.g. desc)
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<data: table<fileId: int, branchId: int, path: string, totalIssues: int, complexity: int, grade: int, gradeLetter: string, coverage: int, coverageWithDecimals: float, duplication: int, linesOfCode: int, sourceLinesOfCode: int, numberOfMethods: int, numberOfClones: int>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List ignored files in a repository
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/ignored-files
# operationId: listIgnoredFiles
export def "organizations-repositories-ignored-files listIgnoredFiles" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # Name of a [repository branch enabled on Codacy](https://docs.codacy.com/repositories-configure/managing-branches/), as returned by the endpoint [listRepositoryBranches](#listrepositorybranches). By default, uses the main branch defined on the Codacy repository settings.  (e.g. master)
  --search: string # Filter files that include this string anywhere in their relative path (e.g. file.js)
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<hasCodacyConfigurationFile: bool, data: table<filepath: string>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/ignored-files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get analysis information and coverage metrics for a file in a repository
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/files/{fileId}
# operationId: getFileWithAnalysis
export def "organizations-repositories-files get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  fileId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<file: record<branchId: int, commitId: int, commitSha: string, fileId: int, fileDataId: int, path: string, language: string, gitProviderUrl: string, ignored: bool>, coverage: record<coverage: float, coverableLines: int, coveredLines: int>, quality: record<totalIssues: int, complexity: int, grade: int, gradeLetter: string, duplication: int, duplicatedLinesOfCode: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/files/($fileId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the list of duplicated code blocks for a file in a repository
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/files/{fileId}/duplication
# operationId: getFileClones
export def "organizations-repositories-files-duplication get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  fileId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<data: table<id: int, occurrences: list>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/files/($fileId)/duplication" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the issue list for a file in a repository
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/files/{fileId}/issues
# operationId: getFileIssues
export def "organizations-repositories-files-issues get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  fileId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<data: table<issueId: string, resultDataId: int, filePath: string, fileId: int, patternInfo: record, toolInfo: record, lineNumber: int, message: string, suggestion: string, language: string, lineText: string, commitInfo: record, falsePositiveProbability: int, falsePositiveReason: string, falsePositiveThreshold: int>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/files/($fileId)/issues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get AI Risk Checklist for an organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/ai-risk-checklist
# operationId: getAiRiskCheckList
export def "organizations-ai-risk-checklist get" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<key: string, check: bool, number: int, threshold: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/ai-risk-checklist")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the coding standards for an organization, including draft coding standards
#
# GET /organizations/{provider}/{remoteOrganizationName}/coding-standards
# operationId: listCodingStandards
export def "organizations-coding-standards listCodingStandards" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: int, name: string, isDraft: bool, isDefault: bool, languages: list, meta: record, complianceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/coding-standards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a draft coding standard for an organization
#
# POST /organizations/{provider}/{remoteOrganizationName}/coding-standards
# operationId: createCodingStandard
export def "organizations-coding-standards createCodingStandard" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sourceRepository: string # Name of a repository in the same organization to use as a template when creating the new coding standard
  --sourceCodingStandard: int # Identifier of an existing coding standard to use as a template when creating a new coding standard, including the enabled repositories and default coding standard status  (format: int64, e.g. 1)
  name: string # Name of the new coding standard (e.g. Security best practices)
  languages: list # List of programming languages supported by the new coding standard (e.g. [Java, Go])
]: any -> record<data: record<id: int, name: string, isDraft: bool, isDefault: bool, languages: list<string>, meta: record<enabledToolsCount: int, enabledPatternsCount: int, linkedRepositoriesCount: int>, complianceType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sourceRepository" $sourceRepository "scalar") (serialize-qp "sourceCodingStandard" $sourceCodingStandard "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/coding-standards" $qp)
  let body = {name: $name, languages: $languages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a compliance standard for an organization
#
# POST /organizations/{provider}/{remoteOrganizationName}/compliance-standards
# operationId: createComplianceStandard
export def "organizations-compliance-standards createComplianceStandard" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the compliance standard (e.g. AI Usage Compliance)
  complianceType: string@complianceType-completer # The type of compliance standard (e.g. ai-risk)
]: any -> record<data: record<id: int, name: string, isDraft: bool, isDefault: bool, languages: list<string>, meta: record<enabledToolsCount: int, enabledPatternsCount: int, linkedRepositoriesCount: int>, complianceType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/compliance-standards")
  let body = {name: $name, complianceType: $complianceType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a coding standard for an organization choosing from a series of presets.
#
# POST /organizations/{provider}/{remoteOrganizationName}/presets-standards
# operationId: createCodingStandardPreset
# --presets shape: {bugRisk: int, security: int, bestPractices: int, codeStyle: int, documentation: int}
export def "organizations-presets-standards createCodingStandardPreset" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the new coding standard (e.g. Security best practices)
  --isDefault: string@bool-completer # If true, the new coding standard becomes the default coding standard for the organization
  presets: record # Settings to create a new coding standard from a series of presets — shape: {bugRisk: int, security: int, bestPractices: int, codeStyle: int, documentation: int}
]: any -> record<data: record<id: int, name: string, isDraft: bool, isDefault: bool, languages: list<string>, meta: record<enabledToolsCount: int, enabledPatternsCount: int, linkedRepositoriesCount: int>, complianceType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/presets-standards")
  let body = {name: $name, isDefault: $isDefault, presets: $presets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a coding standard
#
# GET /organizations/{provider}/{remoteOrganizationName}/coding-standards/{codingStandardId}
# operationId: getCodingStandard
export def "organizations-coding-standards get" [
  provider: string
  remoteOrganizationName: string
  codingStandardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: int, name: string, isDraft: bool, isDefault: bool, languages: list<string>, meta: record<enabledToolsCount: int, enabledPatternsCount: int, linkedRepositoriesCount: int>, complianceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/coding-standards/($codingStandardId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a coding standard
#
# DELETE /organizations/{provider}/{remoteOrganizationName}/coding-standards/{codingStandardId}
# operationId: deleteCodingStandard
export def "organizations-coding-standards delete" [
  provider: string
  remoteOrganizationName: string
  codingStandardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/coding-standards/($codingStandardId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Duplicate a coding standard
#
# POST /organizations/{provider}/{remoteOrganizationName}/coding-standards/{codingStandardId}/duplicate
# operationId: duplicateCodingStandard
export def "organizations-coding-standards-duplicate duplicateCodingStandard" [
  provider: string
  remoteOrganizationName: string
  codingStandardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: int, name: string, isDraft: bool, isDefault: bool, languages: list<string>, meta: record<enabledToolsCount: int, enabledPatternsCount: int, linkedRepositoriesCount: int>, complianceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/coding-standards/($codingStandardId)/duplicate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List tools in a coding standard
#
# GET /organizations/{provider}/{remoteOrganizationName}/coding-standards/{codingStandardId}/tools
# operationId: listCodingStandardTools
export def "organizations-coding-standards-tools listCodingStandardTools" [
  provider: string
  remoteOrganizationName: string
  codingStandardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<codingStandardId: int, uuid: string, isEnabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/coding-standards/($codingStandardId)/tools")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the default coding standard for an organization
#
# POST /organizations/{provider}/{remoteOrganizationName}/coding-standards/{codingStandardId}/setDefault
# operationId: setDefaultCodingStandard
export def "organizations-coding-standards-set-default setDefaultCodingStandard" [
  provider: string
  remoteOrganizationName: string
  codingStandardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isDefault: string@bool-completer # If true, sets the coding standard as the default coding standard for the organization
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/coding-standards/($codingStandardId)/setDefault")
  let body = {isDefault: $isDefault} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the code patterns configured for a tool in a coding standard
#
# GET /organizations/{provider}/{remoteOrganizationName}/coding-standards/{codingStandardId}/tools/{toolUuid}/patterns
# operationId: listCodingStandardPatterns
export def "organizations-coding-standards-tools-patterns listCodingStandardPatterns" [
  provider: string
  remoteOrganizationName: string
  codingStandardId: int
  toolUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --languages: string # Comma-separated list of programming languages to filter results by (e.g. Scala,Java,Javascript)
  --categories: string # Filter by a comma-separated list of code pattern categories. Valid values are `Security`, `ErrorProne`, `CodeStyle`, `Compatibility`, `UnusedCode`, `Complexity`, `Comprehensibility`, `Documentation`, `BestPractice`, and `Performance`.  (e.g. Security,ErrorProne)
  --severityLevels: string # Filter by a comma-separated list of code pattern severity levels. Valid values are `Error`, `High`, `Warning`, and `Info`. (e.g. Error,Warning)
  --tags: string # Filter by a comma-separated list of pattern tags (e.g. React,Angular)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
  --enabled: string@bool-completer # Filter by pattern status. Set to `true` to return only enabled patterns, or `false` to return only disabled patterns
  --recommended: string@bool-completer # Filter by recommended status. Set to `true` to return only recommended patterns, or `false` to return only non-recommended patterns
  --qp-sort: string # Field used to sort the tool's code patterns. Valid values are `category`, `recommended`, and `severity`. (e.g. category)
  --direction: string # Sort direction. Possible values are 'asc' (ascending) or 'desc' (descending). (e.g. desc)
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<data: table<patternDefinition: record, enabled: bool, isCustom: bool, parameters: list, enabledBy: list>, pagination: record<cursor: string, limit: int, total: int>, meta: record<totalEnabled: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languages" $languages "scalar") (serialize-qp "categories" $categories "scalar") (serialize-qp "severityLevels" $severityLevels "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "enabled" $enabled "scalar") (serialize-qp "recommended" $recommended "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/coding-standards/($codingStandardId)/tools/($toolUuid)/patterns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get patterns overview for a coding standard tool
#
# GET /organizations/{provider}/{remoteOrganizationName}/coding-standards/{codingStandardId}/tools/{toolUuid}/patterns/overview
# operationId: codingStandardToolPatternsOverview
export def "organizations-coding-standards-tools-patterns-overview codingStandardToolPatternsOverview" [
  provider: string
  remoteOrganizationName: string
  codingStandardId: int
  toolUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --languages: string # Comma-separated list of programming languages to filter results by (e.g. Scala,Java,Javascript)
  --categories: string # Filter by a comma-separated list of code pattern categories. Valid values are `Security`, `ErrorProne`, `CodeStyle`, `Compatibility`, `UnusedCode`, `Complexity`, `Comprehensibility`, `Documentation`, `BestPractice`, and `Performance`.  (e.g. Security,ErrorProne)
  --severityLevels: string # Filter by a comma-separated list of code pattern severity levels. Valid values are `Error`, `High`, `Warning`, and `Info`. (e.g. Error,Warning)
  --tags: string # Filter by a comma-separated list of pattern tags (e.g. React,Angular)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
  --enabled: string@bool-completer # Filter by pattern status. Set to `true` to return only enabled patterns, or `false` to return only disabled patterns
  --recommended: string@bool-completer # Filter by recommended status. Set to `true` to return only recommended patterns, or `false` to return only non-recommended patterns
]: nothing -> record<data: record<counts: record<languages: list, categories: list, severities: list, tags: list, totalRecommended: int, totalEnabled: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languages" $languages "scalar") (serialize-qp "categories" $categories "scalar") (serialize-qp "severityLevels" $severityLevels "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "enabled" $enabled "scalar") (serialize-qp "recommended" $recommended "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/coding-standards/($codingStandardId)/tools/($toolUuid)/patterns/overview" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk update the code patterns of a tool in a coding standard
#
# POST /organizations/{provider}/{remoteOrganizationName}/coding-standards/{codingStandardId}/tools/{toolUuid}/patterns/update
# operationId: updateCodingStandardPatterns
export def "organizations-coding-standards-tools-patterns-update updateCodingStandardPatterns" [
  provider: string
  remoteOrganizationName: string
  codingStandardId: int
  toolUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --languages: string # Comma-separated list of programming languages to filter results by (e.g. Scala,Java,Javascript)
  --categories: string # Filter by a comma-separated list of code pattern categories. Valid values are `Security`, `ErrorProne`, `CodeStyle`, `Compatibility`, `UnusedCode`, `Complexity`, `Comprehensibility`, `Documentation`, `BestPractice`, and `Performance`.  (e.g. Security,ErrorProne)
  --severityLevels: string # Filter by a comma-separated list of code pattern severity levels. Valid values are `Error`, `High`, `Warning`, and `Info`. (e.g. Error,Warning)
  --tags: string # Filter by a comma-separated list of pattern tags (e.g. React,Angular)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
  --recommended: string@bool-completer # Filter by recommended status. Set to `true` to return only recommended patterns, or `false` to return only non-recommended patterns
  --enabled: string@bool-completer # True enables the code patterns, and False disables them.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languages" $languages "scalar") (serialize-qp "categories" $categories "scalar") (serialize-qp "severityLevels" $severityLevels "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "recommended" $recommended "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/coding-standards/($codingStandardId)/tools/($toolUuid)/patterns/update" $qp)
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Configure a tool in a draft coding standard
#
# PATCH /organizations/{provider}/{remoteOrganizationName}/coding-standards/{codingStandardId}/tools/{toolUuid}
# operationId: updateCodingStandardToolConfiguration
# --patterns item shape: {id: string, enabled?: bool, parameters?: list}
export def "organizations-coding-standards-tools updateCodingStandardToolConfiguration" [
  provider: string
  remoteOrganizationName: string
  codingStandardId: int
  toolUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # True if the tool is enabled in the repository or coding standard (e.g. true)
  patterns: list # List of code pattern configurations — item shape: {id: string, enabled?: bool, parameters?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/coding-standards/($codingStandardId)/tools/($toolUuid)")
  let body = {enabled: $enabled, patterns: $patterns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the repositories that are using a coding standard
#
# GET /organizations/{provider}/{remoteOrganizationName}/coding-standards/{codingStandardId}/repositories
# operationId: listCodingStandardRepositories
export def "organizations-coding-standards-repositories listCodingStandardRepositories" [
  provider: string
  remoteOrganizationName: string
  codingStandardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<data: table<repositoryId: int, name: string>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/coding-standards/($codingStandardId)/repositories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply a coding standard to a list of repositories
#
# PATCH /organizations/{provider}/{remoteOrganizationName}/coding-standards/{codingStandardId}/repositories
# operationId: applyCodingStandardToRepositories
export def "organizations-coding-standards-repositories applyCodingStandardToRepositories" [
  provider: string
  remoteOrganizationName: string
  codingStandardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  link: list # Names of the repositories to link to a coding standard
  unlink: list # Names of the repositories to unlink from a coding standard
]: any -> record<data: record<successful: list<string>, failed: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/coding-standards/($codingStandardId)/repositories")
  let body = {link: $link, unlink: $unlink} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set the gate policy as the default for an organization
#
# POST /organizations/{provider}/{remoteOrganizationName}/gate-policies/{gatePolicyId}/setDefault
# operationId: setDefaultGatePolicy
export def "organizations-gate-policies-set-default setDefaultGatePolicy" [
  provider: string
  remoteOrganizationName: string
  gatePolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/gate-policies/($gatePolicyId)/setDefault")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the built-in Codacy gate policy as the default for an organization
#
# POST /organizations/{provider}/{remoteOrganizationName}/gate-policies/setCodacyDefault
# operationId: setCodacyDefault
export def "organizations-gate-policies-set-codacy-default setCodacyDefault" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/gate-policies/setCodacyDefault")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a gate policy
#
# GET /organizations/{provider}/{remoteOrganizationName}/gate-policies/{gatePolicyId}
# operationId: getGatePolicy
export def "organizations-gate-policies get" [
  provider: string
  remoteOrganizationName: string
  gatePolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: int, name: string, isDefault: bool, readOnly: bool, settings: record<issueThreshold: record, securityIssueThreshold: int, securityIssueMinimumSeverity: string, duplicationThreshold: int, coverageThreshold: int, coverageThresholdWithDecimals: float, diffCoverageThreshold: int, complexityThreshold: int>, meta: record<nrOfQualityGates: int, linkedRepositoriesCount: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/gate-policies/($gatePolicyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a gate policy
#
# DELETE /organizations/{provider}/{remoteOrganizationName}/gate-policies/{gatePolicyId}
# operationId: deleteGatePolicy
export def "organizations-gate-policies delete" [
  provider: string
  remoteOrganizationName: string
  gatePolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/gate-policies/($gatePolicyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a gate policy
#
# PATCH /organizations/{provider}/{remoteOrganizationName}/gate-policies/{gatePolicyId}
# operationId: updateGatePolicy
# --settings shape: {issueThreshold?: record, securityIssueThreshold?: int, securityIssueMinimumSeverity?: "Info"|"Warning"|"High"|"Error", duplicationThreshold?: int, coverageThreshold?: int, coverageThresholdWithDecimals?: float, diffCoverageThreshold?: int, complexityThreshold?: int}
export def "organizations-gate-policies updateGatePolicy" [
  provider: string
  remoteOrganizationName: string
  gatePolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --gatePolicyName: string # Name of the gate policy
  --isDefault: string@bool-completer # True if the gate policy is the default for the organization
  --settings: record # shape: {issueThreshold?: record, securityIssueThreshold?: int, securityIssueMinimumSeverity?: "Info"|"Warning"|"High"|"Error", duplicationThreshold?: int, coverageThreshold?: int, coverageThresholdWithDecimals?: float, diffCoverageThreshold?: int, complexityThreshold?: int}
]: any -> record<data: record<id: int, name: string, isDefault: bool, readOnly: bool, settings: record<issueThreshold: record, securityIssueThreshold: int, securityIssueMinimumSeverity: string, duplicationThreshold: int, coverageThreshold: int, coverageThresholdWithDecimals: float, diffCoverageThreshold: int, complexityThreshold: int>, meta: record<nrOfQualityGates: int, linkedRepositoriesCount: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/gate-policies/($gatePolicyId)")
  let body = {gatePolicyName: $gatePolicyName, isDefault: $isDefault, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the gate policies for an organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/gate-policies
# operationId: listGatePolicies
export def "organizations-gate-policies listGatePolicies" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<data: table<id: int, name: string, isDefault: bool, readOnly: bool, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/gate-policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a gate policy
#
# POST /organizations/{provider}/{remoteOrganizationName}/gate-policies
# operationId: createGatePolicy
# --settings shape: {issueThreshold?: record, securityIssueThreshold?: int, securityIssueMinimumSeverity?: "Info"|"Warning"|"High"|"Error", duplicationThreshold?: int, coverageThreshold?: int, coverageThresholdWithDecimals?: float, diffCoverageThreshold?: int, complexityThreshold?: int}
export def "organizations-gate-policies createGatePolicy" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  gatePolicyName: string # Name of the gate policy (e.g. gate-policy-name)
  --isDefault: string@bool-completer # e.g. true
  --settings: record # shape: {issueThreshold?: record, securityIssueThreshold?: int, securityIssueMinimumSeverity?: "Info"|"Warning"|"High"|"Error", duplicationThreshold?: int, coverageThreshold?: int, coverageThresholdWithDecimals?: float, diffCoverageThreshold?: int, complexityThreshold?: int}
]: any -> record<data: record<id: int, name: string, isDefault: bool, readOnly: bool, settings: record<issueThreshold: record, securityIssueThreshold: int, securityIssueMinimumSeverity: string, duplicationThreshold: int, coverageThreshold: int, coverageThresholdWithDecimals: float, diffCoverageThreshold: int, complexityThreshold: int>, meta: record<nrOfQualityGates: int, linkedRepositoriesCount: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/gate-policies")
  let body = {gatePolicyName: $gatePolicyName, isDefault: $isDefault, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Synchronize Codacy organization name with the Git provider
#
# POST /organizations/{provider}/{remoteOrganizationName}/settings/sync
# operationId: syncOrganizationName
export def "organizations-settings-sync syncOrganizationName" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/settings/sync")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if the submodules option is enabled for the organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/settings/submodules/check
# operationId: checkSubmodules
export def "organizations-settings-submodules-check checkSubmodules" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/settings/submodules/check")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all repositories following a gate policy
#
# GET /organizations/{provider}/{remoteOrganizationName}/gate-policies/{gatePolicyId}/repositories
# operationId: listRepositoriesFollowingGatePolicy
export def "organizations-gate-policies-repositories listRepositoriesFollowingGatePolicy" [
  provider: string
  remoteOrganizationName: string
  gatePolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<data: table<repositoryId: int, name: string>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/gate-policies/($gatePolicyId)/repositories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply a gate policy to a list of repositories
#
# PUT /organizations/{provider}/{remoteOrganizationName}/gate-policies/{gatePolicyId}/repositories
# operationId: applyGatePolicyToRepositories
export def "organizations-gate-policies-repositories applyGatePolicyToRepositories" [
  provider: string
  remoteOrganizationName: string
  gatePolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  link: list # Names of the repositories to link to a gate policy
  unlink: list # Names of the repositories to unlink from a gate policy
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/gate-policies/($gatePolicyId)/repositories")
  let body = {link: $link, unlink: $unlink} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Promote a draft coding standard to an effective coding standard
#
# POST /organizations/{provider}/{remoteOrganizationName}/coding-standards/{codingStandardId}/promote
# operationId: promoteDraftCodingStandard
export def "organizations-coding-standards-promote promoteDraftCodingStandard" [
  provider: string
  remoteOrganizationName: string
  codingStandardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<successful: list<string>, failed: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/coding-standards/($codingStandardId)/promote")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the [repository API tokens](https://docs.codacy.com/codacy-api/api-tokens/)
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/tokens
# operationId: listRepositoryApiTokens
export def "organizations-repositories-tokens listRepositoryApiTokens" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<id: int, token: string, expiresAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new [repository API token](https://docs.codacy.com/codacy-api/api-tokens/)
#
# POST /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/tokens
# operationId: createRepositoryApiToken
export def "organizations-repositories-tokens createRepositoryApiToken" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: int, token: string, expiresAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a [repository API token](https://docs.codacy.com/codacy-api/api-tokens/) by ID
#
# DELETE /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/tokens/{tokenId}
# operationId: deleteRepositoryApiToken
export def "organizations-repositories-tokens delete" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  tokenId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/tokens/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the most recent coverage reports and their status
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/coverage/status
# operationId: listCoverageReports
export def "organizations-repositories-coverage-status listCoverageReports" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<data: record<hasCoverageOverview: bool, lastReports: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/coverage/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List coverage reports for a commit
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/commits/{commitUuid}/coverage/reports
# operationId: listCommitCoverageReports
export def "organizations-repositories-commits-coverage-reports listCommitCoverageReports" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  commitUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<data: table<repositoryId: int, commitSha: string, reportId: string, language: string, isFinal: bool, processed: bool, createdAt: string>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/commits/($commitUuid)/coverage/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a coverage report with its contents
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/commits/{commitUuid}/coverage/reports/{reportUuid}
# operationId: getCoverageReport
export def "organizations-repositories-commits-coverage-reports get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  commitUuid: string
  reportUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<repositoryId: int, commitSha: string, reportId: string, language: string, isFinal: bool, processed: bool, createdAt: string, content: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/commits/($commitUuid)/coverage/reports/($reportUuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the content of the given file for a given commit reference. If the requested file is over 1MB, a 'PayloadTooLarge' error is returned.
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/files/{filePath}/content
# operationId: getFileContent
export def "organizations-repositories-files-content get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  filePath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startLine: int # Line number where the code block starts (format: int32, e.g. 1)
  --endLine: int # Line number where the code block ends (format: int32, e.g. 10)
  --commitRef: string # A reference to a commit (branch name, tag, or commit hash). Defaults to HEAD which represents the head of the default branch. (default: HEAD, e.g. main)
]: nothing -> record<data: table<number: int, content: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startLine" $startLine "scalar") (serialize-qp "endLine" $endLine "scalar") (serialize-qp "commitRef" $commitRef "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/files/($filePath)/content" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get coverage information for a file in the head commit of a repository branch.
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/files/{fileId}/coverage
# operationId: getFileCoverage
export def "organizations-repositories-files-coverage get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  fileId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<line: int, hits: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/files/($fileId)/coverage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ignore or unignore a file
#
# PATCH /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/file
# operationId: updateFileState
export def "organizations-repositories-file updateFileState" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ignored: string@bool-completer # True if the file is ignored (e.g. true)
  filepath: string # Relative path of the file in the repository (e.g. src/main/scala/main/Main.scala)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/file")
  let body = {ignored: $ignored, filepath: $filepath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List security and risk management items for an organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/security/items
# DEPRECATED
# operationId: listSecurityItems
@deprecated
@deprecated --flag repositories
export def "organizations-security-items listSecurityItems" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --repositories: string # **Deprecated:** Use [searchOrganizationRepositoriesWithAnalysis](#searchorganizationrepositorieswithanalysis) instead. (DEPRECATED, e.g. codacy-eslint,codacy-pmd)
  --status: list # Security issue status to filter by. See [SrmStatus](#tocssrmstatus) for valid values. (e.g. status=Overdue&status=OnTrack)
  --priority: list # Security issue priorities to filter by. See [SrmPriority](#tocssrmpriority) for valid values. (e.g. priority=Critical&priority=High)
  --category: list # Security categories to filter by. Use `_other_` to search for issues that don't have a security category. (e.g. category=Cryptography&category=OutdatedDependencies)
  --scanType: list # Security scan type to filter by (e.g. scanType=DAST&scanType=CICD)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<id: string, itemSource: string, itemSourceId: string, title: string, repository: string, openedAt: string, closedAt: string, dueAt: string, ignored: record, priority: string, status: string, htmlUrl: string, projectKey: string, securityCategory: string, scanType: string, summary: string, cvssScore: float, cvssVector: string, cwe: string, cve: string, affectedVersion: string, fixedVersion: list, application: string, affectedTargets: string, additionalInfo: string, likelihood: string, effortToFix: string, remediation: string, dastTargetUrls: string, imageName: string, imageTag: string, dependencyChains: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "repositories" $repositories "scalar") (serialize-qp "status" $status "multi") (serialize-qp "priority" $priority "multi") (serialize-qp "category" $category "multi") (serialize-qp "scanType" $scanType "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/security/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ignore a single item with an optional comment
#
# POST /organizations/{provider}/{remoteOrganizationName}/security/items/{srmItemId}/ignore
# operationId: ignoreSecurityItem
export def "organizations-security-items-ignore ignoreSecurityItem" [
  provider: string
  remoteOrganizationName: string
  srmItemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reason: string # The reason why we ignore an issue. Must be one of `AcceptedUse`, `FalsePositive`, `NotExploitable`, `TestCode`, `ExternalCode`
  --comment: string # Comment describing why we ignore an issue
]: any -> record<data: record<id: string, itemSource: string, itemSourceId: string, title: string, repository: string, openedAt: string, closedAt: string, dueAt: string, ignored: record<at: string, authorId: int, authorName: string, reason: string>, priority: string, status: string, htmlUrl: string, projectKey: string, securityCategory: string, scanType: string, summary: string, cvssScore: float, cvssVector: string, cwe: string, cve: string, affectedVersion: string, fixedVersion: list<string>, application: string, affectedTargets: string, additionalInfo: string, likelihood: string, effortToFix: string, remediation: string, dastTargetUrls: string, imageName: string, imageTag: string, dependencyChains: list<list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/security/items/($srmItemId)/ignore")
  let body = {reason: $reason, comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unignore a single item (only previously ignored items can be unignored)
#
# POST /organizations/{provider}/{remoteOrganizationName}/security/items/{srmItemId}/unignore
# operationId: unignoreSecurityItem
export def "organizations-security-items-unignore unignoreSecurityItem" [
  provider: string
  remoteOrganizationName: string
  srmItemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: string, itemSource: string, itemSourceId: string, title: string, repository: string, openedAt: string, closedAt: string, dueAt: string, ignored: record<at: string, authorId: int, authorName: string, reason: string>, priority: string, status: string, htmlUrl: string, projectKey: string, securityCategory: string, scanType: string, summary: string, cvssScore: float, cvssVector: string, cwe: string, cve: string, affectedVersion: string, fixedVersion: list<string>, application: string, affectedTargets: string, additionalInfo: string, likelihood: string, effortToFix: string, remediation: string, dastTargetUrls: string, imageName: string, imageTag: string, dependencyChains: list<list>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/security/items/($srmItemId)/unignore")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single security and risk management finding
#
# GET /organizations/{provider}/{remoteOrganizationName}/security/items/{srmItemId}
# operationId: getSecurityItem
export def "organizations-security-items get" [
  provider: string
  remoteOrganizationName: string
  srmItemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: string, itemSource: string, itemSourceId: string, title: string, repository: string, openedAt: string, closedAt: string, dueAt: string, ignored: record<at: string, authorId: int, authorName: string, reason: string>, priority: string, status: string, htmlUrl: string, projectKey: string, securityCategory: string, scanType: string, summary: string, cvssScore: float, cvssVector: string, cwe: string, cve: string, affectedVersion: string, fixedVersion: list<string>, application: string, affectedTargets: string, additionalInfo: string, likelihood: string, effortToFix: string, remediation: string, dastTargetUrls: string, imageName: string, imageTag: string, dependencyChains: list<list>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/security/items/($srmItemId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List security and risk management items for an organization
#
# POST /organizations/{provider}/{remoteOrganizationName}/security/items/search
# operationId: searchSecurityItems
# --containerImage shape: {name: string, tag?: string}
export def "organizations-security-items-search searchSecurityItems" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --qp-sort: string@sort-completer # Field to sort SRM items by (e.g. Status)
  --direction: string # Sort direction. Possible values are 'asc' (ascending) or 'desc' (descending). (e.g. desc)
  --repositories: list # Repository names to filter by.
  --priorities: list # Security issue priorities to filter by. See [SrmPriority](#tocssrmpriority) for valid values.
  --statuses: list # Security issue status to filter by. See [SrmStatus](#tocssrmstatus) for valid values.
  --categories: list # Security categories to filter by. Use `_other_` to search for issues that don't have a security category.
  --scanTypes: list # Scan types to filter by. (e.g. [SAST, SCA, ContainerSCA, Secrets, IaC, CICD, License, PenTesting, DAST, CSPM])
  --segments: list # Segments ids to filter by. (e.g. [1, 2, 3])
  --dastTargetUrls: list # Filter containing a list of Dast target urls.
  --searchText: string # Text to search for in security items.
  --containerImage: record # Filter for container scanning items. The image `name` is required; `tag` is optional. Filtering by tag alone (without name) is not allowed. — shape: {name: string, tag?: string}
]: any -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<id: string, itemSource: string, itemSourceId: string, title: string, repository: string, openedAt: string, closedAt: string, dueAt: string, ignored: record, priority: string, status: string, htmlUrl: string, projectKey: string, securityCategory: string, scanType: string, summary: string, cvssScore: float, cvssVector: string, cwe: string, cve: string, affectedVersion: string, fixedVersion: list, application: string, affectedTargets: string, additionalInfo: string, likelihood: string, effortToFix: string, remediation: string, dastTargetUrls: string, imageName: string, imageTag: string, dependencyChains: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/security/items/search" $qp)
  let body = {repositories: $repositories, priorities: $priorities, statuses: $statuses, categories: $categories, scanTypes: $scanTypes, segments: $segments, dastTargetUrls: $dastTargetUrls, searchText: $searchText, containerImage: $containerImage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get metrics for the security and risk management dashboard
#
# GET /organizations/{provider}/{remoteOrganizationName}/security/dashboard
# DEPRECATED
# operationId: getSecurityDashboard
@deprecated
@deprecated --flag repositories
export def "organizations-security-dashboard get" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --repositories: string # **Deprecated:** Use [searchOrganizationRepositoriesWithAnalysis](#searchorganizationrepositorieswithanalysis) instead. (DEPRECATED, e.g. codacy-eslint,codacy-pmd)
  --priority: list # Security issue priorities to filter by. See [SrmPriority](#tocssrmpriority) for valid values. (e.g. priority=Critical&priority=High)
  --category: list # Security categories to filter by. Use `_other_` to search for issues that don't have a security category. (e.g. category=Cryptography&category=OutdatedDependencies)
  --scanType: list # Security scan type to filter by (e.g. scanType=DAST&scanType=CICD)
]: nothing -> record<data: record<totalOpen: int, totalNewThisWeek: int, totalClosed: int, onTrack: int, dueSoon: int, overdue: int, closedOnTime: int, closedLate: int, openCritical: int, openHigh: int, openMedium: int, openLow: int, openSAST: int, openSCA: int, openContainerSCA: int, openSecrets: int, openIaC: int, openCICD: int, openLicense: int, openPenTesting: int, openDAST: int, openCSPM: int, openScanNotAttributed: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "repositories" $repositories "scalar") (serialize-qp "priority" $priority "multi") (serialize-qp "category" $category "multi") (serialize-qp "scanType" $scanType "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/security/dashboard" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metrics for the security and risk management dashboard
#
# POST /organizations/{provider}/{remoteOrganizationName}/security/dashboard
# operationId: searchSecurityDashboard
export def "organizations-security-dashboard searchSecurityDashboard" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --repositories: list # Repository names to filter by.
  --priorities: list # Security issue priorities to filter by. See [SrmPriority](#tocssrmpriority) for valid values.
  --categories: list # Security categories to filter by. Use `_other_` to search for issues that don't have a security category.
  --scanTypes: list # Scan types to filter by. (e.g. [SAST, SCA, ContainerSCA, Secrets, IaC, CICD, License, PenTesting, DAST, CSPM])
  --segments: list # Segments ids to filter by. (e.g. [1, 2, 3])
]: any -> record<data: record<totalOpen: int, totalNewThisWeek: int, totalClosed: int, onTrack: int, dueSoon: int, overdue: int, closedOnTime: int, closedLate: int, openCritical: int, openHigh: int, openMedium: int, openLow: int, openSAST: int, openSCA: int, openContainerSCA: int, openSecrets: int, openIaC: int, openCICD: int, openLicense: int, openPenTesting: int, openDAST: int, openCSPM: int, openScanNotAttributed: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/security/dashboard")
  let body = {repositories: $repositories, priorities: $priorities, categories: $categories, scanTypes: $scanTypes, segments: $segments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List repositories with security findings
#
# POST /organizations/{provider}/{remoteOrganizationName}/security/dashboard/repositories/search
# operationId: searchSecurityDashboardRepositories
export def "organizations-security-dashboard-repositories-search searchSecurityDashboardRepositories" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --repositories: list # Repository names to filter by.
  --segments: list # Segments ids to filter by. (e.g. [1, 2, 3])
]: any -> record<data: table<id: int, name: string, critical: int, high: int, medium: int, low: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/security/dashboard/repositories/search")
  let body = {repositories: $repositories, segments: $segments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the evolution of security findings over time
#
# POST /organizations/{provider}/{remoteOrganizationName}/security/dashboard/history/search
# operationId: searchSecurityDashboardHistory
export def "organizations-security-dashboard-history-search searchSecurityDashboardHistory" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --repositories: list # Repository names to filter by.
  --segments: list # Segments ids to filter by. (e.g. [1, 2, 3])
]: any -> record<data: table<since: string, until: string, newCritical: int, newHigh: int, newMedium: int, newLow: int, fixedCritical: int, fixedHigh: int, fixedMedium: int, fixedLow: int, openCritical: int, openHigh: int, openMedium: int, openLow: int, ignoredCritical: int, ignoredHigh: int, ignoredMedium: int, ignoredLow: int, unignoredCritical: int, unignoredHigh: int, unignoredMedium: int, unignoredLow: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/security/dashboard/history/search")
  let body = {repositories: $repositories, segments: $segments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List security categories with findings
#
# POST /organizations/{provider}/{remoteOrganizationName}/security/dashboard/categories/search
# operationId: searchSecurityDashboardCategories
export def "organizations-security-dashboard-categories-search searchSecurityDashboardCategories" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --repositories: list # Repository names to filter by.
  --segments: list # Segments ids to filter by. (e.g. [1, 2, 3])
]: any -> record<data: table<name: string, total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/security/dashboard/categories/search")
  let body = {repositories: $repositories, segments: $segments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload dynamic application security testing (DAST) scan report generated by the specified tool in the specified format. For ZAP reports (see https://www.zaproxy.org/docs/desktop/addons/report-generation/report-traditional-json), please guarantee that `@generated` timestamps are in an English locale, using the format `EEE, d MMM yyyy HH:mm:ss`  (which is ZAP's default), otherwise the report won't be processed.
#
# POST /organizations/{provider}/{remoteOrganizationName}/security/tools/dast/{toolName}/reports
# operationId: uploadDASTReport
export def "organizations-security-tools-dast-reports uploadDASTReport" [
  provider: string
  remoteOrganizationName: string
  toolName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string # The file containing DAST results (format: binary)
  reportFormat: string@reportFormat-completer # The format the report is provided in
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/security/tools/dast/($toolName)/reports")
  let body = {file: $file, reportFormat: $reportFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List uploaded DAST scan reports and their state
#
# GET /organizations/{provider}/{remoteOrganizationName}/security/dast/reports
# operationId: listDastReports
export def "organizations-security-dast-reports listDastReports" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<data: table<id: string, organizationId: int, createdAt: string, updatedAt: string, generatedAt: string, state: string, tool: string, failureReason: string>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/security/dast/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organization admins and security managers
#
# GET /organizations/{provider}/{remoteOrganizationName}/security/managers
# operationId: listSecurityManagers
export def "organizations-security-managers listSecurityManagers" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<userId: int, name: string, email: string, createdAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/security/managers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign the Security Manager role to an organization member
#
# POST /organizations/{provider}/{remoteOrganizationName}/security/managers
# operationId: postSecurityManager
export def "organizations-security-managers post" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  userId: int # User ID of the organization member to be promoted to security manager. (format: int64, e.g. 867842577)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/security/managers")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke the Security Manager role from an organization member
#
# DELETE /organizations/{provider}/{remoteOrganizationName}/security/managers/{userId}
# operationId: deleteSecurityManager
export def "organizations-security-managers delete" [
  provider: string
  remoteOrganizationName: string
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/security/managers/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organization repositories that have security issues
#
# GET /organizations/{provider}/{remoteOrganizationName}/security/repositories
# operationId: listSecurityRepositories
export def "organizations-security-repositories listSecurityRepositories" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --segments: string # Filter by a comma-separated list of segment identifiers (e.g. 1,2,3)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<repositoryId: int, provider: string, owner: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "segments" $segments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/security/repositories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List security subcategories that have security issues
#
# GET /organizations/{provider}/{remoteOrganizationName}/security/categories
# operationId: listSecurityCategories
export def "organizations-security-categories listSecurityCategories" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/security/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a list of SBOM dependencies, used across the organization.
#
# POST /organizations/{provider}/{remoteOrganizationName}/sbom/dependencies/search
# operationId: searchSbomDependencies
export def "organizations-sbom-dependencies-search searchSbomDependencies" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --sortColumn: string@sortColumn-completer-1 # Field used to sort the results. The possible values are `severity` (default, to sort by the item's severity), or `order` (to sort by the OSSF order). (default: severity)
  --columnOrder: string@columnOrder-completer # Sort direction. The possible values are `asc` (ascending) or `desc` (descending - default). (default: desc)
  --text: string # Text search query. Matches against SBOM component fields (purl, full_name).
  --repositories: list # Repository names to filter by.
  --segments: list # Segments ids to filter by. (e.g. [1, 2, 3])
  --findingSeverities: list # Finding severities to filter by. Possible values are `Critical`, `High`, `Medium`, `Low`.
  --riskCategories: list # License Risk categories to filter by.
]: any -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<fullName: string, purl: string, ossfScore: float, repositoriesCount: int, versionsCount: int, findings: list, licensesDetails: list>, overview: record<totalRepositoriesCount: int, filteredRepositoriesCount: int, totalDependenciesCount: int, filteredDependenciesCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sortColumn" $sortColumn "scalar") (serialize-qp "columnOrder" $columnOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/sbom/dependencies/search" $qp)
  let body = {text: $text, repositories: $repositories, segments: $segments, findingSeverities: $findingSeverities, riskCategories: $riskCategories} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a paginated list of repositories where a version of the specified SBOM dependency is used.
#
# POST /organizations/{provider}/{remoteOrganizationName}/sbom/dependencies/repositories/search
# operationId: searchRepositoriesOfSbomDependency
export def "organizations-sbom-dependencies-repositories-search searchRepositoriesOfSbomDependency" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  dependencyFullName: string # The full name of the dependency to search for.
  --repositoriesFilter: list # Repository names to filter by.
]: any -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<id: int, name: string, dependencyVersion: string, highestFindingSeverity: string, licenses: list, licensesDetails: list>, overview: record<name: string, fullName: string, purl: string, ossfScore: float, latestVersion: string, oldestVersion: string, totalVersionsCount: int, filteredVersionsCount: int, totalRepositoriesCount: int, filteredRepositoriesCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/sbom/dependencies/repositories/search" $qp)
  let body = {dependencyFullName: $dependencyFullName, repositoriesFilter: $repositoriesFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List repositories with SBOM dependency information
#
# POST /organizations/{provider}/{remoteOrganizationName}/sbom/repositories/search
# operationId: searchSbomRepositories
export def "organizations-sbom-repositories-search searchSbomRepositories" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --body: record
]: any -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<id: int, name: string, dependenciesCount: int, dependenciesFindings: list>, overview: record<totalRepositoriesCount: int, filteredRepositoriesCount: int, totalDependenciesCount: int, filteredDependenciesCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/sbom/repositories/search" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a presigned URL for the latest SBOM of the repository
#
# GET /organizations/{provider}/{remoteOrganizationName}/projects/{repositoryName}/sbom
# operationId: getRepositorySbomPresignedUrl
export def "organizations-projects-sbom get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/projects/($repositoryName)/sbom")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload an SBOM for a Docker image
#
# POST /organizations/{provider}/{remoteOrganizationName}/image-sboms
# operationId: uploadImageSbom
export def "organizations-image-sboms uploadImageSbom" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sbom: string # SBOM file (SPDX or CycloneDX format) (format: binary)
  imageName: string # Name of the Docker image
  tag: string # Tag of the Docker image
  --repositoryName: string # Repository name
  --environment: string # Environment where the image is deployed
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/image-sboms")
  let body = {sbom: $sbom, imageName: $imageName, tag: $tag, repositoryName: $repositoryName, environment: $environment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete all SBOMs for a given image
#
# DELETE /organizations/{provider}/{remoteOrganizationName}/image-sboms/{imageName}
# operationId: deleteImageSboms
export def "organizations-image-sboms delete" [
  provider: string
  remoteOrganizationName: string
  imageName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/image-sboms/($imageName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete SBOM for a given image/tag combination
#
# DELETE /organizations/{provider}/{remoteOrganizationName}/image-sboms/{imageName}/tags/{tag}
# operationId: deleteImageTag
export def "organizations-image-sboms-tags delete" [
  provider: string
  remoteOrganizationName: string
  imageName: string
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/image-sboms/($imageName)/tags/($tag)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Docker images for an organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/images
# operationId: listOrganizationImages
export def "organizations-images listOrganizationImages" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<imageName: string, latestTag: string, lastSbomUploaded: string, lastSbomGenerated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/images" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Docker image tags for an organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/images/{imageName}/tags
# operationId: listImageTags
export def "organizations-images-tags listImageTags" [
  provider: string
  remoteOrganizationName: string
  imageName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<imageName: string, tag: string, environment: string, repositoryId: int, repositoryName: string, generatedAt: string, uploadedAt: string, scanStatus: string, lastAnalysedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/images/($imageName)/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Jira ticket
#
# POST /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/integrations/jira/tickets
# DEPRECATED
# operationId: createJiraTicketDeprecated
@deprecated
export def "organizations-repositories-integrations-jira-tickets createJiraTicketDeprecated" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  elementType: string@elementType-completer
  elementIds: list
  jiraProjectId: int # format: int64
  issueTypeId: int # format: int64
  summary: string
  description: string # JIRA description written in Atlassian Document Format https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/#json-schema
  --dueDate: string # Optional due date in YYYY-MM-DD format (format: date)
]: any -> record<data: record<id: string, key: string, summary: string, assignee: string, link: string, status: record<key: string, labels: list, color: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/integrations/jira/tickets")
  let body = {elementType: $elementType, elementIds: $elementIds, jiraProjectId: $jiraProjectId, issueTypeId: $issueTypeId, summary: $summary, description: $description, dueDate: $dueDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Jira tickets for a Codacy element
#
# GET /organizations/{provider}/{remoteOrganizationName}/integrations/jira/tickets
# operationId: getJiraTickets
export def "organizations-integrations-jira-tickets get" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --elementType: string@elementType-completer # Type of Codacy element to filter by (e.g. issue)
  --elementId: string # Unique identifier of the Codacy element (e.g. 12345678)
]: nothing -> record<data: table<id: string, key: string, summary: string, assignee: string, link: string, status: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "elementType" $elementType "scalar") (serialize-qp "elementId" $elementId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/integrations/jira/tickets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Jira ticket
#
# POST /organizations/{provider}/{remoteOrganizationName}/integrations/jira/tickets
# operationId: createJiraTicket
# --createJiraTicketElements item shape: {elementId: string, repositoryName?: string}
export def "organizations-integrations-jira-tickets createJiraTicket" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  elementType: string@elementType-completer
  jiraProjectId: int # format: int64
  createJiraTicketElements: list # item shape: {elementId: string, repositoryName?: string}
  issueTypeId: int # format: int64
  summary: string
  description: string # JIRA description written in Atlassian Document Format https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/#json-schema
  --dueDate: string # Optional due date in YYYY-MM-DD format (format: date)
]: any -> record<data: record<id: string, key: string, summary: string, assignee: string, link: string, status: record<key: string, labels: list, color: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/integrations/jira/tickets")
  let body = {elementType: $elementType, jiraProjectId: $jiraProjectId, createJiraTicketElements: $createJiraTicketElements, issueTypeId: $issueTypeId, summary: $summary, description: $description, dueDate: $dueDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unlink a Jira ticket from a repository
#
# DELETE /organizations/{provider}/{remoteOrganizationName}/integrations/jira/tickets/{jiraTicketIdentifier}
# operationId: unlinkRepositoryJiraTicket
export def "organizations-integrations-jira-tickets unlinkRepositoryJiraTicket" [
  provider: string
  remoteOrganizationName: string
  jiraTicketIdentifier: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  elementType: string@elementType-completer
  elementId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/integrations/jira/tickets/($jiraTicketIdentifier)")
  let body = {elementType: $elementType, elementId: $elementId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the Jira integration of the organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/integrations/jira
# operationId: getJiraIntegration
export def "organizations-integrations-jira get" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<organization_id: int, instance_id: string, instance_name: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/integrations/jira")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update the Jira integration of the organization
#
# PUT /organizations/{provider}/{remoteOrganizationName}/integrations/jira
# operationId: createOrUpdateJiraIntegration
export def "organizations-integrations-jira createOrUpdateJiraIntegration" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --oauthCode: string # The OAuth code to allow authentication as the user installing the Jira App. (e.g. 6nGtF5eij1YuEqQXr7L9OxA0RLHZ21tEQNZq1DZJzuY)
]: nothing -> record<data: record<organization_id: int, instance_id: string, instance_name: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "oauthCode" $oauthCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/integrations/jira" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the Jira integration of the organization and associated resources
#
# DELETE /organizations/{provider}/{remoteOrganizationName}/integrations/jira
# operationId: deleteJiraIntegration
export def "organizations-integrations-jira delete" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/integrations/jira")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get available Jira projects for the organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/integrations/jira/projects
# operationId: getAvailableJiraProjects
export def "organizations-integrations-jira-projects get" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<data: table<id: int, key: string, name: string, avatarUrl: string>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/integrations/jira/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get available issue types for a Jira project
#
# GET /organizations/{provider}/{remoteOrganizationName}/integrations/jira/projects/{jiraProjectId}/issueTypes
# operationId: getJiraProjectIssueTypes
export def "organizations-integrations-jira-projects-issue-types get" [
  provider: string
  remoteOrganizationName: string
  jiraProjectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<data: table<id: int, name: string, isSubtask: bool, iconUrl: string>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/integrations/jira/projects/($jiraProjectId)/issueTypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get available fields by issue type for a Jira project
#
# GET /organizations/{provider}/{remoteOrganizationName}/integrations/jira/projects/{jiraProjectId}/issueTypes/{jiraIssueTypeId}/fields
# operationId: getJiraProjectIssueFields
export def "organizations-integrations-jira-projects-issue-types-fields get" [
  provider: string
  remoteOrganizationName: string
  jiraProjectId: int
  jiraIssueTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<data: table<fieldId: string, name: string, key: string, required: bool, hasDefaultValue: bool>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/integrations/jira/projects/($jiraProjectId)/issueTypes/($jiraIssueTypeId)/fields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the Slack integration of the organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/integrations/slack
# operationId: getSlackIntegration
export def "organizations-integrations-slack get" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<organization_id: int, webhook_url: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/integrations/slack")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update the Slack integration of the organization
#
# PUT /organizations/{provider}/{remoteOrganizationName}/integrations/slack
# operationId: createOrUpdateSlackIntegration
export def "organizations-integrations-slack createOrUpdateSlackIntegration" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  webhook_url: string # Slack Incoming Webhook URL to post notifications to. (e.g. https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX)
]: any -> record<data: record<organization_id: int, webhook_url: string, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/integrations/slack")
  let body = {webhook_url: $webhook_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the Slack integration of the organization and associated resources
#
# DELETE /organizations/{provider}/{remoteOrganizationName}/integrations/slack
# operationId: deleteSlackIntegration
export def "organizations-integrations-slack delete" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/integrations/slack")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the human-readable Git diff of a pull request
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/pull-requests/{pullRequestNumber}/diff
# operationId: getPullRequestDiff
export def "organizations-repositories-pull-requests-diff get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  pullRequestNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<diff: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/pull-requests/($pullRequestNumber)/diff")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the human-readable Git diff of a pull request
#
# GET /coverage/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/pull-requests/{pullRequestNumber}/diff
# DEPRECATED
# operationId: getPullRequestGitDiff
@deprecated
export def "coverage-organizations-repositories-pull-requests-diff get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  pullRequestNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<diff: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coverage/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/pull-requests/($pullRequestNumber)/diff")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the human-readable Git diff of a commit
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/commits/{commitUuid}/diff
# operationId: getCommitDiff
export def "organizations-repositories-commits-diff get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  commitUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<diff: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/commits/($commitUuid)/diff")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the human-readable Git diff between a head commit and a base commit
#
# GET /organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/base/{baseCommitUuid}/head/{headCommitUuid}/diff
# operationId: getDiffBetweenCommits
export def "organizations-repositories-base-head-diff get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  baseCommitUuid: string
  headCommitUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<diff: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/base/($baseCommitUuid)/head/($headCommitUuid)/diff")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a CSV file listing all security and risk management items for an organization.
#
# GET /reports/organizations/{provider}/{remoteOrganizationName}/security/items
# operationId: getReportSecurityItems
export def "reports-organizations-security-items get" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reports/organizations/($provider)/($remoteOrganizationName)/security/items")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a filtered CSV export of security and risk management items
#
# POST /reports/organizations/{provider}/{remoteOrganizationName}/security/items/search
# operationId: searchReportSecurityItems
export def "reports-organizations-security-items-search searchReportSecurityItems" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --repositories: list # Repository names to filter by
  --priorities: list # Security issue priorities to filter by. See [SrmPriority](#tocssrmpriority) for valid values.
  --statuses: list # Security issue status to filter by. See [SrmStatus](#tocssrmstatus) for valid values.
  --categories: list # Security categories to filter by. Use `_other_` to search for issues that don't have a security category
  --scanTypes: list # Scan types to filter by (e.g. [SAST, SCA, ContainerSCA, Secrets, IaC, CICD, License, PenTesting, DAST, CSPM])
  --segments: list # Segment IDs to filter by (e.g. [1, 2, 3])
  --searchText: string # Text to search for in security items
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reports/organizations/($provider)/($remoteOrganizationName)/security/items/search")
  let body = {repositories: $repositories, priorities: $priorities, statuses: $statuses, categories: $categories, scanTypes: $scanTypes, segments: $segments, searchText: $searchText} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search SBOM dependencies for the organization in CSV format
#
# POST /reports/organizations/{provider}/{remoteOrganizationName}/sbom/dependencies/search
# operationId: searchReportSbomDependencies
export def "reports-organizations-sbom-dependencies-search searchReportSbomDependencies" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text: string # Text search query. Matches against SBOM component fields (purl, full_name).
  --repositories: list # Repository names to filter by.
  --segments: list # Segments ids to filter by. (e.g. [1, 2, 3])
  --findingSeverities: list # Finding severities to filter by. Possible values are `Critical`, `High`, `Medium`, `Low`.
  --riskCategories: list # License Risk categories to filter by.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reports/organizations/($provider)/($remoteOrganizationName)/sbom/dependencies/search")
  let body = {text: $text, repositories: $repositories, segments: $segments, findingSeverities: $findingSeverities, riskCategories: $riskCategories} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get information about a commit
#
# GET /organizations/{provider}/{remoteOrganizationName}/commit/{commitId}
# DEPRECATED
# operationId: getCommitDetails
@deprecated
export def "organizations-commit get" [
  provider: string
  remoteOrganizationName: string
  commitId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<commit: record<sha: string, id: int, commitTimestamp: string, authorName: string, authorEmail: string, message: string, startedAnalysis: string, endedAnalysis: string, isMergeCommit: bool, gitHref: string, parents: list<string>>, repository: record<repositoryId: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/commit/($commitId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get information about a commit
#
# GET /commits/{commitId}
# operationId: getCommitDetailsByCommitId
export def "commits get" [
  commitId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<commit: record<sha: string, id: int, commitTimestamp: string, authorName: string, authorEmail: string, message: string, startedAnalysis: string, endedAnalysis: string, isMergeCommit: bool, gitHref: string, parents: list<string>>, repository: record<repositoryId: int, name: string, provider: string, organizationName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/commits/($commitId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send a heartbeat to keep the session alive
#
# POST /session/heartbeat
# operationId: heartbeat
export def "session-heartbeat heartbeat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wasActive: string@bool-completer # True if the user was active in the last heartbeat interval. (e.g. true)
]: any -> record<lastActivity: string, idleExpiresIn: int, absoluteExpiresIn: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/session/heartbeat")
  let body = {wasActive: $wasActive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check if the repository has quick fix suggestions for a branch
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/issues/hasSuggestions
# operationId: hasQuickfixSuggestions
export def "analysis-organizations-repositories-issues-has-suggestions hasQuickfixSuggestions" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # Name of a [repository branch enabled on Codacy](https://docs.codacy.com/repositories-configure/managing-branches/), as returned by the endpoint [listRepositoryBranches](#listrepositorybranches). By default, uses the main branch defined on the Codacy repository settings.  (e.g. master)
]: nothing -> record<hasSuggestions: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/issues/hasSuggestions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get quickfixes for issues in patch format
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/issues/patch
# operationId: getQuickfixesPatch
export def "analysis-organizations-repositories-issues-patch get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # Name of a [repository branch enabled on Codacy](https://docs.codacy.com/repositories-configure/managing-branches/), as returned by the endpoint [listRepositoryBranches](#listrepositorybranches). By default, uses the main branch defined on the Codacy repository settings.  (e.g. master)
]: nothing -> record<data: record<patch: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/issues/patch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get quickfixes for pull request issues in patch format
#
# GET /analysis/organizations/{provider}/{remoteOrganizationName}/repositories/{repositoryName}/pull-requests/{pullRequestNumber}/issues/patch
# operationId: getPullRequestQuickfixesPatch
export def "analysis-organizations-repositories-pull-requests-issues-patch get" [
  provider: string
  remoteOrganizationName: string
  repositoryName: string
  pullRequestNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<patch: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analysis/organizations/($provider)/($remoteOrganizationName)/repositories/($repositoryName)/pull-requests/($pullRequestNumber)/issues/patch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the audit logs for the organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/audit
# operationId: listAuditLogsForOrganization
export def "organizations-audit listAuditLogsForOrganization" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: int # Starting timestamp of audit logs in unix epoch milliseconds. Defaults to the earliest available time if not provided. (format: int64, e.g. 1720446021296)
  --qp-to: int # Ending timestamp of audit logs in unix epoch milliseconds. Defaults to the current time if not provided. (format: int64, e.g. 1726233785428)
]: nothing -> table<actor: record<email: string, role: string>, action: string, result: string, timestamp: string, source: string, repositoryName: string, description: string, details: record, entityId: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/audit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the status of the segments synchronization
#
# GET /organizations/{provider}/{remoteOrganizationName}/segments/sync
# operationId: getSegmentsSyncStatus
export def "organizations-segments-sync get" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, error: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/segments/sync")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Synchronize the segments of the organization with the Git provider
#
# POST /organizations/{provider}/{remoteOrganizationName}/segments/sync
# operationId: syncSegments
export def "organizations-segments-sync syncSegments" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/segments/sync")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the segment keys for the organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/segments/keys
# operationId: getSegmentsKeys
export def "organizations-segments-keys get" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/segments/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the segment keys with IDs for the organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/segments/keys/ids
# operationId: getSegmentsKeysWithIds
export def "organizations-segments-keys-ids get" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<id: int, key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/segments/keys/ids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get segment values for a segment key
#
# GET /organizations/{provider}/{remoteOrganizationName}/segments/values/{segmentKey}
# DEPRECATED
# operationId: getSegmentsValues
@deprecated
export def "organizations-segments-values get-by-provider-remoteOrganizationName-segmentKey" [
  provider: string
  remoteOrganizationName: string
  segmentKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<id: int, name: string, value: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/segments/values/($segmentKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the segment values for the organization by segment key
#
# GET /organizations/{provider}/{remoteOrganizationName}/segments/{segmentKey}/values
# operationId: getSegments
export def "organizations-segments-values get-by-provider-remoteOrganizationName-segmentKey-1" [
  provider: string
  remoteOrganizationName: string
  segmentKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<id: int, name: string, value: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/segments/($segmentKey)/values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List configured DAST targets
#
# GET /organizations/{provider}/{remoteOrganizationName}/dast/targets
# operationId: getDastTargets
export def "organizations-dast-targets get" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<id: int, url: string, status: list, targetType: string, apiDefinitionUrl: string, apiAuthHeaderNames: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/dast/targets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a DAST target
#
# POST /organizations/{provider}/{remoteOrganizationName}/dast/targets
# operationId: createDastTarget
export def "organizations-dast-targets createDastTarget" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # format: uri, e.g. https://api.domain.com/v1
  --targetType: string@targetType-completer # Dast target request type (default: webapp)
  --apiDefinitionUrl: string # e.g. https://api.domain.com/v1
  --apiAuthHeaders: record
]: any -> record<data: record<id: int, url: string, status: list<record>, targetType: string, apiDefinitionUrl: string, apiAuthHeaderNames: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/dast/targets")
  let body = {url: $body_url, targetType: $targetType, apiDefinitionUrl: $apiDefinitionUrl, apiAuthHeaders: $apiAuthHeaders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a DAST target
#
# DELETE /organizations/{provider}/{remoteOrganizationName}/dast/targets/{dastTargetId}
# operationId: deleteDastTarget
export def "organizations-dast-targets delete" [
  provider: string
  remoteOrganizationName: string
  dastTargetId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/dast/targets/($dastTargetId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enqueue a DAST analysis for the given target
#
# POST /organizations/{provider}/{remoteOrganizationName}/dast/targets/{dastTargetId}/analyze
# operationId: analyzeDastTarget
export def "organizations-dast-targets-analyze analyzeDastTarget" [
  provider: string
  remoteOrganizationName: string
  dastTargetId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<analysisId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/dast/targets/($dastTargetId)/analyze")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the SLA configuration for an organization
#
# GET /organizations/{provider}/{remoteOrganizationName}/security/sla
# operationId: getSLAConfig
export def "organizations-security-sla get" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<slaConfig: record<criticalSla: int, highSla: int, mediumSla: int, lowSla: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/security/sla")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the SLA configuration for an organization
#
# PUT /organizations/{provider}/{remoteOrganizationName}/security/sla
# operationId: updateSLAConfig
# --slaConfig shape: {criticalSla: int, highSla: int, mediumSla: int, lowSla: int}
export def "organizations-security-sla updateSLAConfig" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  slaConfig: record # SLA configuration of an organization. — shape: {criticalSla: int, highSla: int, mediumSla: int, lowSla: int}
]: any -> record<slaConfig: record<criticalSla: int, highSla: int, mediumSla: int, lowSla: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/security/sla")
  let body = {slaConfig: $slaConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the organizations of an enterprise
#
# GET /enterprises/{provider}/{enterpriseName}/organizations
# operationId: listEnterpriseOrganizations
export def "enterprises-organizations listEnterpriseOrganizations" [
  enterpriseName: string
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<id: int, remoteId: string, name: string, displayName: string, userRole: string, url: string, avatar: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enterprises/($provider)/($enterpriseName)/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user enterprises
#
# GET /enterprises/{provider}
# operationId: listEnterprises
export def "enterprises listEnterprises" [
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
]: nothing -> record<data: table<name: string, displayName: string, userRole: string, url: string, avatarUrl: string, provider: string>, pagination: record<cursor: string, limit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enterprises/($provider)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an enterprise
#
# GET /enterprises/{provider}/{enterpriseName}
# operationId: getEnterprise
export def "enterprises get" [
  enterpriseName: string
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<name: string, displayName: string, userRole: string, url: string, avatarUrl: string, provider: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enterprises/($provider)/($enterpriseName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get enterprise seats
#
# GET /enterprises/{provider}/{enterpriseName}/seats
# operationId: listEnterpriseSeats
export def "enterprises-seats listEnterpriseSeats" [
  provider: string
  enterpriseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --search: string # Filter results by searching for this string (e.g. my-repository-name)
]: nothing -> record<pagination: record<cursor: string, limit: int, total: int>, data: table<organizationsIds: list, emails: list, lastAnalysis: string, createdAt: string, lastCommitId: int, providerId: string, providerLogin: string, isActive: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enterprises/($provider)/($enterpriseName)/seats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get enterprise seats as a CSV file
#
# GET /reports/enterprises/{provider}/{enterpriseName}/seats-csv
# operationId: listEnterpriseSeatsCsv
export def "reports-enterprises-seats-csv listEnterpriseSeatsCsv" [
  provider: string
  enterpriseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reports/enterprises/($provider)/($enterpriseName)/seats-csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List available plans in Codacy
#
# GET /plans
# operationId: listPaymentPlans
export def "plans listPaymentPlans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<defaultYearlyPaidCode: string, defaultMonthlyPaidCode: string, trialCode: string, openSourceCode: string, defaultYearlyPaidPlan: record<isPremium: bool, model: string, code: string, monthly: bool, price: int, pricedPerUser: bool, alternatePeriodCode: string>, defaultMonthlyPaidPlan: record<isPremium: bool, model: string, code: string, monthly: bool, price: int, pricedPerUser: bool, alternatePeriodCode: string>, trialPlan: record<isPremium: bool, model: string, code: string, monthly: bool, price: int, pricedPerUser: bool, alternatePeriodCode: string>, openSourcePlan: record<isPremium: bool, model: string, code: string, monthly: bool, price: int, pricedPerUser: bool, alternatePeriodCode: string>, plans: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/plans")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the OSSF Scorecard for a repository
#
# POST /security/dependencies/ossf/scorecard
# operationId: getOssfScorecard
export def "security-dependencies-ossf-scorecard post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # The URL of the repository to fetch OSSF Scorecard information for. (e.g. https://www.github.com/codacy/codacy)
  --purl: string # The PURL of the dependency to fetch OSSF Scorecard information for. (e.g. maven:ch.qos.logback:logback-classic:1.2.3)
]: any -> record<data: record<score: float, date: string, checks: list<record>, failingCheckCount: int, passingCheckCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/security/dependencies/ossf/scorecard")
  let body = {url: $body_url, purl: $purl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List AI inventory provider summaries for an organization
#
# POST /organizations/{provider}/{remoteOrganizationName}/ai-inventory/providers/summaries/search
# operationId: searchAiInventoryProviderSummaries
export def "organizations-ai-inventory-providers-summaries-search searchAiInventoryProviderSummaries" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --inventoryItemTypes: list # Inventory item types to filter by (e.g. `tool`, `asset`) (e.g. [tool])
  --aiProvider: string # AI provider name to filter by (e.g. Claude Code)
  --segments: list # Segment IDs to filter by (e.g. [1, 2, 3])
  --repositories: list # Repository names to filter by
  --categoryGroups: list # Inventory category groups to filter by (e.g. `workflows`, `usage`, `mcps`). Category groups are the higher-level buckets that group individual categories  (e.g. [usage])
  --categories: list # Inventory categories to filter by (e.g. `code_marker`, `commits`, `branches`, `settings`, `instructions`). Available categories grouped by category group can be retrieved from the categories endpoint  (e.g. [code_marker])
  --marker: string # Marker text to filter by. Typically used when drilling down from a marker summary to list its repositories or locations  (e.g. Generated with [Claude Code])
]: any -> record<data: table<aiProvider: string, resourcesCount: int, referencesCount: int, repositoriesCount: int, categoryGroupBreakdown: list>, pagination: record<cursor: string, limit: int, total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/ai-inventory/providers/summaries/search" $qp)
  let body = {inventoryItemTypes: $inventoryItemTypes, aiProvider: $aiProvider, segments: $segments, repositories: $repositories, categoryGroups: $categoryGroups, categories: $categories, marker: $marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get AI inventory summary for a specific provider
#
# POST /organizations/{provider}/{remoteOrganizationName}/ai-inventory/providers/summary
# operationId: getAiInventoryProviderSummary
export def "organizations-ai-inventory-providers-summary post" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  aiProvider: string # AI provider name to return the summary for (e.g. Claude Code)
  --inventoryItemTypes: list # Inventory item types to filter by (e.g. `tool`, `asset`) (e.g. [tool])
  --segments: list # Segment IDs to filter by (e.g. [1, 2, 3])
  --repositories: list # Repository names to filter by
  --categoryGroups: list # Inventory category groups to filter by (e.g. `workflows`, `usage`, `mcps`). Category groups are the higher-level buckets that group individual categories  (e.g. [usage])
  --categories: list # Inventory categories to filter by (e.g. `code_marker`, `commits`, `branches`, `settings`, `instructions`). Available categories grouped by category group can be retrieved from the categories endpoint  (e.g. [code_marker])
]: any -> record<data: record<aiProvider: string, resourcesCount: int, referencesCount: int, repositoriesCount: int, categoryGroupBreakdown: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/ai-inventory/providers/summary")
  let body = {aiProvider: $aiProvider, inventoryItemTypes: $inventoryItemTypes, segments: $segments, repositories: $repositories, categoryGroups: $categoryGroups, categories: $categories} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List AI inventory marker summaries for an organization
#
# POST /organizations/{provider}/{remoteOrganizationName}/ai-inventory/markers/summaries/search
# operationId: searchAiInventoryMarkerSummaries
export def "organizations-ai-inventory-markers-summaries-search searchAiInventoryMarkerSummaries" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --inventoryItemTypes: list # Inventory item types to filter by (e.g. `tool`, `asset`) (e.g. [tool])
  --aiProvider: string # AI provider name to filter by (e.g. Claude Code)
  --segments: list # Segment IDs to filter by (e.g. [1, 2, 3])
  --repositories: list # Repository names to filter by
  --categoryGroups: list # Inventory category groups to filter by (e.g. `workflows`, `usage`, `mcps`). Category groups are the higher-level buckets that group individual categories  (e.g. [usage])
  --categories: list # Inventory categories to filter by (e.g. `code_marker`, `commits`, `branches`, `settings`, `instructions`). Available categories grouped by category group can be retrieved from the categories endpoint  (e.g. [code_marker])
  --marker: string # Marker text to filter by. Typically used when drilling down from a marker summary to list its repositories or locations  (e.g. Generated with [Claude Code])
]: any -> record<data: table<categoryGroup: string, category: string, marker: string, referencesCount: int, repositoriesCount: int>, pagination: record<cursor: string, limit: int, total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/ai-inventory/markers/summaries/search" $qp)
  let body = {inventoryItemTypes: $inventoryItemTypes, aiProvider: $aiProvider, segments: $segments, repositories: $repositories, categoryGroups: $categoryGroups, categories: $categories, marker: $marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List repositories that have AI inventory items
#
# POST /organizations/{provider}/{remoteOrganizationName}/ai-inventory/repositories/search
# operationId: searchAiInventoryRepositories
export def "organizations-ai-inventory-repositories-search searchAiInventoryRepositories" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --inventoryItemTypes: list # Inventory item types to filter by (e.g. `tool`, `asset`) (e.g. [tool])
  --aiProvider: string # AI provider name to filter by (e.g. Claude Code)
  --segments: list # Segment IDs to filter by (e.g. [1, 2, 3])
  --repositories: list # Repository names to filter by
  --categoryGroups: list # Inventory category groups to filter by (e.g. `workflows`, `usage`, `mcps`). Category groups are the higher-level buckets that group individual categories  (e.g. [usage])
  --categories: list # Inventory categories to filter by (e.g. `code_marker`, `commits`, `branches`, `settings`, `instructions`). Available categories grouped by category group can be retrieved from the categories endpoint  (e.g. [code_marker])
  --marker: string # Marker text to filter by. Typically used when drilling down from a marker summary to list its repositories or locations  (e.g. Generated with [Claude Code])
]: any -> record<data: table<name: string, owner: string>, pagination: record<cursor: string, limit: int, total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/ai-inventory/repositories/search" $qp)
  let body = {inventoryItemTypes: $inventoryItemTypes, aiProvider: $aiProvider, segments: $segments, repositories: $repositories, categoryGroups: $categoryGroups, categories: $categories, marker: $marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List AI inventory repository summaries for an organization
#
# POST /organizations/{provider}/{remoteOrganizationName}/ai-inventory/repositories/summaries/search
# operationId: searchAiInventoryRepositorySummaries
export def "organizations-ai-inventory-repositories-summaries-search searchAiInventoryRepositorySummaries" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --inventoryItemTypes: list # Inventory item types to filter by (e.g. `tool`, `asset`) (e.g. [tool])
  --aiProvider: string # AI provider name to filter by (e.g. Claude Code)
  --segments: list # Segment IDs to filter by (e.g. [1, 2, 3])
  --repositories: list # Repository names to filter by
  --categoryGroups: list # Inventory category groups to filter by (e.g. `workflows`, `usage`, `mcps`). Category groups are the higher-level buckets that group individual categories  (e.g. [usage])
  --categories: list # Inventory categories to filter by (e.g. `code_marker`, `commits`, `branches`, `settings`, `instructions`). Available categories grouped by category group can be retrieved from the categories endpoint  (e.g. [code_marker])
  --marker: string # Marker text to filter by. Typically used when drilling down from a marker summary to list its repositories or locations  (e.g. Generated with [Claude Code])
]: any -> record<data: table<repositoryName: string, locationsCount: int, referencesCount: int>, pagination: record<cursor: string, limit: int, total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/ai-inventory/repositories/summaries/search" $qp)
  let body = {inventoryItemTypes: $inventoryItemTypes, aiProvider: $aiProvider, segments: $segments, repositories: $repositories, categoryGroups: $categoryGroups, categories: $categories, marker: $marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List AI inventory location summaries for an organization
#
# POST /organizations/{provider}/{remoteOrganizationName}/ai-inventory/locations/summaries/search
# operationId: searchAiInventoryLocationSummaries
export def "organizations-ai-inventory-locations-summaries-search searchAiInventoryLocationSummaries" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to [specify a batch of results to request](https://docs.codacy.com/codacy-api/using-the-codacy-api/#using-pagination) (e.g. Yms345gh==)
  --limit: int # Maximum number of items to return (format: int32, default: 100, e.g. 20)
  --inventoryItemTypes: list # Inventory item types to filter by (e.g. `tool`, `asset`) (e.g. [tool])
  --aiProvider: string # AI provider name to filter by (e.g. Claude Code)
  --segments: list # Segment IDs to filter by (e.g. [1, 2, 3])
  --repositories: list # Repository names to filter by
  --categoryGroups: list # Inventory category groups to filter by (e.g. `workflows`, `usage`, `mcps`). Category groups are the higher-level buckets that group individual categories  (e.g. [usage])
  --categories: list # Inventory categories to filter by (e.g. `code_marker`, `commits`, `branches`, `settings`, `instructions`). Available categories grouped by category group can be retrieved from the categories endpoint  (e.g. [code_marker])
  --marker: string # Marker text to filter by. Typically used when drilling down from a marker summary to list its repositories or locations  (e.g. Generated with [Claude Code])
]: any -> record<data: table<location: string, regions: list>, pagination: record<cursor: string, limit: int, total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/ai-inventory/locations/summaries/search" $qp)
  let body = {inventoryItemTypes: $inventoryItemTypes, aiProvider: $aiProvider, segments: $segments, repositories: $repositories, categoryGroups: $categoryGroups, categories: $categories, marker: $marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List AI inventory categories grouped by category group
#
# POST /organizations/{provider}/{remoteOrganizationName}/ai-inventory/categories/search
# operationId: searchAiInventoryCategories
export def "organizations-ai-inventory-categories-search searchAiInventoryCategories" [
  provider: string
  remoteOrganizationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --inventoryItemTypes: list # Inventory item types to filter by (e.g. `tool`, `asset`) (e.g. [tool])
  --aiProvider: string # AI provider name to filter by (e.g. Claude Code)
  --segments: list # Segment IDs to filter by (e.g. [1, 2, 3])
  --repositories: list # Repository names to filter by
  --categoryGroups: list # Inventory category groups to filter by (e.g. `workflows`, `usage`, `mcps`). Category groups are the higher-level buckets that group individual categories  (e.g. [usage])
  --categories: list # Inventory categories to filter by (e.g. `code_marker`, `commits`, `branches`, `settings`, `instructions`). Available categories grouped by category group can be retrieved from the categories endpoint  (e.g. [code_marker])
  --marker: string # Marker text to filter by. Typically used when drilling down from a marker summary to list its repositories or locations  (e.g. Generated with [Claude Code])
]: any -> record<data: table<categoryGroup: string, categories: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($provider)/($remoteOrganizationName)/ai-inventory/categories/search")
  let body = {inventoryItemTypes: $inventoryItemTypes, aiProvider: $aiProvider, segments: $segments, repositories: $repositories, categoryGroups: $categoryGroups, categories: $categories, marker: $marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
