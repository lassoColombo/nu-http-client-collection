# Auto-generated client for graphql v0.0.0
# Source: https://sourcegraph.com/.api/graphql
# Auth: --token flag or $env.GRAPHQL_TOKEN

const BASE_URL = "https://sourcegraph.com/.api/graphql"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GRAPHQL_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

# Unwrap a GraphQL response: extract data.{field} and surface errors
def unwrap-graphql [resp: any, field: string] {
  if ($resp | describe) == "string" { return $resp }
  let errors = ($resp.errors? | default [])
  if ($errors | length) > 0 {
    let msgs = ($errors | each {|e| $e.message? | default "unknown error" } | str join "; ")
    error make --unspanned { msg: $"GraphQL error: ($msgs)" }
  }
  $resp.data? | get -o $field | default $resp.data?
}

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://sourcegraph.com/.api/graphql"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def kind-completer [] { ["AWSCODECOMMIT" "AZUREDEVOPS" "BITBUCKETCLOUD" "BITBUCKETSERVER" "GERRIT" "GITHUB" "GITLAB" "GITOLITE" "OTHER" "PAGURE" "PERFORCE" "PHABRICATOR"] }
def clone-status-completer [] { ["CLONED" "CLONING" "NOT_CLONED"] }
def order-by-completer [] { ["LAST_CHANGED" "REPOSITORY_CREATED_AT" "REPOSITORY_NAME" "REPO_CREATED_AT" "SIZE" "STARS"] }
def active-period-completer [] { ["ALL_TIME" "THIS_MONTH" "THIS_WEEK" "TODAY"] }
def version-completer [] { ["V1" "V2" "V3"] }
def pattern-type-completer [] { ["codycontext" "keyword" "literal" "lucky" "nls" "regexp" "standard" "structural"] }
def output-phase-completer [] { ["JOB_TREE" "PARSE_TREE"] }
def output-format-completer [] { ["JSON" "MERMAID" "SEXP"] }
def output-verbosity-completer [] { ["BASIC" "MAXIMAL" "MINIMAL"] }
def scope-completer [] { ["BATCHES" "CODEINTEL"] }
def status-completer [] { ["APPROVED" "CANCELED" "PENDING" "REJECTED"] }
def sku-completer [] { ["DEEP_SEARCH"] }
def states-completer [] { ["COMPLETED" "DELETED" "DELETING" "INDEXING" "INDEXING_COMPLETED" "INDEXING_ERRORED" "PROCESSING" "PROCESSING_ERRORED" "QUEUED_FOR_INDEXING" "QUEUED_FOR_PROCESSING" "SUPERSEDED" "UPLOADING_INDEX"] }
def index-source-completer [] { ["AUTO_INDEX" "UPLOAD"] }
def input-groupBy-completer [] { ["AUTHOR" "DATE" "LANG" "PATH" "REPO"] }
def order-by-completer-1 [] { ["QUEUE_POSITION" "STATE"] }
def states-completer-1 [] { ["COMPLETED" "FAILED" "NEW" "PROCESSING" "QUEUED" "UNKNOWN"] }
def perm-completer [] { ["READ"] }
def reason-group-completer [] { ["MANUAL" "SCHEDULE" "SOURCEGRAPH" "UNKNOWN" "WEBHOOK"] }
def state-completer [] { ["CANCELED" "COMPLETED" "ERRORED" "FAILED" "PROCESSING" "QUEUED"] }
def search-type-completer [] { ["REPOSITORY" "USER"] }
def wizard-type-completer [] { ["AUTH_PROVIDER_BITBUCKET_CLOUD" "AUTH_PROVIDER_BITBUCKET_SERVER" "AUTH_PROVIDER_GERRIT" "AUTH_PROVIDER_GITHUB" "AUTH_PROVIDER_GITLAB" "AUTH_PROVIDER_OPENIDCONNECT" "AUTH_PROVIDER_SAML" "UNKNOWN"] }
def order-by-completer-2 [] { ["SAVED_SEARCH_DESCRIPTION" "SAVED_SEARCH_UPDATED_AT"] }
def domain-completer [] { ["AGENTS_REVIEW" "BATCHES" "REPOS"] }
def order-by-completer-3 [] { ["SEARCH_CONTEXT_SPEC" "SEARCH_CONTEXT_UPDATED_AT"] }
def type-completer [] { ["DEEP_SEARCH" "SMART_HOVER_SUMMARY"] }
def order-by-completer-4 [] { ["PROMPT_NAME_WITH_OWNER" "PROMPT_RECOMMENDED" "PROMPT_RELEVANCE" "PROMPT_UPDATED_AT"] }
def order-by-multiple-completer [] { ["PROMPT_NAME_WITH_OWNER" "PROMPT_RECOMMENDED" "PROMPT_RELEVANCE" "PROMPT_UPDATED_AT"] }
def order-by-completer-5 [] { ["PROMPT_TAG_NAME"] }
def order-by-multiple-completer-1 [] { ["PROMPT_TAG_NAME"] }
def input-kind-completer [] { ["AWSCODECOMMIT" "AZUREDEVOPS" "BITBUCKETCLOUD" "BITBUCKETSERVER" "GERRIT" "GITHUB" "GITLAB" "GITOLITE" "OTHER" "PAGURE" "PERFORCE" "PHABRICATOR"] }
def strategy-completer [] { ["EAGER" "HEURISTIC"] }
def response-type-completer [] { ["ACCEPT" "REJECT"] }
def event-completer [] { ["CODEINTEL" "CODEINTELINTEGRATION" "CODEINTELINTEGRATIONREFS" "CODEINTELREFS" "PAGEVIEW" "SEARCHQUERY" "STAGEAUTOMATE" "STAGECODE" "STAGECONFIGURE" "STAGEDEPLOY" "STAGEMANAGE" "STAGEMONITOR" "STAGEPACKAGE" "STAGEPLAN" "STAGEREVIEW" "STAGESECURE" "STAGEVERIFY"] }
def source-completer [] { ["BACKEND" "CODEHOSTINTEGRATION" "CODY" "IDEEXTENSION" "STATICWEB" "WEB"] }
def smtp-authentication-completer [] { ["CRAM_MD5" "NONE" "PLAIN"] }
def type-completer-1 [] { ["GIT_BLOB" "GIT_COMMIT" "GIT_TAG" "GIT_TREE" "GIT_UNKNOWN"] }
def input-wizardType-completer [] { ["AUTH_PROVIDER_BITBUCKET_CLOUD" "AUTH_PROVIDER_BITBUCKET_SERVER" "AUTH_PROVIDER_GERRIT" "AUTH_PROVIDER_GITHUB" "AUTH_PROVIDER_GITLAB" "AUTH_PROVIDER_OPENIDCONNECT" "AUTH_PROVIDER_SAML" "UNKNOWN"] }
def input-visibility-completer [] { ["PUBLIC" "SECRET"] }
def new-visibility-completer [] { ["PUBLIC" "SECRET"] }
def window-completer [] { ["ONE_DAY" "ONE_HOUR" "SEVEN_DAYS" "THIRTY_DAYS"] }
def input-mode-completer [] { ["CHAT" "EDIT" "INSERT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "query root" } } | get name | first)
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

# The root of the query.
#
# DEPRECATED
# operationId: root
@deprecated "this will be removed."
export def "query root" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "renderMarkdown highlightCode parseSearchQuery evaluateFeatureFlag organizationFeatureFlagValue areExecutorsConfigured viewerCanChangeLibraryItemVisibilityToPublic indexerKeys codeIntelligenceInferenceScript usersWithPendingPermissions enterpriseLicenseHasFeature isSearchContextAvailable completions" }
    let body = {query: ("query { root { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "root" }
}

# Looks up a node by ID.
#
# operationId: node
export def "query node" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id ... on GitserverInstance { address freeDiskSpaceBytes totalDiskSpaceBytes } ... on IndexedSearchInstance { address } ... on ExecutorSecret { key scope overwritesGlobalSecret createdAt updatedAt }" }
    let body = {query: ("query($id: ID!) { node(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "node" }
}

# Looks up a repository by either name or cloneURL.
#
# operationId: repository
export def "query repository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --name: string # Query the repository by name, for example "github.com/gorilla/mux".
  --clone-url: string # Query the repository by a Git clone URL (format documented here: https://git-scm.com/docs/git-clone_git_urls_a_id_urls_a) by checking for a code host configuration that matches the clone URL. Will not actually check the code host to see if the repository actually exists.
  --uri: string # An alias for name. DEPRECATED: use name instead.
  --database-id: int # Query the repository by its database ID. NOTE: this is intended for debugging purposes only, and clients should generally just use GraphQL IDs.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"name": $name, "cloneURL": $clone_url, "uri": $uri, "databaseID": $database_id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id databaseID name uri sourceType description iconURL language createdAt updatedAt isFork isArchived isPrivate cloneInProgress url viewerCanAdminister stars topics diskSizeBytes isRecordingEnabled" }
    let body = {query: ("query($name: String, $cloneURL: String, $uri: String, $databaseID: Int) { repository(name: $name, cloneURL: $cloneURL, uri: $uri, databaseID: $databaseID) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "repository" }
}

# Looks up a repository by either name or cloneURL or hashedName. When the repository does not exist on the server, it returns a Redirect to an external Sourcegraph URL that may have this repository instead. Otherwise, this query returns null.
#
# operationId: repositoryRedirect
export def "query repository-redirect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --name: string # Query the repository by name, for example "github.com/gorilla/mux".
  --clone-url: string # Query the repository by a Git clone URL (format documented here: https://git-scm.com/docs/git-clone_git_urls_a_id_urls_a) by checking for a code host configuration that matches the clone URL. Will not actually check the code host to see if the repository actually exists.
  --hashed-name: string # Query the repository by hashed name. Hashed name is a SHA256 checksum of the absolute repo name in lower case, for example "github.com/sourcegraph/sourcegraph" -> "a6c905ceb7dec9a565945ceded8c7fa4154250df8b928fb40673b535d9a24c2f"
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"name": $name, "cloneURL": $clone_url, "hashedName": $hashed_name} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename ... on Repository { id databaseID name uri sourceType description iconURL language createdAt updatedAt isFork isArchived isPrivate cloneInProgress url viewerCanAdminister stars topics diskSizeBytes isRecordingEnabled } ... on Redirect { url }" }
    let body = {query: ("query($name: String, $cloneURL: String, $hashedName: String) { repositoryRedirect(name: $name, cloneURL: $cloneURL, hashedName: $hashedName) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "repositoryRedirect" }
}

# Lists external services under given namespace. If no namespace is given, it returns all external services.
#
# operationId: externalServices
export def "query external-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int # Returns the first n external services from the list.
  --after: string # Opaque pagination cursor.
  --repo: string # If provided, fetch external services which contain a repo with the given ID.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first, "after": $after, "repo": $repo} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($first: Int, $after: String, $repo: ID) { externalServices(first: $first, after: $after, repo: $repo) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "externalServices" }
}

# Lists all namespaces for a given external service connection. A namespace is an entity on the code host that repositories are assignable to.
#
# operationId: externalServiceNamespaces
export def "query external-service-namespaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --id: string # The GraphQL ID of the external service whose configuration will be used to define the code host remote url to submit requests to and the token value to authenticate with. If no external service exists which provides the necessary request parameters then leave ID nil and provide kind, remote code host token and url.
  kind: string@kind-completer # The kind of the external service.
  token: string # The secret token value that is used to authenticate.
  url: string # The url of the external service.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id, "kind": $kind, "token": $token, "url": $url} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($id: ID, $kind: ExternalServiceKind!, $token: String!, $url: String!) { externalServiceNamespaces(id: $id, kind: $kind, token: $token, url: $url) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "externalServiceNamespaces" }
}

# Lists all repositories for a given external service connection.
#
# operationId: externalServiceRepositories
export def "query external-service-repositories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --id: string # The GraphQL ID of the external service whose configuration will be used to define the code host remote url to submit requests to and the token value to authenticate with. If no external service exists which provides the necessary request parameters then leave ID nil and provide kind, remote code host token and url.
  kind: string@kind-completer # The kind of the external service.
  token: string # The secret token value that is used to authenticate.
  url: string # The url of the external service.
  query: string # Repository query string.
  exclude_repos: string # A list of repository names to exclude from results (in the form of owner/name).
  --first: int # Returns the first n repositories matching the query and excludeRepos criteria.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id, "kind": $kind, "token": $token, "url": $url, "query": $query, "excludeRepos": $exclude_repos, "first": $first} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($id: ID, $kind: ExternalServiceKind!, $token: String!, $url: String!, $query: String!, $excludeRepos: [String!]!, $first: Int) { externalServiceRepositories(id: $id, kind: $kind, token: $token, url: $url, query: $query, excludeRepos: $excludeRepos, first: $first) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "externalServiceRepositories" }
}

# List all repositories.
#
# operationId: repositories
export def "query repositories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int # Returns the first n repositories from the list.
  --last: int # Returns the last n repositories from the list.
  --qp-query: string # Return repositories whose names match the query.
  --after: string # An opaque cursor that is used for pagination.
  --before: string # An opaque cursor that is used for pagination.
  --names: string # Return repositories whose names are in the list.
  --cloned: string@bool-completer # Include cloned repositories.
  --clone-status: string@clone-status-completer # Include only repositories of the given clone status.
  --not-cloned: string@bool-completer # Include repositories that are not yet cloned and for which cloning is not in progress.
  --indexed: string@bool-completer # Include repositories that have a text search index.
  --not-indexed: string@bool-completer # Include repositories that do not have a text search index.
  --failed-fetch: string@bool-completer # Include only repositories that have encountered errors when cloning or fetching
  --corrupted: string@bool-completer # Include repositories that are corrupt
  --external-service: string # Return repositories that are associated with the given external service.
  --order-by: string@order-by-completer # Sort field.
  --descending: string@bool-completer # Sort direction.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first, "last": $last, "query": $qp_query, "after": $after, "before": $before, "names": $names, "cloned": $cloned, "cloneStatus": $clone_status, "notCloned": $not_cloned, "indexed": $indexed, "notIndexed": $not_indexed, "failedFetch": $failed_fetch, "corrupted": $corrupted, "externalService": $external_service, "orderBy": $order_by, "descending": $descending} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($first: Int, $last: Int, $query: String, $after: String, $before: String, $names: [String!], $cloned: Boolean, $cloneStatus: CloneStatus, $notCloned: Boolean, $indexed: Boolean, $notIndexed: Boolean, $failedFetch: Boolean, $corrupted: Boolean, $externalService: ID, $orderBy: RepositoryOrderBy, $descending: Boolean) { repositories(first: $first, last: $last, query: $query, after: $after, before: $before, names: $names, cloned: $cloned, cloneStatus: $cloneStatus, notCloned: $notCloned, indexed: $indexed, notIndexed: $notIndexed, failedFetch: $failedFetch, corrupted: $corrupted, externalService: $externalService, orderBy: $orderBy, descending: $descending) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "repositories" }
}

# Looks up a Phabricator repository by name.
#
# operationId: phabricatorRepo
export def "query phabricator-repo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --name: string # The name, for example "github.com/gorilla/mux".
  --uri: string # An alias for name. DEPRECATED: use name instead.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"name": $name, "uri": $uri} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "name uri callsign url" }
    let body = {query: ("query($name: String, $uri: String) { phabricatorRepo(name: $name, uri: $uri) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "phabricatorRepo" }
}

# The current user.
#
# operationId: currentUser
export def "query current-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id username email displayName avatarURL url settingsURL createdAt updatedAt siteAdmin builtinAuth serviceAccount unrestrictedRepoAccess tosAccepted hasVerifiedEmail viewerCanAdminister viewerCanChangeUsername databaseID namespaceName scimControlled viewerCanChangePrimaryEmail completionsQuotaOverride codeCompletionsQuotaOverride evaluateFeatureFlag" }
    let body = {query: ("query { currentUser { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "currentUser" }
}

# Looks up a user by username or email address.
#
# operationId: user
export def "query user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --username: string # Query the user by username.
  --email: string # Query the user by verified email address.
  --database-id: int # Query the user by ID. Clients should prefer using GraphQL IDs. This is primarily intended for debugging.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"username": $username, "email": $email, "databaseID": $database_id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id username email displayName avatarURL url settingsURL createdAt updatedAt siteAdmin builtinAuth serviceAccount unrestrictedRepoAccess tosAccepted hasVerifiedEmail viewerCanAdminister viewerCanChangeUsername databaseID namespaceName scimControlled viewerCanChangePrimaryEmail completionsQuotaOverride codeCompletionsQuotaOverride evaluateFeatureFlag" }
    let body = {query: ("query($username: String, $email: String, $databaseID: Int) { user(username: $username, email: $email, databaseID: $databaseID) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "user" }
}

# List all users.
#
# operationId: users
export def "query users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int # Returns the first n users from the list.
  --after: string # Opaque pagination cursor.
  --qp-query: string # Return users whose usernames or display names match the query.
  --active-period: string@active-period-completer # Returns users who have been active in a given period of time.
  --inactive-since: string # Returns users who have NOT been active since a given point in time.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first, "after": $after, "query": $qp_query, "activePeriod": $active_period, "inactiveSince": $inactive_since} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($first: Int, $after: String, $query: String, $activePeriod: UserActivePeriod, $inactiveSince: DateTime) { users(first: $first, after: $after, query: $query, activePeriod: $activePeriod, inactiveSince: $inactiveSince) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "users" }
}

# Looks up an organization by name.
#
# operationId: organization
export def "query organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  name: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"name": $name} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name displayName createdAt viewerCanAdminister viewerIsMember url settingsURL namespaceName" }
    let body = {query: ("query($name: String!) { organization(name: $name) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "organization" }
}

# List all organizations.
#
# operationId: organizations
export def "query organizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int # Returns the first n organizations from the list.
  --qp-query: string # Return organizations whose names or display names match the query.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first, "query": $qp_query} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($first: Int, $query: String) { organizations(first: $first, query: $query) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "organizations" }
}

# Renders Markdown to HTML. The returned HTML is already sanitized and escaped and thus is always safe to render.
#
# operationId: renderMarkdown
export def "query render-markdown" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  markdown: string
  --options-alwaysNil: string # A dummy null value (empty input types are not allowed yet).
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let options = ({"alwaysNil": $options_alwaysNil} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"markdown": $markdown, "options": $options} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let body = {query: "query($markdown: String!, $options: MarkdownOptions) { renderMarkdown(markdown: $markdown, options: $options) }", variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "renderMarkdown" }
}

# EXPERIMENTAL: Syntax highlights a code string.
#
# operationId: highlightCode
export def "query highlight-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  code: string
  fuzzy_language: string
  --disable-timeout: string@bool-completer
  --is-light-theme: string@bool-completer
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"code": $code, "fuzzyLanguage": $fuzzy_language, "disableTimeout": $disable_timeout, "isLightTheme": $is_light_theme} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let body = {query: "query($code: String!, $fuzzyLanguage: String!, $disableTimeout: Boolean!, $isLightTheme: Boolean) { highlightCode(code: $code, fuzzyLanguage: $fuzzyLanguage, disableTimeout: $disableTimeout, isLightTheme: $isLightTheme) }", variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "highlightCode" }
}

# Looks up an instance of a type that implements SettingsSubject (i.e., something that has settings). This can be a site (which has global settings), an organization, or a user.
#
# operationId: settingsSubject
export def "query settings-subject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id settingsURL viewerCanAdminister ... on User { username email displayName avatarURL url createdAt updatedAt siteAdmin builtinAuth serviceAccount unrestrictedRepoAccess tosAccepted hasVerifiedEmail viewerCanChangeUsername databaseID namespaceName scimControlled viewerCanChangePrimaryEmail completionsQuotaOverride codeCompletionsQuotaOverride evaluateFeatureFlag } ... on Org { name displayName createdAt viewerIsMember url namespaceName }" }
    let body = {query: ("query($id: ID!) { settingsSubject(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "settingsSubject" }
}

# The settings for the viewer. The viewer is either an anonymous visitor (in which case viewer settings is global settings) or an authenticated user (in which case viewer settings are the user's settings).
#
# operationId: viewerSettings
export def "query viewer-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "final" }
    let body = {query: ("query { viewerSettings { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "viewerSettings" }
}

# DEPRECATED
#
# DEPRECATED
# operationId: viewerConfiguration
@deprecated "use viewerSettings instead"
export def "query viewer-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query { viewerConfiguration { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "viewerConfiguration" }
}

# The configuration for clients.
#
# operationId: clientConfiguration
export def "query client-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "contentScriptUrls" }
    let body = {query: ("query { clientConfiguration { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "clientConfiguration" }
}

# Runs a search.
#
# operationId: search
export def "query search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --version: string@version-completer # The version of the search syntax being used. All new clients should use the latest version.
  --pattern-type: string@pattern-type-completer # PatternType controls the search pattern type, if and only if it is not specified in the query string using the patternType: field.
  --qp-query: string # The search query (such as "foo" or "repo:myrepo foo").
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"version": $version, "patternType": $pattern_type, "query": $qp_query} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($version: SearchVersion, $patternType: SearchPatternType, $query: String) { search(version: $version, patternType: $patternType, query: $query) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "search" }
}

# EXPERIMENTAL: Return the parse tree of a search query.
#
# operationId: parseSearchQuery
export def "query parse-search-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --qp-query: string # The search query (such as "repo:myrepo foo").
  --pattern-type: string@pattern-type-completer # The parser to use for this query.
  --output-phase: string@output-phase-completer # The output corresponding to a phase in the parser pipeline.
  --output-format: string@output-format-completer # The parser output format.
  --output-verbosity: string@output-verbosity-completer # The level of output format verbosity.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"query": $qp_query, "patternType": $pattern_type, "outputPhase": $output_phase, "outputFormat": $output_format, "outputVerbosity": $output_verbosity} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let body = {query: "query($query: String, $patternType: SearchPatternType, $outputPhase: SearchQueryOutputPhase, $outputFormat: SearchQueryOutputFormat, $outputVerbosity: SearchQueryOutputVerbosity) { parseSearchQuery(query: $query, patternType: $patternType, outputPhase: $outputPhase, outputFormat: $outputFormat, outputVerbosity: $outputVerbosity) }", variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "parseSearchQuery" }
}

# The current site.
#
# operationId: site
export def "query site" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id siteID settingsURL canReloadSite viewerCanAdminister permissionsUserMappingBindID buildVersion productVersion needsRepositoryConfiguration externalServicesFromFile allowEditExternalServicesWithFile siteConfigBlocklistPaths siteConfigurationFromFile allowEditSiteConfigurationWithFile globalSettingsFromFile allowEditGlobalSettingsWithFile hasCodeIntelligence sendsEmailVerificationEmails allowSiteSettingsEdits perUserCompletionsQuota perUserCodeCompletionsQuota isCodyEnabled" }
    let body = {query: ("query { site { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "site" }
}

# Retrieve responses to surveys.
#
# operationId: surveyResponses
export def "query survey-responses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int # Returns the first n survey responses from the list.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount last30DaysCount averageScore netPromoterScore" }
    let body = {query: ("query($first: Int) { surveyResponses(first: $first) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "surveyResponses" }
}

# FOR INTERNAL USE ONLY: Lists all status messages
#
# operationId: statusMessages
export def "query status-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename ... on GitUpdatesDisabled { message } ... on NoRepositoriesDetected { message } ... on CloningProgress { message }" }
    let body = {query: ("query { statusMessages { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "statusMessages" }
}

# FOR INTERNAL USE ONLY: Query repository statistics for the site.
#
# operationId: repositoryStats
export def "query repository-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "gitDirBytes indexedLinesCount total cloned cloning notCloned failedFetch indexed corrupted" }
    let body = {query: ("query { repositoryStats { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "repositoryStats" }
}

# Look up a namespace by ID.
#
# operationId: namespace
export def "query namespace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id namespaceName url ... on User { username email displayName avatarURL settingsURL createdAt updatedAt siteAdmin builtinAuth serviceAccount unrestrictedRepoAccess tosAccepted hasVerifiedEmail viewerCanAdminister viewerCanChangeUsername databaseID scimControlled viewerCanChangePrimaryEmail completionsQuotaOverride codeCompletionsQuotaOverride evaluateFeatureFlag } ... on Org { name displayName createdAt viewerCanAdminister viewerIsMember settingsURL }" }
    let body = {query: ("query($id: ID!) { namespace(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "namespace" }
}

# Look up a namespace by name, which is a username or organization name.
#
# operationId: namespaceByName
export def "query namespace-by-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  name: string # The name of the namespace.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"name": $name} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id namespaceName url ... on User { username email displayName avatarURL settingsURL createdAt updatedAt siteAdmin builtinAuth serviceAccount unrestrictedRepoAccess tosAccepted hasVerifiedEmail viewerCanAdminister viewerCanChangeUsername databaseID scimControlled viewerCanChangePrimaryEmail completionsQuotaOverride codeCompletionsQuotaOverride evaluateFeatureFlag } ... on Org { name displayName createdAt viewerCanAdminister viewerIsMember settingsURL }" }
    let body = {query: ("query($name: String!) { namespaceByName(name: $name) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "namespaceByName" }
}

# Retrieve all registered out-of-band migrations. Optionally filter deprecated before first version out-of-band-migrations.
#
# operationId: outOfBandMigrations
export def "query out-of-band-migrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --exclude-deprecated-before-first-version: string@bool-completer
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"ExcludeDeprecatedBeforeFirstVersion": $exclude_deprecated_before_first_version} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id team component description introduced deprecated progress created lastUpdated nonDestructive applyReverse" }
    let body = {query: ("query($ExcludeDeprecatedBeforeFirstVersion: Boolean) { outOfBandMigrations(ExcludeDeprecatedBeforeFirstVersion: $ExcludeDeprecatedBeforeFirstVersion) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "outOfBandMigrations" }
}

# Retrieve the list of defined feature flags
#
# operationId: featureFlags
export def "query feature-flags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --search: string
  --type: string
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"search": $search, "type": $type} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename ... on FeatureFlagBoolean { name value createdAt updatedAt } ... on FeatureFlagRollout { name rolloutBasisPoints createdAt updatedAt }" }
    let body = {query: ("query($search: String, $type: String) { featureFlags(search: $search, type: $type) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "featureFlags" }
}

# Retrieve a feature flag
#
# operationId: featureFlag
export def "query feature-flag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  name: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"name": $name} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename ... on FeatureFlagBoolean { name value createdAt updatedAt } ... on FeatureFlagRollout { name rolloutBasisPoints createdAt updatedAt }" }
    let body = {query: ("query($name: String!) { featureFlag(name: $name) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "featureFlag" }
}

# Evaluates a feature flag for the current user Returns null if feature flag does not exist
#
# operationId: evaluateFeatureFlag
export def "query evaluate-feature-flag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  flag_name: string
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"flagName": $flag_name} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let body = {query: "query($flagName: String!) { evaluateFeatureFlag(flagName: $flagName) }", variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "evaluateFeatureFlag" }
}

# Evaluates multiple feature flags for the current user.
#
# operationId: evaluateFeatureFlags
export def "query evaluate-feature-flags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  flag_names: string
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"flagNames": $flag_names} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "name value" }
    let body = {query: ("query($flagNames: [String!]!) { evaluateFeatureFlags(flagNames: $flagNames) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "evaluateFeatureFlags" }
}

# Retrieve all previously evaluated feature flags for the current user.  DEPRECATED: We will remove this query with Sourcegraph 6.3. Use `evaluateFeatureFlags` to get the feature flags for the current user instead. We will stop to cache information about previously evaluated feature flags.
#
# DEPRECATED
# operationId: evaluatedFeatureFlags
@deprecated "use evaluateFeatureFlags instead"
export def "query evaluated-feature-flags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "name value" }
    let body = {query: ("query { evaluatedFeatureFlags { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "evaluatedFeatureFlags" }
}

# Retrieve the value of a feature flag for the organization
#
# operationId: organizationFeatureFlagValue
export def "query organization-feature-flag-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  org_id: string
  flag_name: string
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"orgID": $org_id, "flagName": $flag_name} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let body = {query: "query($orgID: ID!, $flagName: String!) { organizationFeatureFlagValue(orgID: $orgID, flagName: $flagName) }", variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "organizationFeatureFlagValue" }
}

# Retrieve all organization feature flag overrides for the current user
#
# operationId: organizationFeatureFlagOverrides
export def "query organization-feature-flag-overrides" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id value" }
    let body = {query: ("query { organizationFeatureFlagOverrides { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "organizationFeatureFlagOverrides" }
}

# Retrieves the temporary settings for the current user.
#
# operationId: temporarySettings
export def "query temporary-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "contents" }
    let body = {query: ("query { temporarySettings { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "temporarySettings" }
}

# Returns recently received webhooks across all external services, optionally limiting the returned values to only those that didn't match any external service.  Only site admins can access this field.
#
# operationId: webhookLogs
export def "query webhook-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int # Returns the first n webhook logs.
  --after: string # Opaque pagination cursor.
  --only-errors: string@bool-completer # Only include webhook logs that resulted in errors.
  --only-unmatched: string@bool-completer # Only include webhook logs that were not matched to an external service.
  --since: string # Only include webhook logs on or after this time.
  --until: string # Only include webhook logs on or before this time.
  --webhook-id: string # Only include webhook logs of given webhook ID.
  --legacy-only: string@bool-completer # Only include webhook logs that have no webhook ID set.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first, "after": $after, "onlyErrors": $only_errors, "onlyUnmatched": $only_unmatched, "since": $since, "until": $until, "webhookID": $webhook_id, "legacyOnly": $legacy_only} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($first: Int, $after: String, $onlyErrors: Boolean, $onlyUnmatched: Boolean, $since: DateTime, $until: DateTime, $webhookID: ID, $legacyOnly: Boolean) { webhookLogs(first: $first, after: $after, onlyErrors: $onlyErrors, onlyUnmatched: $onlyUnmatched, since: $since, until: $until, webhookID: $webhookID, legacyOnly: $legacyOnly) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "webhookLogs" }
}

# Get a log of the latest outbound external requests. Only available to site admins.
#
# operationId: outboundRequests
export def "query outbound-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int # Returns the first n log items. If omitted then it returns all of them.
  --after: string # Opaque pagination cursor.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first, "after": $after} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($first: Int, $after: String) { outboundRequests(first: $first, after: $after) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "outboundRequests" }
}

# Get a list of background jobs that are currently known in the system.
#
# operationId: backgroundJobs
export def "query background-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int # Returns the first n jobs. If omitted then it returns all of them.
  --after: string # Opaque pagination cursor.
  --recent-run-count: int # The maximum number of recent runs to return for each routine.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first, "after": $after, "recentRunCount": $recent_run_count} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($first: Int, $after: String, $recentRunCount: Int) { backgroundJobs(first: $first, after: $after, recentRunCount: $recentRunCount) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "backgroundJobs" }
}

# EXPERIMENTAL: Get invitation based on the JWT in the invitation URL
#
# operationId: invitationByToken
export def "query invitation-by-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  token: string # The token that uniquely identifies the invitation
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"token": $token} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id recipientEmail createdAt notifiedAt respondedAt responseType respondURL revokedAt expiresAt isVerifiedEmail" }
    let body = {query: ("query($token: String!) { invitationByToken(token: $token) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "invitationByToken" }
}

# Lists webhooks. Only available to site admins. If no kind is given, it returns all webhooks. If first is omitted, 20 items are returned
#
# operationId: webhooks
export def "query webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int # Returns the first n webhooks from the list.
  --after: string # Opaque pagination cursor.
  --kind: string@kind-completer # Optionally filter by kind.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first, "after": $after, "kind": $kind} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($first: Int, $after: String, $kind: ExternalServiceKind) { webhooks(first: $first, after: $after, kind: $kind) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "webhooks" }
}

# List slow GraphQL requests that were recently captured (requires site-admin permissions).
#
# operationId: slowRequests
export def "query slow-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --after: string # Opaque pagnination cursor.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"after": $after} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($after: String) { slowRequests(after: $after) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "slowRequests" }
}

# Roles returns all the roles in the database that matches the arguments.
#
# operationId: roles
export def "query roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int # The limit argument for forward pagination.
  --last: int # The limit argument for backward pagination.
  --after: string # The cursor argument for forward pagination.
  --before: string # The cursor argument for backward pagination.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first, "last": $last, "after": $after, "before": $before} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($first: Int, $last: Int, $after: String, $before: String) { roles(first: $first, last: $last, after: $after, before: $before) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "roles" }
}

# This returns all permissions in a paginated format.
#
# operationId: permissions
export def "query permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int # The limit argument for forward pagination.
  --last: int # The limit argument for backward pagination.
  --after: string # The cursor argument for forward pagination.
  --before: string # The cursor argument for backward pagination.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first, "last": $last, "after": $after, "before": $before} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($first: Int, $last: Int, $after: String, $before: String) { permissions(first: $first, last: $last, after: $after, before: $before) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "permissions" }
}

# Returns information pertaining to all gitserver instances associated with this Sourcegraph instance.  Site-admin only.
#
# operationId: gitservers
export def "query gitservers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query { gitservers { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "gitservers" }
}

# Returns information pertaining to all indexed search instances associated with this Sourcegraph instance.  Site-admin only.
#
# operationId: indexedSearchInstances
export def "query indexed-search-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query { indexedSearchInstances { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "indexedSearchInstances" }
}

# Returns the current instance settings configuration (external URL, CORS origins, branding, HTML injection). Only site admins may query this.
#
# operationId: instanceSettingsConfiguration
export def "query instance-settings-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "externalURL corsOrigin htmlHeadTop htmlHeadBottom htmlBodyTop htmlBodyBottom" }
    let body = {query: ("query { instanceSettingsConfiguration { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "instanceSettingsConfiguration" }
}

# The list of all globally available executor secrets.
#
# operationId: executorSecrets
export def "query executor-secrets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  scope: string@scope-completer # The scope for which secrets shall be returned.
  --first: int # Only return N records.
  --after: string # Opaque cursor for pagination.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"scope": $scope, "first": $first, "after": $after} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($scope: ExecutorSecretScope!, $first: Int, $after: String) { executorSecrets(scope: $scope, first: $first, after: $after) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "executorSecrets" }
}

# Lists the container registries configured in a DOCKER_AUTH_CONFIG executor secret. Credential values themselves are never returned. Returns an empty list when the target namespace has no DOCKER_AUTH_CONFIG secret. `namespace` may be a User ID or an Org ID; non-admins may only target their own user namespace or an org they belong to. When omitted, the site-wide (global) secret is read; this is restricted to site admins.
#
# operationId: dockerRegistryCredentials
export def "query docker-registry-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --namespace: string # The namespace whose DOCKER_AUTH_CONFIG secret should be inspected. May be a User ID or an Org ID. Non-admins may only target their own user namespace or an org they belong to. When omitted, the site-wide (global) secret is read; this is restricted to site admins.
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"namespace": $namespace} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "registry" }
    let body = {query: ("query($namespace: ID) { dockerRegistryCredentials(namespace: $namespace) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "dockerRegistryCredentials" }
}

# Retrieve active executor compute instances.
#
# operationId: executors
export def "query executors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --qp-query: string # An (optional) search query that searches over the hostname, queue name, os, architecture, and version properties.
  --active: string@bool-completer # Whether to show only executors that have sent a heartbeat in the last fifteen minutes.
  --first: int # Returns the first n executors.
  --after: string # Opaque pagination cursor.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"query": $qp_query, "active": $active, "first": $first, "after": $after} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($query: String, $active: Boolean, $first: Int, $after: String) { executors(query: $query, active: $active, first: $first, after: $after) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "executors" }
}

# Returns true if executors have been configured on the Sourcegraph instance. This is based on heuristics and doesn't necessarily mean that they would be working.
#
# operationId: areExecutorsConfigured
export def "query are-executors-configured" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let body = {query: "query { areExecutorsConfigured }", variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "areExecutorsConfigured" }
}

# List access requests.
#
# operationId: accessRequests
export def "query access-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --status: string@status-completer
  --first: int # Returns the first n access requests from the list.
  --last: int
  --after: string
  --before: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"status": $status, "first": $first, "last": $last, "after": $after, "before": $before} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($status: AccessRequestStatus, $first: Int, $last: Int, $after: String, $before: String) { accessRequests(status: $status, first: $first, last: $last, after: $after, before: $before) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "accessRequests" }
}

# Repository key-value pair metadata
#
# operationId: repoMeta
export def "query repo-meta" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query { repoMeta { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "repoMeta" }
}

# Find repositories where a specific contributor has made commits.
#
# operationId: contributorRepositories
export def "query contributor-repositories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  author: string # Author name or email address to search for.
  --first: int # Returns the first n repositories from the list.
  --after: string # Opaque pagination cursor.
  --min-commits: int # Minimum number of commits the author must have in a repository.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"author": $author, "first": $first, "after": $after, "minCommits": $min_commits} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($author: String!, $first: Int, $after: String, $minCommits: Int) { contributorRepositories(author: $author, first: $first, after: $after, minCommits: $minCommits) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "contributorRepositories" }
}

# List of all configured code hosts on this instance.  Site-admin only.
#
# operationId: codeHosts
export def "query code-hosts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int
  --after: string
  --search: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first, "after": $after, "search": $search} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "isMigrationDone totalCount" }
    let body = {query: ("query($first: Int, $after: String, $search: String) { codeHosts(first: $first, after: $after, search: $search) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "codeHosts" }
}

# All configured Slack bot integrations.
#
# operationId: slackConfigurations
export def "query slack-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id createdAt webhookVerifiedAt allowDeepSearch" }
    let body = {query: ("query { slackConfigurations { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "slackConfigurations" }
}

# Returns the outbound webhooks registered within Sourcegraph, optionally filtered by event type and scope. To filter by scope, event type is also required. If the event type and scope are both omitted, all webhooks are returned.  Only site admins have access to this query.
#
# operationId: outboundWebhooks
export def "query outbound-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int
  --after: string
  --event-type: string
  --scope: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first, "after": $after, "eventType": $event_type, "scope": $scope} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($first: Int, $after: String, $eventType: String, $scope: String) { outboundWebhooks(first: $first, after: $after, eventType: $eventType, scope: $scope) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "outboundWebhooks" }
}

# Returns all possible outbound webhook event types.  Only site admins have access to this query.
#
# operationId: outboundWebhookEventTypes
export def "query outbound-webhook-event-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "key description" }
    let body = {query: ("query { outboundWebhookEventTypes { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "outboundWebhookEventTypes" }
}

# The current user (if authenticated), or an unauthenticated visitor. On some Sourcegraph sites, unauthenticated visitors can access the GraphQL API and perform a limited set of actions.
#
# operationId: viewer
export def "query viewer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { " ... on User { id username email displayName avatarURL url settingsURL createdAt updatedAt siteAdmin builtinAuth serviceAccount unrestrictedRepoAccess tosAccepted hasVerifiedEmail viewerCanAdminister viewerCanChangeUsername databaseID namespaceName scimControlled viewerCanChangePrimaryEmail completionsQuotaOverride codeCompletionsQuotaOverride evaluateFeatureFlag }" }
    let body = {query: ("query { viewer { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "viewer" }
}

# Whether the viewer can change the visibility of a library item (such as a saved search or prompt) to public.
#
# operationId: viewerCanChangeLibraryItemVisibilityToPublic
export def "query viewer-can-change-library-item-visibility-to-public" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let body = {query: "query { viewerCanChangeLibraryItemVisibilityToPublic }", variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "viewerCanChangeLibraryItemVisibilityToPublic" }
}

# Fetches the result of an authentication provider validation. Results are one-time fetch only - calling twice returns null. Only site admins can access this.
#
# operationId: authProviderValidationResult
export def "query auth-provider-validation-result" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  validation_id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"validationID": $validation_id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "success errorMessage subject email username displayName groups" }
    let body = {query: ("query($validationID: String!) { authProviderValidationResult(validationID: $validationID) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "authProviderValidationResult" }
}

# Returns the current external TLS configuration with parsed certificate metadata. Only site admins may query this.
#
# operationId: externalTLSConfiguration
export def "query external-tls-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "insecureSkipVerify" }
    let body = {query: ("query { externalTLSConfiguration { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "externalTLSConfiguration" }
}

# List of notebooks exported as markdown. The notebooks feature has been removed, but this endpoint allows exporting existing notebook data.  This API will be removed in the future.  Only site admins can access this.
#
# operationId: notebookExports
export def "query notebook-exports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --owner: string # Filter by notebook owner (a user ID). If not provided, all notebooks are returned.
  --first: int # Returns the first n notebooks exports.
  --after: string # Opaque pagination cursor.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"owner": $owner, "first": $first, "after": $after} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($owner: ID, $first: Int, $after: String) { notebookExports(owner: $owner, first: $first, after: $after) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "notebookExports" }
}

# Reports on whether or not the caller has enough quota remaining to use the feature specified by the given SKU.  Note: This is used to drive UI gating (e.g., disabling a chat input if the instance doesn't have enough credits remaining, etc.)
#
# operationId: checkQuota
export def "query check-quota" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  sku: string@sku-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"sku": $sku} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "blocked" }
    let body = {query: ("query($sku: QuotaSKU!) { checkQuota(sku: $sku) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "checkQuota" }
}

# Query precise code intelligence indexes.
#
# operationId: preciseIndexes
export def "query precise-indexes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --repo: string # If supplied, only precise indexes for the given repository will be returned.
  --qp-query: string # If supplied, only precise indexes that match the given terms by their state, repository name, commit, root, and indexer fields will be returned..
  --states: string@states-completer # If supplied, only precise indexes in one of the provided states are returned.
  --indexer-key: string # If supplied, only precise indexes created by an indexer with the given key are returned.
  --index-source: string@index-source-completer # If supplied, only precise indexes of the given source are returned.
  --dependency-of: string # If supplied, only precise indexes that are a dependency of the specified index are returned.
  --dependent-of: string # If supplied, only precise indexes that are a dependent of the specified index are returned.
  --include-deleted: string@bool-completer # When specified, merges the list of existing uploads with data from uploads that have been deleted but for which audit logs still exist. Only makes sense when state filter is unset or equal to 'DELETED'.
  --first: int # If specified, this limits the number of results per request.
  --after: string # If specified, this indicates that the request should be paginated and to fetch results starting at this cursor.  A future request can be made for more results by passing in the 'PreciseIndexConnection.pageInfo.endCursor' that is returned.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repo": $repo, "query": $qp_query, "states": $states, "indexerKey": $indexer_key, "indexSource": $index_source, "dependencyOf": $dependency_of, "dependentOf": $dependent_of, "includeDeleted": $include_deleted, "first": $first, "after": $after} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($repo: ID, $query: String, $states: [PreciseIndexState!], $indexerKey: String, $indexSource: PreciseIndexSource, $dependencyOf: ID, $dependentOf: ID, $includeDeleted: Boolean, $first: Int, $after: String) { preciseIndexes(repo: $repo, query: $query, states: $states, indexerKey: $indexerKey, indexSource: $indexSource, dependencyOf: $dependencyOf, dependentOf: $dependentOf, includeDeleted: $includeDeleted, first: $first, after: $after) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "preciseIndexes" }
}

# Provides a summary of code intelligence on the instance.
#
# operationId: codeIntelSummary
export def "query code-intel-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "numRepositoriesWithCodeIntelligence" }
    let body = {query: ("query { codeIntelSummary { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "codeIntelSummary" }
}

# A list of unique indexer keys queryable via the `preciseIndexes.indexerKey` filter.
#
# operationId: indexerKeys
export def "query indexer-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --repo: string # If supplied, only indexers associated with the given repository will be returned.
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repo": $repo} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let body = {query: "query($repo: ID) { indexerKeys(repo: $repo) }", variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "indexerKeys" }
}

# Return the currently set auto-indexing job inference script. Does not return the value stored in the environment variable or the default shipped scripts, only the value set via UI/GraphQL.
#
# operationId: codeIntelligenceInferenceScript
export def "query code-intelligence-inference-script" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let body = {query: "query { codeIntelligenceInferenceScript }", variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "codeIntelligenceInferenceScript" }
}

# Return (but do not enqueue) descriptions of auto indexing jobs at the current revision.
#
# operationId: inferAutoIndexJobsForRepo
export def "query infer-auto-index-jobs-for-repo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repository: string
  --rev: string
  --script: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repository": $repository, "rev": $rev, "script": $script} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "inferenceOutput" }
    let body = {query: ("query($repository: ID!, $rev: String, $script: String) { inferAutoIndexJobsForRepo(repository: $repository, rev: $rev, script: $script) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "inferAutoIndexJobsForRepo" }
}

# Identify usages for either a semantic symbol, or the symbol(s) implied by a source range. Ordering and uniqueness guarantees: 1. The usages returned will already be de-duplicated. 2. Results are first grouped by provenance in the order precise, syntactic, then search-based. 3. Results for a single repository are contiguous. 4. Results for a single file are contiguous. Related: See `codeGraphData` on GitBlob.  EXPERIMENTAL: This API may make backwards-incompatible changes in the future.
#
# operationId: usagesForSymbol
# --symbol-name shape: {equals?: string}
# --symbol-provenance shape: {equals?: "PRECISE"|"SYNTACTIC"|"SEARCH_BASED"}
# --range-start shape: {line: int, character: int}
# --range-end shape: {line: int, character: int}
export def "query usages-for-symbol" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int # When specified, indicates that this request should be paginated and the first N results (relative to the cursor) should be returned. i.e. how many results to return per page. May return more results than requested to complete usages for a file.
  --after: string # When specified, indicates that this request should be paginated and to fetch results starting at this cursor. A future request can be made for more results by passing in the 'UsageConnection.pageInfo.endCursor' that is returned.
  --symbol-name: record # Describes how the symbol name should be compared. — shape: {equals?: string}
  --symbol-provenance: record # Describes the provenance of the symbol. This value should be based on the provenance value obtained from the CodeGraphData type. — shape: {equals?: "PRECISE"|"SYNTACTIC"|"SEARCH_BASED"}
  --range-repository: string # The repository containing the initial usage for a symbol.
  --range-revision: string # The revision containing the initial usage for the symbol.  Defaults to HEAD of the default branch if not specified.
  --range-path: string # The path containing the initial usage for the symbol.
  --range-start: record # Start position of the range (inclusive) — shape: {line: int, character: int}
  --range-end: record # End position of the range (exclusive) — shape: {line: int, character: int}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let symbol = ({"name": $symbol_name, "provenance": $symbol_provenance} | compact | if ($in | is-empty) { null } else { $in })
  let range = ({"repository": $range_repository, "revision": $range_revision, "path": $range_path, "start": $range_start, "end": $range_end} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"first": $first, "after": $after, "symbol": $symbol, "range": $range} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($symbol: SymbolComparator, $range: RangeInput!, $first: Int, $after: String) { usagesForSymbol(first: $first, after: $after, symbol: $symbol, range: $range) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "usagesForSymbol" }
}

# Returns the current managed indexing settings for the Sourcegraph instance. These settings control whether precise and syntactic indexing are enabled via the "[Sourcegraph Managed]" global policy.
#
# operationId: managedIndexingSettings
export def "query managed-indexing-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "preciseIndexingEnabled syntacticIndexingEnabled" }
    let body = {query: ("query { managedIndexingSettings { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "managedIndexingSettings" }
}

# Returns code intelligence configuration policies for precise and syntactic indexing that control data retention and (if enabled) precise auto-indexing behavior.
#
# operationId: codeIntelligenceConfigurationPolicies
export def "query code-intelligence-configuration-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --repository: string # If repository is supplied, then only the configuration policies that apply to repository are returned. If repository is not supplied, then all policies are returned.
  --qp-query: string # An (optional) search query that searches over the name property.
  --for-data-retention: string@bool-completer # If set to true, then only configuration policies with SCIP data retention enabled are returned. If set to false, then configuration policies with SCIP data retention enabled are filtered out.
  --for-precise-indexing: string@bool-completer # If set to true, then only configuration policies with precise indexing enabled are returned. If set to false, then configuration policies with precise indexing enabled are filtered out.
  --for-syntactic-indexing: string@bool-completer # If set to true, then only configuration policies with syntactic indexing enabled are returned. If set to false, then configuration policies with syntactic indexing enabled are filtered out.
  --protected: string@bool-completer # If set to true, then only protected configuration policies are returned. If set to false, then only un-protected configuration policies are returned. If unset, policies are returned regardless if they're protected or not.
  --first: int # When specified, indicates that this request should be paginated and the first N results (relative to the cursor) should be returned. i.e. how many results to return per page.
  --after: string # When specified, indicates that this request should be paginated and to fetch results starting at this cursor.  A future request can be made for more results by passing in the 'CodeIntelligenceConfigurationPolicyConnection.pageInfo.endCursor' that is returned.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repository": $repository, "query": $qp_query, "forDataRetention": $for_data_retention, "forPreciseIndexing": $for_precise_indexing, "forSyntacticIndexing": $for_syntactic_indexing, "protected": $protected, "first": $first, "after": $after} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($repository: ID, $query: String, $forDataRetention: Boolean, $forPreciseIndexing: Boolean, $forSyntacticIndexing: Boolean, $protected: Boolean, $first: Int, $after: String) { codeIntelligenceConfigurationPolicies(repository: $repository, query: $query, forDataRetention: $forDataRetention, forPreciseIndexing: $forPreciseIndexing, forSyntacticIndexing: $forSyntacticIndexing, protected: $protected, first: $first, after: $after) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "codeIntelligenceConfigurationPolicies" }
}

# The set of repositories that match the given glob pattern. This resolver is used by the UI to preview what repositories match a code intelligence policy in a given repository.
#
# operationId: previewRepositoryFilter
export def "query preview-repository-filter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  patterns: string # A set of patterns matching the name of the matching repository.
  --first: int # When specified, indicates that this request should return the first N items.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"patterns": $patterns, "first": $first} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount matchesAllRepos limit totalMatches" }
    let body = {query: ("query($patterns: [String!]!, $first: Int) { previewRepositoryFilter(patterns: $patterns, first: $first) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "previewRepositoryFilter" }
}

# Return dashboards visible to the authenticated user.
#
# operationId: insightsDashboards
export def "query insights-dashboards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int
  --after: string
  --id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first, "after": $after, "id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($first: Int, $after: String, $id: ID) { insightsDashboards(first: $first, after: $after, id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "insightsDashboards" }
}

# Return all insight views visible to the authenticated user.
#
# operationId: insightViews
# --series-display-options-sortOptions shape: {mode: "RESULT_COUNT"|"LEXICOGRAPHICAL"|"DATE_ADDED", direction: "ASC"|"DESC"}
export def "query insight-views" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int
  --after: string
  --id: string
  --exclude-ids: string # Allow you to exclude subset of insights by their ids.
  --find: string # Allow you to search insight views by their title or data series labels.
  --is-frozen: string@bool-completer
  --filters-includeRepoRegex: string # A regex string for which to include repositories in a filter.
  --filters-excludeRepoRegex: string # A regex string for which to exclude repositories in a filter.
  --filters-searchContexts: string # A list of query based search contexts to include in the filters for the view.
  --series-display-options-sortOptions: record # Sort options for the series. — shape: {mode: "RESULT_COUNT"|"LEXICOGRAPHICAL"|"DATE_ADDED", direction: "ASC"|"DESC"}
  --series-display-options-limit: int # Max number of series to return.
  --series-display-options-numSamples: int # Max number of samples to return.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let filters = ({"includeRepoRegex": $filters_includeRepoRegex, "excludeRepoRegex": $filters_excludeRepoRegex, "searchContexts": $filters_searchContexts} | compact | if ($in | is-empty) { null } else { $in })
  let seriesDisplayOptions = ({"sortOptions": $series_display_options_sortOptions, "limit": $series_display_options_limit, "numSamples": $series_display_options_numSamples} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"first": $first, "after": $after, "id": $id, "excludeIds": $exclude_ids, "find": $find, "isFrozen": $is_frozen, "filters": $filters, "seriesDisplayOptions": $seriesDisplayOptions} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($first: Int, $after: String, $id: ID, $excludeIds: [ID!], $find: String, $isFrozen: Boolean, $filters: InsightViewFiltersInput, $seriesDisplayOptions: SeriesDisplayOptionsInput) { insightViews(first: $first, after: $after, id: $id, excludeIds: $excludeIds, find: $find, isFrozen: $isFrozen, filters: $filters, seriesDisplayOptions: $seriesDisplayOptions) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "insightViews" }
}

# Generate an ephemeral time series for a Search based code insight, generally for the purposes of live preview.
#
# operationId: searchInsightLivePreview
# --input-repositoryScope shape: {repositories: string, repositoryCriteria?: string}
# --input-timeScope shape: {stepInterval?: record}
export def "query search-insight-live-preview" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-query: string # The query string.
  --input-label: string # The desired label for the series. Will be overwritten when series are dynamically generated.
  --input-repositoryScope: record # The scope of repositories. — shape: {repositories: string, repositoryCriteria?: string}
  --input-timeScope: record # The scope of time. — shape: {stepInterval?: record}
  --input-generatedFromCaptureGroups: string@bool-completer # Whether or not to generate the timeseries results from the query capture groups.
  --input-groupBy: string@input-groupBy-completer # Use this field to specify a compute insight.
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"query": $input_query, "label": $input_label, "repositoryScope": $input_repositoryScope, "timeScope": $input_timeScope, "generatedFromCaptureGroups": $input_generatedFromCaptureGroups, "groupBy": $input_groupBy} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "label" }
    let body = {query: ("query($input: SearchInsightLivePreviewInput!) { searchInsightLivePreview(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "searchInsightLivePreview" }
}

# Generate an ephemeral set of time series for a code insight, generally for the purposes of live preview.
#
# operationId: searchInsightPreview
# --input-repositoryScope shape: {repositories: string, repositoryCriteria?: string}
# --input-timeScope shape: {stepInterval?: record}
# --input-series item shape: {query: string, label: string, generatedFromCaptureGroups: bool, groupBy?: "REPO"|"LANG"|"PATH"|"AUTHOR"|"DATE"}
export def "query search-insight-preview" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-repositoryScope: record # The scope of repositories. — shape: {repositories: string, repositoryCriteria?: string}
  --input-timeScope: record # The scope of time. — shape: {stepInterval?: record}
  --input-series: record # The series to generate previews for — item shape: {query: string, label: string, generatedFromCaptureGroups: bool, groupBy?: "REPO"|"LANG"|"PATH"|"AUTHOR"|"DATE"}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"repositoryScope": $input_repositoryScope, "timeScope": $input_timeScope, "series": $input_series} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "label" }
    let body = {query: ("query($input: SearchInsightPreviewInput!) { searchInsightPreview(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "searchInsightPreview" }
}

# Generate an ephemeral set of time series for a repository statistics insight, generally for the purposes of live preview.
#
# operationId: inventoryStatsPreview
# --input-repositoryScope shape: {repositories: string, repositoryCriteria?: string}
# --input-timeScope shape: {stepInterval?: record}
# --input-series item shape: {metric: "LINES_OF_CODE"|"BYTES"|"FILE_COUNT", label?: string, groupBy?: "REPO"|"LANG"|"PATH"|"AUTHOR"|"DATE"}
export def "query inventory-stats-preview" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-repositoryScope: record # The scope of repositories. — shape: {repositories: string, repositoryCriteria?: string}
  --input-timeScope: record # The scope of time. — shape: {stepInterval?: record}
  --input-series: record # The series to generate previews for — item shape: {metric: "LINES_OF_CODE"|"BYTES"|"FILE_COUNT", label?: string, groupBy?: "REPO"|"LANG"|"PATH"|"AUTHOR"|"DATE"}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"repositoryScope": $input_repositoryScope, "timeScope": $input_timeScope, "series": $input_series} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "label" }
    let body = {query: ("query($input: InventoryStatsPreviewInput!) { inventoryStatsPreview(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "inventoryStatsPreview" }
}

# Retrieve information about queued insights series and their breakout by status. Restricted to admins only.
#
# operationId: insightSeriesQueryStatus
export def "query insight-series-query-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "seriesId query enabled errored completed processing failed queued" }
    let body = {query: ("query { insightSeriesQueryStatus { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "insightSeriesQueryStatus" }
}

# Retrieve information about an insight view and its status. Restricted to admins only.
#
# operationId: insightViewDebug
export def "query insight-view-debug" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "raw" }
    let body = {query: ("query($id: ID!) { insightViewDebug(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "insightViewDebug" }
}

# Validates a query for determining insight scope and returns the number of repositories it matches for the caller.
#
# operationId: validateScopedInsightQuery
export def "query validate-scoped-insight-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  query: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"query": $query} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "query isValid invalidReason" }
    let body = {query: ("query($query: String!) { validateScopedInsightQuery(query: $query) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "validateScopedInsightQuery" }
}

# Returns the number of repositories matched given a valid query.
#
# operationId: previewRepositoriesFromQuery
export def "query preview-repositories-from-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  query: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"query": $query} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "query numberOfRepositories" }
    let body = {query: ("query($query: String!) { previewRepositoriesFromQuery(query: $query) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "previewRepositoriesFromQuery" }
}

# Fetch information related to the queue of backfilling insights.
#
# operationId: insightAdminBackfillQueue
export def "query insight-admin-backfill-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int # Returns the first n queue items from the list.
  --last: int # Returns the last n queue items from the list.
  --after: string # An opaque cursor that is used for pagination.
  --before: string # An opaque cursor that is used for pagination.
  --order-by: string@order-by-completer-1 # How to order the list.
  --descending: string@bool-completer # Sort direction.
  --states: string@states-completer-1 # List of states to filter list by.
  --text-search: string # Text to filter the list, checking the Insight Title and Series Label
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first, "last": $last, "after": $after, "before": $before, "orderBy": $order_by, "descending": $descending, "states": $states, "textSearch": $text_search} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($first: Int, $last: Int, $after: String, $before: String, $orderBy: BackfillQueueOrderBy, $descending: Boolean, $states: [InsightQueueItemState!], $textSearch: String) { insightAdminBackfillQueue(first: $first, last: $last, after: $after, before: $before, orderBy: $orderBy, descending: $descending, states: $states, textSearch: $textSearch) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "insightAdminBackfillQueue" }
}

# The repositories a user is authorized to access with the given permission. This isn’t defined in the User type because we store permissions for users that don’t yet exist (i.e. late binding). Only one of "username" or "email" is required to identify a user.
#
# operationId: authorizedUserRepositories
export def "query authorized-user-repositories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --username: string # The username.
  --email: string # One of the email addresses.
  --perm: string@perm-completer # Permission that the user has on the repositories.
  first: int # Number of repositories to return after the given cursor.
  --after: string # Opaque pagination cursor.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"username": $username, "email": $email, "perm": $perm, "first": $first, "after": $after} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($username: String, $email: String, $perm: RepositoryPermission, $first: Int!, $after: String) { authorizedUserRepositories(username: $username, email: $email, perm: $perm, first: $first, after: $after) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "authorizedUserRepositories" }
}

# Returns a list of usernames or emails that have associated pending permissions. The returned list can be used to query authorizedUserRepositories for pending permissions.
#
# operationId: usersWithPendingPermissions
export def "query users-with-pending-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let body = {query: "query { usersWithPendingPermissions }", variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "usersWithPendingPermissions" }
}

# Returns a list of recent permissions sync jobs for a given set of parameters.
#
# operationId: permissionsSyncJobs
export def "query permissions-sync-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int # Number of jobs returned. Maximum number of returned jobs is 500. Up to 100 jobs are returned by default.
  --last: int # The number of nodes to return starting from the end (latest). Note: Use either last or first (see above) in the query. Setting both will return an error.
  --after: string # Opaque pagination cursor to be used when paginating forwards that may be also used in conjunction with "first" to return the first N nodes.
  --before: string # Opaque pagination cursor to be used when paginating backwards that may be also used in conjunction with "last" to return the last N nodes.
  --reason-group: string@reason-group-completer # Optional filter for PermissionsSyncJobReasonGroup.
  --state: string@state-completer # Optional filter for PermissionsSyncJobState.
  --search-type: string@search-type-completer # Type of search for permissions sync jobs: user or repository.
  --qp-query: string # Term used to search for permissions sync jobs.
  --user-id: string # Optional filter to find permissions sync jobs for a user. Please provide either this or repoID, but not both.
  --repo-id: string # Optional filter to find permissions sync jobs for a repository. Please provide either this or userID, but not both.
  --partial: string@bool-completer # Optional filter to filter only partially successful sync jobs.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first, "last": $last, "after": $after, "before": $before, "reasonGroup": $reason_group, "state": $state, "searchType": $search_type, "query": $qp_query, "userID": $user_id, "repoID": $repo_id, "partial": $partial} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($first: Int, $last: Int, $after: String, $before: String, $reasonGroup: PermissionsSyncJobReasonGroup, $state: PermissionsSyncJobState, $searchType: PermissionsSyncJobsSearchType, $query: String, $userID: ID, $repoID: ID, $partial: Boolean) { permissionsSyncJobs(first: $first, last: $last, after: $after, before: $before, reasonGroup: $reasonGroup, state: $state, searchType: $searchType, query: $query, userID: $userID, repoID: $repoID, partial: $partial) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "permissionsSyncJobs" }
}

# Returns various permissions syncing statistics.
#
# operationId: permissionsSyncingStats
export def "query permissions-syncing-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "queueSize usersWithLatestJobFailing reposWithLatestJobFailing usersWithNoPermissions reposWithNoPermissions usersWithStalePermissions reposWithStalePermissions" }
    let body = {query: ("query { permissionsSyncingStats { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "permissionsSyncingStats" }
}

# Returns a list of Bitbucket Project permissions sync jobs for a given set of parameters.
#
# operationId: bitbucketProjectPermissionJobs
export def "query bitbucket-project-permission-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --project-keys: string # Bitbucket project keys which sync jobs are queried
  --status: string # Job status, one of the following: queued, processing, completed, errored, failed.
  --count: int # Number of jobs returned. Maximum number of returned jobs is 500. 100 jobs are returned by default.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"projectKeys": $project_keys, "status": $status, "count": $count} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($projectKeys: [String!], $status: String, $count: Int) { bitbucketProjectPermissionJobs(projectKeys: $projectKeys, status: $status, count: $count) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "bitbucketProjectPermissionJobs" }
}

# List of auth provider wizard drafts for the current user.
#
# operationId: authProviderWizardDrafts
export def "query auth-provider-wizard-drafts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int # The limit argument for pagination.
  --after: string # Cursor for pagination.
  --wizard-type: string@wizard-type-completer # Filter by wizard type (e.g., "auth-provider-saml", "auth-provider-openidconnect").
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first, "after": $after, "wizardType": $wizard_type} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($first: Int, $after: String, $wizardType: AuthWizardType) { authProviderWizardDrafts(first: $first, after: $after, wizardType: $wizardType) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "authProviderWizardDrafts" }
}

# List of saved searches.
#
# operationId: savedSearches
export def "query saved-searches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --qp-query: string # Filter saved searches by text in their description and query.
  --owner: string # Filter by saved search owner (a namespace, either a user or organization).
  --viewer-is-affiliated: string@bool-completer # Filter to only saved searches owned by the viewer or one of viewer's organizations. All public saved searches are also included. If null or false, no such filtering is performed.
  --include-drafts: string@bool-completer # Whether to include draft saved searches.
  --first: int # The limit argument for forward pagination.
  --last: int # The limit argument for backward pagination.
  --after: string # The cursor argument for forward pagination.
  --before: string # The cursor argument for backward pagination.
  --order-by: string@order-by-completer-2 # The field to sort by.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"query": $qp_query, "owner": $owner, "viewerIsAffiliated": $viewer_is_affiliated, "includeDrafts": $include_drafts, "first": $first, "last": $last, "after": $after, "before": $before, "orderBy": $order_by} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($query: String, $owner: ID, $viewerIsAffiliated: Boolean, $includeDrafts: Boolean, $first: Int, $last: Int, $after: String, $before: String, $orderBy: SavedSearchesOrderBy) { savedSearches(query: $query, owner: $owner, viewerIsAffiliated: $viewerIsAffiliated, includeDrafts: $includeDrafts, first: $first, last: $last, after: $after, before: $before, orderBy: $orderBy) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "savedSearches" }
}

# All configured GitHub Apps, optionally filtered by the domain in which they are used. 🚨 SECURITY: Requires site-admin.
#
# operationId: gitHubApps
export def "query git-hub-apps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --domain: string@domain-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"domain": $domain} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($domain: GitHubAppDomain) { gitHubApps(domain: $domain) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "gitHubApps" }
}

# GitHub Apps configured as Batch Changes credentials for a user. 🚨 SECURITY: Requires site-admin or the same user.
#
# operationId: batchChangesUserCredentialGitHubApps
export def "query batch-changes-user-credential-git-hub-apps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"user": $user} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($user: ID!) { batchChangesUserCredentialGitHubApps(user: $user) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "batchChangesUserCredentialGitHubApps" }
}

# Looks up a GitHub App by its AppID and BaseURL. 🚨 SECURITY: Requires site-admin.
#
# operationId: gitHubAppByAppID
export def "query git-hub-app-by-app-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  app_id: int
  base_url: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"appID": $app_id, "baseURL": $base_url} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id appID name domain kind slug baseURL appURL clientID clientSecret logo createdAt updatedAt missingRequiredPermissions" }
    let body = {query: ("query($appID: Int!, $baseURL: String!) { gitHubAppByAppID(appID: $appID, baseURL: $baseURL) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "gitHubAppByAppID" }
}

# Checks whether the given feature is enabled on Sourcegraph.
#
# operationId: enterpriseLicenseHasFeature
export def "query enterprise-license-has-feature" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  feature: string
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"feature": $feature} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let body = {query: "query($feature: String!) { enterpriseLicenseHasFeature(feature: $feature) }", variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "enterpriseLicenseHasFeature" }
}

# Validates a license key and returns information about it without applying it. This allows previewing license details before updating the site configuration. Only accessible to site admins.
#
# operationId: previewLicenseKey
export def "query preview-license-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  license_key: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"licenseKey": $license_key} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "error plan userCount expiresAt tags" }
    let body = {query: ("query($licenseKey: String!) { previewLicenseKey(licenseKey: $licenseKey) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "previewLicenseKey" }
}

# All available user-defined search contexts. Excludes auto-defined contexts.
#
# operationId: searchContexts
export def "query search-contexts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int # Returns the first n search contexts from the list.
  --after: string # Opaque pagination cursor.
  --qp-query: string # Free-form query to filter search contexts by spec, namespace, or name.
  --namespaces: string # Include search contexts matching the provided namespaces. A union of all matching search contexts is returned. ID can either be a user ID, org ID, or nil to match instance-level contexts. Empty namespaces list defaults to returning all available search contexts. Example: `namespaces: [user1, org1, org2, nil]` will return search contexts created by user1 + contexts created by org1 + contexts created by org2 + all instance-level contexts.
  --order-by: string@order-by-completer-3 # Sort field. Despite the value, the results are always sorted with the global context first, user's default context next, followed by the user's starred contexts, followed by the rest of the contexts. This controls the order of these internal groups.
  --descending: string@bool-completer # Sort direction.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first, "after": $after, "query": $qp_query, "namespaces": $namespaces, "orderBy": $order_by, "descending": $descending} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($first: Int, $after: String, $query: String, $namespaces: [ID], $orderBy: SearchContextsOrderBy, $descending: Boolean) { searchContexts(first: $first, after: $after, query: $query, namespaces: $namespaces, orderBy: $orderBy, descending: $descending) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "searchContexts" }
}

# Fetch search context by spec (global, @username, @username/ctx, etc.).
#
# operationId: searchContextBySpec
export def "query search-context-by-spec" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  spec: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"spec": $spec} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id databaseID name description spec autoDefined query public updatedAt viewerCanManage viewerHasAsDefault viewerHasStarred" }
    let body = {query: ("query($spec: String!) { searchContextBySpec(spec: $spec) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "searchContextBySpec" }
}

# Determines whether the search context is within the set of search contexts available to the current user. The set consists of contexts created by the user, contexts created by the users' organizations, and instance-level contexts.
#
# operationId: isSearchContextAvailable
export def "query is-search-context-available" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  spec: string
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"spec": $spec} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let body = {query: "query($spec: String!) { isSearchContextAvailable(spec: $spec) }", variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "isSearchContextAvailable" }
}

# Gets the default search context for the current user. This context is guaranteed to be available to the user.
#
# operationId: defaultSearchContext
export def "query default-search-context" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id databaseID name description spec autoDefined query public updatedAt viewerCanManage viewerHasAsDefault viewerHasStarred" }
    let body = {query: ("query { defaultSearchContext { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "defaultSearchContext" }
}

# Computes valus from search results.
#
# operationId: compute
export def "query compute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --qp-query: string # The search query.
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"query": $qp_query} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename ... on ComputeMatchContext { commit path } ... on ComputeText { commit path kind value }" }
    let body = {query: ("query($query: String) { compute(query: $query) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "compute" }
}

# Returns information about aggregating the potential results of a search query.
#
# operationId: searchQueryAggregate
export def "query search-query-aggregate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  query: string
  pattern_type: string@pattern-type-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"query": $query, "patternType": $pattern_type} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($query: String!, $patternType: SearchPatternType!) { searchQueryAggregate(query: $query, patternType: $patternType) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "searchQueryAggregate" }
}

# Get a list of context related to the query from a set of repositories. This is the first list from getCodyContextAlternatives
#
# DEPRECATED
# operationId: getCodyContext
@deprecated "Use the search API instead with `patterntype=nls`"
export def "query get-cody-context" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repos: string # The repositories to search.
  --file-patterns: string # An optional list of file patterns used to filter the results. The patterns are regex strings. For a file chunk to be returned a context result, the path must match at least one of these patterns.
  query: string # A natural language query string.
  code_results_count: int # The number of code results to return. NOTE: The API no longer searches text and code separately, and instead just collects `codeResultsCount + textResultsCount` total results.
  text_results_count: int # The number of text results to return. NOTE: The API no longer searches text and code separately, and instead just collects `codeResultsCount + textResultsCount` total results.
  --version: string # The version number of the context API
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repos": $repos, "filePatterns": $file_patterns, "query": $query, "codeResultsCount": $code_results_count, "textResultsCount": $text_results_count, "version": $version} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename ... on FileChunkContext { startLine endLine chunkContent }" }
    let body = {query: ("query($repos: [ID!]!, $filePatterns: [String!], $query: String!, $codeResultsCount: Int!, $textResultsCount: Int!, $version: String) { getCodyContext(repos: $repos, filePatterns: $filePatterns, query: $query, codeResultsCount: $codeResultsCount, textResultsCount: $textResultsCount, version: $version) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "getCodyContext" }
}

# Get lists of context related to the query from a set of repositories.
#
# DEPRECATED
# operationId: getCodyContextAlternatives
@deprecated "Use the search API instead with `patterntype=nls`"
export def "query get-cody-context-alternatives" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repos: string # The repositories to search.
  --file-patterns: string # An optional list of file patterns used to filter the results. The patterns are regex strings. For a file chunk to be returned a context result, the path must match at least one of these patterns.
  query: string # A natural language query string.
  code_results_count: int # The number of code results to return.
  text_results_count: int # The number of text results to return. Text results contain Markdown files and similar file types primarily used for writing documentation.
  --version: string # The version number of the context API
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repos": $repos, "filePatterns": $file_patterns, "query": $query, "codeResultsCount": $code_results_count, "textResultsCount": $text_results_count, "version": $version} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($repos: [ID!]!, $filePatterns: [String!], $query: String!, $codeResultsCount: Int!, $textResultsCount: Int!, $version: String) { getCodyContextAlternatives(repos: $repos, filePatterns: $filePatterns, query: $query, codeResultsCount: $codeResultsCount, textResultsCount: $textResultsCount, version: $version) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "getCodyContextAlternatives" }
}

# EXPERIMENTAL: Fetches the relevant context for a mentioned URL
#
# operationId: urlMentionContext
export def "query url-mention-context" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  url: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"url": $url} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "title content" }
    let body = {query: ("query($url: String!) { urlMentionContext(url: $url) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "urlMentionContext" }
}

# Returns a string of completion responses
#
# DEPRECATED
# operationId: completions
# --input-messages item shape: {speaker: "HUMAN"|"ASSISTANT", text: string}
@deprecated "Consumers should use non graphql endpoints when communicating the completions endpoint"
export def "query completions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --fast: string@bool-completer
  --input-messages: record # List of conversation messages — item shape: {speaker: "HUMAN"|"ASSISTANT", text: string}
  --input-temperature: float # Temperature for sampling - higher means more random completions
  --input-maxTokensToSample: int # Maximum number of tokens to sample
  --input-topK: int # Number of highest probability completions to return
  --input-topP: int # Probability threshold for inclusion in results
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"messages": $input_messages, "temperature": $input_temperature, "maxTokensToSample": $input_maxTokensToSample, "topK": $input_topK, "topP": $input_topP} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"fast": $fast, "input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let body = {query: "query($input: CompletionsInput!, $fast: Boolean) { completions(fast: $fast, input: $input) }", variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "completions" }
}

# Returns an entitlement by its ID.
#
# operationId: entitlement
export def "query entitlement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name type limit window isDefault updatedAt" }
    let body = {query: ("query($id: ID!) { entitlement(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "entitlement" }
}

# Returns all entitlements in a paginated format.
#
# operationId: entitlements
export def "query entitlements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --type: string@type-completer # The type of the entitlement.
  --is-default: string@bool-completer # Whether this is the default entitlement for its type.
  --first: int # The limit argument for forward pagination.
  --last: int # The limit argument for backward pagination.
  --after: string # The cursor argument for forward pagination.
  --before: string # The cursor argument for backward pagination.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"type": $type, "isDefault": $is_default, "first": $first, "last": $last, "after": $after, "before": $before} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($type: EntitlementType, $isDefault: Boolean, $first: Int, $last: Int, $after: String, $before: String) { entitlements(type: $type, isDefault: $isDefault, first: $first, last: $last, after: $after, before: $before) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "entitlements" }
}

# EXPERIMENTAL: Searches the instances indexed code for code matching snippet.
#
# operationId: snippetAttribution
export def "query snippet-attribution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  snippet: string
  --first: int
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"snippet": $snippet, "first": $first} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount limitHit" }
    let body = {query: ("query($snippet: String!, $first: Int) { snippetAttribution(snippet: $snippet, first: $first) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "snippetAttribution" }
}

# Telemetry queries for "Event Logging Everywhere", aka a version 2 of existing event-logging/event-recording APIs.
#
# operationId: telemetry
export def "query telemetry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query { telemetry { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "telemetry" }
}

# External API queries for managing and introspecting external API services.
#
# operationId: externalAPI
export def "query external-api" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "openAPISchema" }
    let body = {query: ("query { externalAPI { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "externalAPI" }
}

# List of prompts, which are templates for chat prompts that can be shared and reused.
#
# operationId: prompts
export def "query prompts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --qp-query: string # Search prompts by name, description, or prompt template text.
  --owner: string # Filter by prompt owner (a namespace, either a user or organization).
  --viewer-is-affiliated: string@bool-completer # Filter to only prompts owned by the viewer or one of viewer's organizations. All public prompts are also included. If null or false, no such filtering is performed.
  --include-drafts: string@bool-completer # Whether to include draft prompts.
  --recommended-only: string@bool-completer # Whether to include only recommended prompts.
  --builtin-only: string@bool-completer # Whether to include only builtin prompts.
  --include-builtin: string@bool-completer # Whether to include builtin prompts.
  --include-viewer-drafts: string@bool-completer # Whether to include draft prompts owned by the viewer.
  --first: int # The limit argument for forward pagination.
  --last: int # The limit argument for backward pagination.
  --after: string # The cursor argument for forward pagination.
  --before: string # The cursor argument for backward pagination.
  --order-by: string@order-by-completer-4 # The field to sort by.
  --order-by-multiple: string@order-by-multiple-completer # The field to sort by multiple fields.
  --tags: string # Filter by tag IDs.
  --exclude: string # List of prompt IDs to exclude.
  --include: string # List of prompt IDs to include.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"query": $qp_query, "owner": $owner, "viewerIsAffiliated": $viewer_is_affiliated, "includeDrafts": $include_drafts, "recommendedOnly": $recommended_only, "builtinOnly": $builtin_only, "includeBuiltin": $include_builtin, "includeViewerDrafts": $include_viewer_drafts, "first": $first, "last": $last, "after": $after, "before": $before, "orderBy": $order_by, "orderByMultiple": $order_by_multiple, "tags": $tags, "exclude": $exclude, "include": $include} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($query: String, $owner: ID, $viewerIsAffiliated: Boolean, $includeDrafts: Boolean, $recommendedOnly: Boolean, $builtinOnly: Boolean, $includeBuiltin: Boolean, $includeViewerDrafts: Boolean, $first: Int, $last: Int, $after: String, $before: String, $orderBy: PromptsOrderBy, $orderByMultiple: [PromptsOrderBy!], $tags: [ID!], $exclude: [ID!], $include: [ID!]) { prompts(query: $query, owner: $owner, viewerIsAffiliated: $viewerIsAffiliated, includeDrafts: $includeDrafts, recommendedOnly: $recommendedOnly, builtinOnly: $builtinOnly, includeBuiltin: $includeBuiltin, includeViewerDrafts: $includeViewerDrafts, first: $first, last: $last, after: $after, before: $before, orderBy: $orderBy, orderByMultiple: $orderByMultiple, tags: $tags, exclude: $exclude, include: $include) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "prompts" }
}

# List of prompt tags, which can be applied to prompts.
#
# operationId: promptTags
export def "query prompt-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int # The limit argument for forward pagination.
  --last: int # The limit argument for backward pagination.
  --after: string # The cursor argument for forward pagination.
  --before: string # The cursor argument for backward pagination.
  --qp-query: string # Search prompt tags by name.
  --order-by: string@order-by-completer-5 # The field to sort by.
  --order-by-multiple: string@order-by-multiple-completer-1 # The field to sort by multiple fields.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first, "last": $last, "after": $after, "before": $before, "query": $qp_query, "orderBy": $order_by, "orderByMultiple": $order_by_multiple} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($first: Int, $last: Int, $after: String, $before: String, $query: String, $orderBy: PromptTagsOrderBy, $orderByMultiple: [PromptTagsOrderBy!]) { promptTags(first: $first, last: $last, after: $after, before: $before, query: $query, orderBy: $orderBy, orderByMultiple: $orderByMultiple) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "promptTags" }
}

# Returns the list of IdP clients that exist in the system. These can be used to authenticate with Sourcegraph.  Requires IDP_CLIENTS#READ permission.
#
# operationId: idpClients
export def "query idp-clients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int
  --after: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"first": $first, "after": $after} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "totalCount" }
    let body = {query: ("query($first: Int, $after: String) { idpClients(first: $first, after: $after) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "idpClients" }
}

# The list of known IdP scopes.
#
# operationId: idpScopes
export def "query idp-scopes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "name description" }
    let body = {query: ("query { idpScopes { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "idpScopes" }
}

# Get device authorization details by user code for the authorization flow. Returns the client information and requested scopes that the user needs to approve or deny.
#
# operationId: deviceAuthorizationByUserCode
export def "query device-authorization-by-user-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user_code: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"userCode": $user_code} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "isValid" }
    let body = {query: ("query($userCode: String!) { deviceAuthorizationByUserCode(userCode: $userCode) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deviceAuthorizationByUserCode" }
}

# Get consent details for a consent flow ID from the authorization flow. Returns the client information and requested scopes that the user needs to approve or deny. Can only be requested by the user who began the authorization flow.
#
# operationId: consentDetails
export def "query consent-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  consent_id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"consentID": $consent_id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($consentID: String!) { consentDetails(consentID: $consentID) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "consentDetails" }
}

# Returns the current Deep Search quota usage for the authenticated user. Returns null if quota tracking is not available or the user is not authenticated.
#
# operationId: deepSearchQuotaUsage
export def "query deep-search-quota-usage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "limit consumed resetTime" }
    let body = {query: ("query { deepSearchQuotaUsage { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deepSearchQuotaUsage" }
}

# Configuration for MCP (Model Context Protocol) integration.
#
# operationId: mcpConfig
export def "query mcp-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "isMCPEnabled isDCREnabled endpoint" }
    let body = {query: ("query { mcpConfig { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "mcpConfig" }
}

# Updates the user profile information for the user with the given ID.  Only the user and site admins may perform this mutation.
#
# operationId: updateUser
export def "mutation update-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user: string
  --username: string
  --display-name: string
  --avatar-url: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"user": $user, "username": $username, "displayName": $display_name, "avatarURL": $avatar_url} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id username email displayName avatarURL url settingsURL createdAt updatedAt siteAdmin builtinAuth serviceAccount unrestrictedRepoAccess tosAccepted hasVerifiedEmail viewerCanAdminister viewerCanChangeUsername databaseID namespaceName scimControlled viewerCanChangePrimaryEmail completionsQuotaOverride codeCompletionsQuotaOverride evaluateFeatureFlag" }
    let body = {query: ("mutation($user: ID!, $username: String, $displayName: String, $avatarURL: String) { updateUser(user: $user, username: $username, displayName: $displayName, avatarURL: $avatarURL) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateUser" }
}

# Creates an organization. The caller is added as a member of the newly created organization.  Only authenticated users may perform this mutation.
#
# operationId: createOrganization
export def "mutation create-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  name: string
  --display-name: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"name": $name, "displayName": $display_name} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name displayName createdAt viewerCanAdminister viewerIsMember url settingsURL namespaceName" }
    let body = {query: ("mutation($name: String!, $displayName: String) { createOrganization(name: $name, displayName: $displayName) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createOrganization" }
}

# Updates an organization.  Only site admins and any member of the organization may perform this mutation.
#
# operationId: updateOrganization
export def "mutation update-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  --display-name: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id, "displayName": $display_name} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name displayName createdAt viewerCanAdminister viewerIsMember url settingsURL namespaceName" }
    let body = {query: ("mutation($id: ID!, $displayName: String) { updateOrganization(id: $id, displayName: $displayName) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateOrganization" }
}

# Soft deletes an organization.  Only site admins may perform this mutation.
#
# operationId: deleteOrganization
export def "mutation delete-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  organization: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"organization": $organization} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($organization: ID!) { deleteOrganization(organization: $organization) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteOrganization" }
}

# Creates a webhook for the specified code host. Only site admins may perform this mutation.
#
# operationId: createWebhook
export def "mutation create-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  name: string
  code_host_kind: string
  code_host_urn: string
  --secret: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"name": $name, "codeHostKind": $code_host_kind, "codeHostURN": $code_host_urn, "secret": $secret} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id uuid url name codeHostKind codeHostURN secret updatedAt createdAt" }
    let body = {query: ("mutation($name: String!, $codeHostKind: String!, $codeHostURN: String!, $secret: String) { createWebhook(name: $name, codeHostKind: $codeHostKind, codeHostURN: $codeHostURN, secret: $secret) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createWebhook" }
}

# Deletes a webhook by given ID. Only site admins may perform this mutation.
#
# operationId: deleteWebhook
export def "mutation delete-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!) { deleteWebhook(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteWebhook" }
}

# Updates a webhook with given ID. Null values aren't updated.
#
# operationId: updateWebhook
export def "mutation update-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  --name: string
  --code-host-kind: string
  --code-host-urn: string
  --secret: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id, "name": $name, "codeHostKind": $code_host_kind, "codeHostURN": $code_host_urn, "secret": $secret} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id uuid url name codeHostKind codeHostURN secret updatedAt createdAt" }
    let body = {query: ("mutation($id: ID!, $name: String, $codeHostKind: String, $codeHostURN: String, $secret: String) { updateWebhook(id: $id, name: $name, codeHostKind: $codeHostKind, codeHostURN: $codeHostURN, secret: $secret) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateWebhook" }
}

# Adds a external service. Only site admins may perform this mutation.
#
# operationId: addExternalService
export def "mutation add-external-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-kind: string@input-kind-completer # The kind of the external service.
  --input-displayName: string # The display name of the external service.
  --input-config: string # The JSON configuration of the external service.
  --input-namespace: string # The namespace this external service belongs to. This can be used both for a user and an organization.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"kind": $input_kind, "displayName": $input_displayName, "config": $input_config, "namespace": $input_namespace} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id kind url displayName config createdAt updatedAt repoCount warning lastSyncError lastSyncAt nextSyncAt suspended hasConnectionCheck supportsRepoExclusion unrestricted" }
    let body = {query: ("mutation($input: AddExternalServiceInput!) { addExternalService(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "addExternalService" }
}

# Updates a external service. Only site admins may perform this mutation.
#
# operationId: updateExternalService
export def "mutation update-external-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-id: string # The id of the external service to update.
  --input-displayName: string # The updated display name, if provided.
  --input-config: string # The updated config, if provided.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"id": $input_id, "displayName": $input_displayName, "config": $input_config} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id kind url displayName config createdAt updatedAt repoCount warning lastSyncError lastSyncAt nextSyncAt suspended hasConnectionCheck supportsRepoExclusion unrestricted" }
    let body = {query: ("mutation($input: UpdateExternalServiceInput!) { updateExternalService(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateExternalService" }
}

# Delete an external service. Only site admins may perform this mutation.
#
# operationId: deleteExternalService
export def "mutation delete-external-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  external_service: string
  --async: string@bool-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"externalService": $external_service, "async": $async} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($externalService: ID!, $async: Boolean) { deleteExternalService(externalService: $externalService, async: $async) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteExternalService" }
}

# Excludes a repo from external services configs. Only site admins may perform this mutation.
#
# operationId: excludeRepoFromExternalServices
export def "mutation exclude-repo-from-external-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  external_services: string
  repo: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"externalServices": $external_services, "repo": $repo} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($externalServices: [ID!]!, $repo: ID!) { excludeRepoFromExternalServices(externalServices: $externalServices, repo: $repo) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "excludeRepoFromExternalServices" }
}

# Tests the connection to a mirror repository's original source repository. This is an expensive and slow operation, so it should only be used for interactive diagnostics.  Only site admins may perform this mutation.
#
# operationId: checkMirrorRepositoryConnection
export def "mutation check-mirror-repository-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repository: string # The ID of the existing repository whose mirror to check.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repository": $repository} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "error" }
    let body = {query: ("mutation($repository: ID!) { checkMirrorRepositoryConnection(repository: $repository) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "checkMirrorRepositoryConnection" }
}

# Schedule the mirror repository to be updated from its original source repository. Updating occurs automatically, so this should not normally be needed.  Only site admins may perform this mutation.
#
# operationId: updateMirrorRepository
export def "mutation update-mirror-repository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repository: string # The mirror repository to update.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repository": $repository} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($repository: ID!) { updateMirrorRepository(repository: $repository) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateMirrorRepository" }
}

# Schedule the mirror repository to be optimized. Optimization occurs automatically, so this should not normally be needed.  Only site admins may perform this mutation.
#
# operationId: optimizeMirrorRepository
export def "mutation optimize-mirror-repository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repository: string # The mirror repository to optimize.
  --strategy: string@strategy-completer # The optimization strategy to use. HEURISTIC (default) optimizes only what's needed based on Git's assessment. EAGER forces a full optimization regardless of current state.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repository": $repository, "strategy": $strategy} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($repository: ID!, $strategy: GitOptimizationStrategy) { optimizeMirrorRepository(repository: $repository, strategy: $strategy) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "optimizeMirrorRepository" }
}

# Force Zoekt to reindex the repository right now. Reindexing occurs automatically, so this should not normally be needed.
#
# operationId: reindexRepository
export def "mutation reindex-repository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repository: string # The repository to index
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repository": $repository} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($repository: ID!) { reindexRepository(repository: $repository) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "reindexRepository" }
}

# Creates a new user account.  Only site admins may perform this mutation.
#
# operationId: createUser
export def "mutation create-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  username: string # The new user's username.
  --email: string # The new user's optional email address. If given, it must be verified by the user.
  --verified-email: string@bool-completer # Whether or not to mark the provided email address as verified. If unset or set to true, then the email address is immediately marked as verified - otherwise, the email may be marked as unverified if SMTP and password resets are enabled.
  --is-service-account: string@bool-completer # Whether this is a service account for automation rather than a regular user account. Service accounts don't have an email or password.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"username": $username, "email": $email, "verifiedEmail": $verified_email, "isServiceAccount": $is_service_account} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "resetPasswordURL" }
    let body = {query: ("mutation($username: String!, $email: String, $verifiedEmail: Boolean, $isServiceAccount: Boolean) { createUser(username: $username, email: $email, verifiedEmail: $verifiedEmail, isServiceAccount: $isServiceAccount) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createUser" }
}

# Randomize a user's password so that they need to reset it before they can sign in again.  Only site admins may perform this mutation.
#
# operationId: randomizeUserPassword
export def "mutation randomize-user-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"user": $user} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "resetPasswordURL emailSent" }
    let body = {query: ("mutation($user: ID!) { randomizeUserPassword(user: $user) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "randomizeUserPassword" }
}

# Adds an email address to the user's account. The email address will be marked as unverified until the user has followed the email verification process.  Only the user and site admins may perform this mutation.
#
# operationId: addUserEmail
export def "mutation add-user-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user: string
  email: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"user": $user, "email": $email} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($user: ID!, $email: String!) { addUserEmail(user: $user, email: $email) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "addUserEmail" }
}

# Removes an email address from the user's account.  Only the user and site admins may perform this mutation.
#
# operationId: removeUserEmail
export def "mutation remove-user-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user: string
  email: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"user": $user, "email": $email} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($user: ID!, $email: String!) { removeUserEmail(user: $user, email: $email) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "removeUserEmail" }
}

# Set an email address as the user's primary.  Only the user and site admins may perform this mutation. Check user.viewerCanChangePrimaryEmail for permission and other update inhibitors.
#
# operationId: setUserEmailPrimary
export def "mutation set-user-email-primary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user: string
  email: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"user": $user, "email": $email} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($user: ID!, $email: String!) { setUserEmailPrimary(user: $user, email: $email) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setUserEmailPrimary" }
}

# Manually set the verification status of a user's email, without going through the normal verification process (of clicking on a link in the email with a verification code).  Only site admins may perform this mutation.
#
# operationId: setUserEmailVerified
export def "mutation set-user-email-verified" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user: string
  email: string
  --verified: string@bool-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"user": $user, "email": $email, "verified": $verified} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($user: ID!, $email: String!, $verified: Boolean!) { setUserEmailVerified(user: $user, email: $email, verified: $verified) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setUserEmailVerified" }
}

# Resend a verification email, no op if the email is already verified.  Only the user and site admins may perform this mutation.
#
# operationId: resendVerificationEmail
export def "mutation resend-verification-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user: string
  email: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"user": $user, "email": $email} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($user: ID!, $email: String!) { resendVerificationEmail(user: $user, email: $email) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "resendVerificationEmail" }
}

# Deletes a user account. Only site admins may perform this mutation.  If hard == true, a hard delete is performed. By default, deletes are 'soft deletes' and could theoretically be undone with manual DB commands. If a hard delete is performed, the data is truly removed from the database and deletion can NEVER be undone.  Data that is deleted as part of this operation:  - All user data (access tokens, email addresses, external account info, survey responses, etc) - Organization membership information (which organizations the user is a part of, any invitations created by or targeting the user). - User, Organization, or Global settings authored by the user.
#
# operationId: deleteUser
export def "mutation delete-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user: string
  --hard: string@bool-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"user": $user, "hard": $hard} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($user: ID!, $hard: Boolean) { deleteUser(user: $user, hard: $hard) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteUser" }
}

# Bulk "deleteUser" action.
#
# operationId: deleteUsers
export def "mutation delete-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  users: string
  --hard: string@bool-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"users": $users, "hard": $hard} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($users: [ID!]!, $hard: Boolean) { deleteUsers(users: $users, hard: $hard) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteUsers" }
}

# Bulk "recoverUser" action.
#
# operationId: recoverUsers
export def "mutation recover-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user_i_ds: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"userIDs": $user_i_ds} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($userIDs: [ID!]!) { recoverUsers(userIDs: $userIDs) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "recoverUsers" }
}

# Updates the current user's password. The oldPassword arg must match the user's current password.
#
# operationId: updatePassword
export def "mutation update-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  old_password: string
  new_password: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"oldPassword": $old_password, "newPassword": $new_password} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($oldPassword: String!, $newPassword: String!) { updatePassword(oldPassword: $oldPassword, newPassword: $newPassword) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updatePassword" }
}

# Creates a password for the current user. It is only permitted if the user does not have a password and password authentication is enabled.
#
# operationId: createPassword
export def "mutation create-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  new_password: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"newPassword": $new_password} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($newPassword: String!) { createPassword(newPassword: $newPassword) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createPassword" }
}

# Sets the user to accept the site's Terms of Service and Privacy Policy. If the ID is omitted, the current user is assumed.  Only the user or site admins may perform this mutation.
#
# operationId: setTosAccepted
export def "mutation set-tos-accepted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --user-id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"userID": $user_id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($userID: ID) { setTosAccepted(userID: $userID) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setTosAccepted" }
}

# Creates an access token that grants the privileges of the specified user (referred to as the access token's "subject" user after token creation). The result is the access token value, which the caller is responsible for storing (it is not accessible by Sourcegraph after creation).  The supported scopes are:  - "user:all": Full control of all resources accessible to the user account. - "site-admin:sudo": Ability to perform any action as any other user. (Only site admins may create tokens   with this scope.) - "mcp": Access to MCP (Model Context Protocol) endpoints only. This is a limited scope that does not   grant full API access.  DurationSeconds: If provided, the number of seconds until the token expires automatically.  Only the user or site admins may perform this mutation.
#
# operationId: createAccessToken
export def "mutation create-access-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user: string
  --duration-seconds: int
  scopes: string
  note: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"user": $user, "durationSeconds": $duration_seconds, "scopes": $scopes, "note": $note} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id token" }
    let body = {query: ("mutation($user: ID!, $durationSeconds: Int, $scopes: [String!]!, $note: String!) { createAccessToken(user: $user, durationSeconds: $durationSeconds, scopes: $scopes, note: $note) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createAccessToken" }
}

# Deletes and immediately revokes the specified access token, specified by either its ID or by the token itself.  Only site admins or the user who owns the token may perform this mutation.
#
# operationId: deleteAccessToken
export def "mutation delete-access-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --by-id: string
  --by-token: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"byID": $by_id, "byToken": $by_token} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($byID: ID, $byToken: String) { deleteAccessToken(byID: $byID, byToken: $byToken) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteAccessToken" }
}

# Deletes the association between an external account and its Sourcegraph user. It does NOT delete the external account on the external service where it resides.  Only site admins or the user who is associated with the external account may perform this mutation.
#
# operationId: deleteExternalAccount
export def "mutation delete-external-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  external_account: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"externalAccount": $external_account} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($externalAccount: ID!) { deleteExternalAccount(externalAccount: $externalAccount) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteExternalAccount" }
}

# Adds an external account to the authenticated user's account. The service type and service ID must correspond to a valid auth provider on the site. The account details must be a stringified JSON object that contains valid credentials for the provided service type.
#
# operationId: addExternalAccount
export def "mutation add-external-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  service_type: string
  service_id: string
  account_details: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"serviceType": $service_type, "serviceID": $service_id, "accountDetails": $account_details} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($serviceType: String!, $serviceID: String!, $accountDetails: String!) { addExternalAccount(serviceType: $serviceType, serviceID: $serviceID, accountDetails: $accountDetails) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "addExternalAccount" }
}

# Invite the user with the given username to join the organization. The invited user account must already exist.  Only site admins and any organization member may perform this mutation.
#
# operationId: inviteUserToOrganization
export def "mutation invite-user-to-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  organization: string
  username: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"organization": $organization, "username": $username} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "sentInvitationEmail invitationURL" }
    let body = {query: ("mutation($organization: ID!, $username: String!) { inviteUserToOrganization(organization: $organization, username: $username) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "inviteUserToOrganization" }
}

# Accept or reject an existing organization invitation.  Only the recipient of the invitation may perform this mutation.
#
# operationId: respondToOrganizationInvitation
export def "mutation respond-to-organization-invitation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  organization_invitation: string # The organization invitation.
  response_type: string@response-type-completer # The response to the invitation.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"organizationInvitation": $organization_invitation, "responseType": $response_type} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($organizationInvitation: ID!, $responseType: OrganizationInvitationResponseType!) { respondToOrganizationInvitation(organizationInvitation: $organizationInvitation, responseType: $responseType) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "respondToOrganizationInvitation" }
}

# Immediately add a user as a member to the organization, without sending an invitation email.  Only site admins may perform this mutation. Organization members may use the inviteUserToOrganization mutation to invite users.
#
# operationId: addUserToOrganization
export def "mutation add-user-to-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  organization: string
  username: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"organization": $organization, "username": $username} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($organization: ID!, $username: String!) { addUserToOrganization(organization: $organization, username: $username) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "addUserToOrganization" }
}

# Removes a user as a member from an organization.  Only site admins and any member of the organization may perform this mutation.
#
# operationId: removeUserFromOrganization
export def "mutation remove-user-from-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user: string
  organization: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"user": $user, "organization": $organization} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($user: ID!, $organization: ID!) { removeUserFromOrganization(user: $user, organization: $organization) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "removeUserFromOrganization" }
}

# Adds a Phabricator repository to Sourcegraph.
#
# operationId: addPhabricatorRepo
export def "mutation add-phabricator-repo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  callsign: string # The callsign, for example "MUX".
  --name: string # The name, for example "github.com/gorilla/mux".
  --uri: string # An alias for name. DEPRECATED: use name instead.
  url: string # The URL to the phabricator instance (e.g. http://phabricator.sgdev.org).
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"callsign": $callsign, "name": $name, "uri": $uri, "url": $url} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($callsign: String!, $name: String, $uri: String, $url: String!) { addPhabricatorRepo(callsign: $callsign, name: $name, uri: $uri, url: $url) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "addPhabricatorRepo" }
}

# Resolves a revision for a given diff from Phabricator.
#
# operationId: resolvePhabricatorDiff
export def "mutation resolve-phabricator-diff" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repo_name: string # The name of the repository that the diff is based on.
  diff_id: string # The ID of the diff on Phabricator.
  base_rev: string # The base revision this diff is based on.
  --patch: string # The raw contents of the diff from Phabricator. Required if Sourcegraph doesn't have a Conduit API token.
  --description: string # The description of the diff. This will be used as the commit message.
  --author-name: string # The name of author of the diff.
  --author-email: string # The author's email.
  --date: string # When the diff was created.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repoName": $repo_name, "diffID": $diff_id, "baseRev": $base_rev, "patch": $patch, "description": $description, "authorName": $author_name, "authorEmail": $author_email, "date": $date} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id oid abbreviatedOID message subject body url canonicalURL fileNames languages" }
    let body = {query: ("mutation($repoName: String!, $diffID: ID!, $baseRev: String!, $patch: String, $description: String, $authorName: String, $authorEmail: String, $date: String) { resolvePhabricatorDiff(repoName: $repoName, diffID: $diffID, baseRev: $baseRev, patch: $patch, description: $description, authorName: $authorName, authorEmail: $authorEmail, date: $date) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "resolvePhabricatorDiff" }
}

# Logs a user event. No longer used, only here for backwards compatibility with IDE and browser extensions.
#
# DEPRECATED
# operationId: logUserEvent
@deprecated "use telemetry { recordEvent } instead"
export def "mutation log-user-event" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  event: string@event-completer
  user_cookie_id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"event": $event, "userCookieID": $user_cookie_id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($event: UserEvent!, $userCookieID: String!) { logUserEvent(event: $event, userCookieID: $userCookieID) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "logUserEvent" }
}

# Logs an event.
#
# DEPRECATED
# operationId: logEvent
@deprecated "use telemetry { recordEvent } instead"
export def "mutation log-event" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  event: string # The name of the event.
  user_cookie_id: string # The randomly generated unique user ID stored in a browser cookie.
  --first-source-url: string # The first sourcegraph URL visited by the user, stored in a browser cookie.
  --last-source-url: string # The last sourcegraph URL visited by the user, stored in a browser cookie.
  url: string # The URL when the event was logged.
  source: string@source-completer # The source of the event.
  --cohort-id: string # An optional cohort ID to identify the user as part of a specific A/B test. The cohort ID is expected to be a date in the form YYYY-MM-DD
  --referrer: string # An optional referrer parameter for the user's current session. Only captured and stored on Sourcegraph Cloud.
  --original-referrer: string # The original referrer for a user
  --session-referrer: string # The session referrer for a user
  --session-first-url: string # The sessions first url for a user
  --device-session-id: string # Device session ID to identify the user's session for analytics.
  --argument: string # The additional argument information.
  --public-argument: string # Public argument information. PRIVACY: Do NOT include any potentially private information in this field. These properties get sent to our analytics tools for Cloud, so must not include private information, such as search queries or repository names.
  --device-id: string # Device ID used for Amplitude analytics. Used on Sourcegraph Cloud only.
  --event-id: int # Event ID used to deduplicate events that occur simultaneously in Amplitude analytics. See https://developers.amplitude.com/docs/http-api-v2#optional-keys. Used on Sourcegraph Cloud only.
  --insert-id: string # Insert ID used to deduplicate events that re-occur in the event of retries or backfills in Amplitude analytics. See https://developers.amplitude.com/docs/http-api-v2#optional-keys. Used on Sourcegraph Cloud only.
  --client: string # The client that this event is being sent from.
  --billing-product-category: string # The product category for the event, used for billing purposes.
  --billing-event-id: string # The billing ID for the event, used for tagging user events for billing aggregation purposes.
  --connected-site-id: string # The site ID that the client was connected to when the event was logged.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"event": $event, "userCookieID": $user_cookie_id, "firstSourceURL": $first_source_url, "lastSourceURL": $last_source_url, "url": $url, "source": $source, "cohortID": $cohort_id, "referrer": $referrer, "originalReferrer": $original_referrer, "sessionReferrer": $session_referrer, "sessionFirstURL": $session_first_url, "deviceSessionID": $device_session_id, "argument": $argument, "publicArgument": $public_argument, "deviceID": $device_id, "eventID": $event_id, "insertID": $insert_id, "client": $client, "billingProductCategory": $billing_product_category, "billingEventID": $billing_event_id, "connectedSiteID": $connected_site_id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($event: String!, $userCookieID: String!, $firstSourceURL: String, $lastSourceURL: String, $url: String!, $source: EventSource!, $cohortID: String, $referrer: String, $originalReferrer: String, $sessionReferrer: String, $sessionFirstURL: String, $deviceSessionID: String, $argument: String, $publicArgument: String, $deviceID: String, $eventID: Int, $insertID: String, $client: String, $billingProductCategory: String, $billingEventID: String, $connectedSiteID: String) { logEvent(event: $event, userCookieID: $userCookieID, firstSourceURL: $firstSourceURL, lastSourceURL: $lastSourceURL, url: $url, source: $source, cohortID: $cohortID, referrer: $referrer, originalReferrer: $originalReferrer, sessionReferrer: $sessionReferrer, sessionFirstURL: $sessionFirstURL, deviceSessionID: $deviceSessionID, argument: $argument, publicArgument: $publicArgument, deviceID: $deviceID, eventID: $eventID, insertID: $insertID, client: $client, billingProductCategory: $billingProductCategory, billingEventID: $billingEventID, connectedSiteID: $connectedSiteID) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "logEvent" }
}

# Logs a batch of events.
#
# DEPRECATED
# operationId: logEvents
# --events item shape: {event: string, userCookieID: string, firstSourceURL?: string, lastSourceURL?: string, url: string, source: "WEB"|"CODEHOSTINTEGRATION"|"BACKEND"|"STATICWEB"|"IDEEXTENSION"|"CODY", cohortID?: string, referrer?: string, originalReferrer?: string, sessionReferrer?: string, sessionFirstURL?: string, deviceSessionID?: string, argument?: string, publicArgument?: string, deviceID?: string, eventID?: int, insertID?: string, client?: string, billingProductCategory?: string, billingEventID?: string, connectedSiteID?: string}
@deprecated "use telemetry { recordEvent } instead"
export def "mutation log-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --events: record # item shape: {event: string, userCookieID: string, firstSourceURL?: string, lastSourceURL?: string, url: string, source: "WEB"|"CODEHOSTINTEGRATION"|"BACKEND"|"STATICWEB"|"IDEEXTENSION"|"CODY", cohortID?: string, referrer?: string, originalReferrer?: string, sessionReferrer?: string, sessionFirstURL?: string, deviceSessionID?: string, argument?: string, publicArgument?: string, deviceID?: string, eventID?: int, insertID?: string, client?: string, billingProductCategory?: string, billingEventID?: string, connectedSiteID?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"events": $events} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($events: [Event!]) { logEvents(events: $events) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "logEvents" }
}

# All mutations that update settings (global, organization, and user settings) are under this field.  Only the settings subject whose settings are being mutated (and site admins) may perform this mutation.  This mutation only affects global, organization, and user settings, not site configuration. For site configuration (which is a separate set of configuration properties from global/organization/user settings), use updateSiteConfiguration.
#
# operationId: settingsMutation
export def "mutation settings-mutation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-subject: string # The subject whose settings to mutate (organization, user, etc.).
  --input-lastID: int # The ID of the last-known settings known to the client, or null if there is none. This field is used to prevent race conditions when there are concurrent editors.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"subject": $input_subject, "lastID": $input_lastID} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("mutation($input: SettingsMutationGroupInput!) { settingsMutation(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "settingsMutation" }
}

# DEPRECATED: Use settingsMutation instead. This field is a deprecated alias for settingsMutation and will be removed in a future release.
#
# DEPRECATED
# operationId: configurationMutation
@deprecated "use settingsMutation instead"
export def "mutation configuration-mutation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-subject: string # The subject whose settings to mutate (organization, user, etc.).
  --input-lastID: int # The ID of the last-known settings known to the client, or null if there is none. This field is used to prevent race conditions when there are concurrent editors.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"subject": $input_subject, "lastID": $input_lastID} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("mutation($input: SettingsMutationGroupInput!) { configurationMutation(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "configurationMutation" }
}

# Updates the site configuration. Returns whether or not a restart is required for the update to be applied.  Only site admins may perform this mutation.
#
# operationId: updateSiteConfiguration
export def "mutation update-site-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  last_id: int # The last ID of the site configuration that is known by the client, to prevent race conditions. An error will be returned if someone else has already written a new update.
  input: string # A JSON object containing the entire site configuration. The previous site configuration will be replaced with this new value.
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"lastID": $last_id, "input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let body = {query: "mutation($lastID: Int!, $input: String!) { updateSiteConfiguration(lastID: $lastID, input: $input) }", variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateSiteConfiguration" }
}

# Sets the license key in the site configuration.  Only site admins may perform this mutation.
#
# operationId: setLicenseKey
export def "mutation set-license-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --license-key: string # The license key to set. If null or empty, the license key is removed.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"licenseKey": $license_key} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($licenseKey: String) { setLicenseKey(licenseKey: $licenseKey) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setLicenseKey" }
}

# Sets the email configuration in the site configuration.  Only site admins may perform this mutation.
#
# operationId: setSMTPConfiguration
# --input-smtp shape: {host: string, port: int, authentication: "NONE"|"PLAIN"|"CRAM_MD5", username?: string, password?: string, domain?: string, noVerifyTLS?: bool, additionalHeaders?: record}
export def "mutation set-smtp-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-smtp: record # SMTP server configuration. If null, SMTP configuration is removed. — shape: {host: string, port: int, authentication: "NONE"|"PLAIN"|"CRAM_MD5", username?: string, password?: string, domain?: string, noVerifyTLS?: bool, additionalHeaders?: record}
  --input-address: string # The email address to use as the sender. If null or empty, the address is removed.
  --input-senderName: string # The name to use as the sender. If null or empty, defaults to "Sourcegraph".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"smtp": $input_smtp, "address": $input_address, "senderName": $input_senderName} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($input: SMTPConfigurationInput!) { setSMTPConfiguration(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setSMTPConfiguration" }
}

# Sets the instance settings (external URL, CORS origins, branding, HTML injection) in the site configuration.  Only site admins may perform this mutation.
#
# operationId: setInstanceSettings
# --input-branding shape: {brandName?: string, favicon?: string, light?: record, dark?: record}
export def "mutation set-instance-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-externalURL: string # The externally accessible URL for this Sourcegraph instance.
  --input-corsOrigin: string # Space-separated list of allowed origins for cross-origin HTTP requests.
  --input-branding: record # Branding configuration for the instance. — shape: {brandName?: string, favicon?: string, light?: record, dark?: record}
  --input-htmlHeadTop: string # HTML to inject at the top of the <head> element on each page.
  --input-htmlHeadBottom: string # HTML to inject at the bottom of the <head> element on each page.
  --input-htmlBodyTop: string # HTML to inject at the top of the <body> element on each page.
  --input-htmlBodyBottom: string # HTML to inject at the bottom of the <body> element on each page.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"externalURL": $input_externalURL, "corsOrigin": $input_corsOrigin, "branding": $input_branding, "htmlHeadTop": $input_htmlHeadTop, "htmlHeadBottom": $input_htmlHeadBottom, "htmlBodyTop": $input_htmlBodyTop, "htmlBodyBottom": $input_htmlBodyBottom} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($input: InstanceSettingsInput!) { setInstanceSettings(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setInstanceSettings" }
}

# Validates an SMTP configuration by sending a verification email without saving the config. Returns a verification code that was sent in the email, which can be used to confirm the email was received before saving the configuration.  Only site admins may perform this mutation.
#
# operationId: validateSMTPConfiguration
# --smtp-additionalHeaders item shape: {key: string, value: string}
export def "mutation validate-smtp-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  to: string # The email address to send the verification email to.
  sender_address: string # The sender email address to use.
  --sender-name: string # The sender name to use (optional).
  --smtp-host: string # The SMTP server hostname.
  --smtp-port: int # The SMTP server port.
  --smtp-authentication: string@smtp-authentication-completer # The authentication method to use.
  --smtp-username: string # The username for authentication (required if authentication is not "none").
  --smtp-password: string # The password for authentication (required if authentication is not "none").
  --smtp-domain: string # The domain to use for the HELO command.
  --smtp-noVerifyTLS: string@bool-completer # If true, skip TLS certificate verification (not recommended for production).
  --smtp-additionalHeaders: record # Additional headers to include on SMTP messages. — item shape: {key: string, value: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let smtp = ({"host": $smtp_host, "port": $smtp_port, "authentication": $smtp_authentication, "username": $smtp_username, "password": $smtp_password, "domain": $smtp_domain, "noVerifyTLS": $smtp_noVerifyTLS, "additionalHeaders": $smtp_additionalHeaders} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"to": $to, "senderAddress": $sender_address, "senderName": $sender_name, "smtp": $smtp} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let body = {query: "mutation($smtp: SMTPConfigInput!, $to: String!, $senderAddress: String!, $senderName: String) { validateSMTPConfiguration(to: $to, senderAddress: $senderAddress, senderName: $senderName, smtp: $smtp) }", variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "validateSMTPConfiguration" }
}

# Sets session management configuration in the site configuration. This includes session expiry, idle timeout, and access token settings.  Only site admins may perform this mutation.
#
# operationId: setSessionConfiguration
# --input-accessTokens shape: {allow: "ALL_USERS_CREATE"|"SITE_ADMIN_CREATE"|"NONE", allowNoExpiration: bool}
export def "mutation set-session-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-sessionExpiry: string # How long user login sessions are valid. Format: Go duration string (e.g., "720h", "30m", "60s"). Must be at least 1 hour.
  --input-maxSessionIdleDuration: string # Maximum idle time before a session expires. If null or empty, idle timeout is disabled.
  --input-accessTokens: record # Access token settings. — shape: {allow: "ALL_USERS_CREATE"|"SITE_ADMIN_CREATE"|"NONE", allowNoExpiration: bool}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"sessionExpiry": $input_sessionExpiry, "maxSessionIdleDuration": $input_maxSessionIdleDuration, "accessTokens": $input_accessTokens} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($input: SessionConfigurationInput!) { setSessionConfiguration(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setSessionConfiguration" }
}

# Sets signup and self-service configuration in the site configuration. This includes username change settings and access request settings.  Only site admins may perform this mutation.
#
# operationId: setSignupConfiguration
export def "mutation set-signup-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-enableUsernameChanges: string@bool-completer # Whether users can change their own usernames.
  --input-accessRequestEnabled: string@bool-completer # Whether access requests are enabled for users who cannot sign up.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"enableUsernameChanges": $input_enableUsernameChanges, "accessRequestEnabled": $input_accessRequestEnabled} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($input: SignupConfigurationInput!) { setSignupConfiguration(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setSignupConfiguration" }
}

# Sets password policy configuration in the site configuration. This includes minimum password length and complexity requirements.  Only site admins may perform this mutation.
#
# operationId: setPasswordPolicyConfiguration
export def "mutation set-password-policy-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-minPasswordLength: int # Minimum password length required.
  --input-enabled: string@bool-completer # Whether password complexity requirements are enabled.
  --input-numberOfSpecialCharacters: int # Number of special characters required in passwords.
  --input-requireAtLeastOneNumber: string@bool-completer # Whether at least one number is required.
  --input-requireUpperandLowerCase: string@bool-completer # Whether mixed case (upper and lower) is required.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"minPasswordLength": $input_minPasswordLength, "enabled": $input_enabled, "numberOfSpecialCharacters": $input_numberOfSpecialCharacters, "requireAtLeastOneNumber": $input_requireAtLeastOneNumber, "requireUpperandLowerCase": $input_requireUpperandLowerCase} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($input: PasswordPolicyConfigurationInput!) { setPasswordPolicyConfiguration(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setPasswordPolicyConfiguration" }
}

# Sets access restrictions configuration in the site configuration. This includes repository permission enforcement and IP allowlist settings.  Only site admins may perform this mutation.
#
# operationId: setAccessRestrictionsConfiguration
export def "mutation set-access-restrictions-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-enforceForSiteAdmins: string@bool-completer # Whether repository permissions are enforced for site admins.
  --input-ipAllowlistEnabled: string@bool-completer # Whether IP allowlist is enabled.
  --input-userIpAddress: string # Allowed user IP addresses (CIDR notation supported).
  --input-clientIpAddress: string # Allowed client IP addresses (e.g., load balancer ranges).
  --input-trustedClientIpAddress: string # Trusted client IP addresses that bypass user IP checks.
  --input-userIpRequestHeaders: string # Request headers to check for user IP address.
  --input-errorMessageTemplate: string # Custom error message shown when access is denied.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"enforceForSiteAdmins": $input_enforceForSiteAdmins, "ipAllowlistEnabled": $input_ipAllowlistEnabled, "userIpAddress": $input_userIpAddress, "clientIpAddress": $input_clientIpAddress, "trustedClientIpAddress": $input_trustedClientIpAddress, "userIpRequestHeaders": $input_userIpRequestHeaders, "errorMessageTemplate": $input_errorMessageTemplate} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($input: AccessRestrictionsConfigurationInput!) { setAccessRestrictionsConfiguration(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setAccessRestrictionsConfiguration" }
}

# Deletes an authentication provider from the site configuration by removing the matching entry from the auth.providers array.  Only site admins may perform this mutation.
#
# operationId: deleteAuthProvider
export def "mutation delete-auth-provider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  service_type: string # The service type of the auth provider to delete (e.g. "builtin", "saml", "openidconnect", "github", "gitlab").
  config_id: string # The stable configuration identifier of the auth provider to delete.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"serviceType": $service_type, "configID": $config_id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($serviceType: String!, $configID: String!) { deleteAuthProvider(serviceType: $serviceType, configID: $configID) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteAuthProvider" }
}

# Enables or disables the builtin username-password authentication provider. When enabled, adds a builtin provider to auth.providers if not already present. When disabled, removes all builtin providers from auth.providers.  Only site admins may perform this mutation.
#
# operationId: setBuiltinAuthEnabled
export def "mutation set-builtin-auth-enabled" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --enabled: string@bool-completer # Whether builtin authentication should be enabled.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"enabled": $enabled} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($enabled: Boolean!) { setBuiltinAuthEnabled(enabled: $enabled) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setBuiltinAuthEnabled" }
}

# Sets whether an authentication provider is enabled for sign-in. When disabled, the provider is hidden from the sign-in page but can still be used for account linking and permissions syncing.  Only site admins may perform this mutation.
#
# operationId: setAuthProviderSignIn
export def "mutation set-auth-provider-sign-in" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  service_type: string # The service type of the auth provider.
  config_id: string # The stable configuration identifier of the auth provider.
  --enabled: string@bool-completer # Whether sign-in should be enabled for this provider.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"serviceType": $service_type, "configID": $config_id, "enabled": $enabled} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($serviceType: String!, $configID: String!, $enabled: Boolean!) { setAuthProviderSignIn(serviceType: $serviceType, configID: $configID, enabled: $enabled) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setAuthProviderSignIn" }
}

# Reorders authentication providers by setting their order field in site configuration. The providers array specifies the desired display order on the sign-in page (first element = order 1). Providers not included in the list will have their order cleared.  Only site admins may perform this mutation.
#
# operationId: reorderAuthProviders
# --providers item shape: {serviceType: string, configID: string}
export def "mutation reorder-auth-providers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --providers: record # The ordered list of provider identifiers. The first provider in this list will be assigned order 1, the second order 2, etc. — item shape: {serviceType: string, configID: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"providers": $providers} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($providers: [AuthProviderReorderInput!]!) { reorderAuthProviders(providers: $providers) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "reorderAuthProviders" }
}

# Sets whether the user with the specified user ID is a site admin.  Only site admins may perform this mutation.
#
# operationId: setUserIsSiteAdmin
export def "mutation set-user-is-site-admin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user_id: string
  --site-admin: string@bool-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"userID": $user_id, "siteAdmin": $site_admin} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($userID: ID!, $siteAdmin: Boolean!) { setUserIsSiteAdmin(userID: $userID, siteAdmin: $siteAdmin) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setUserIsSiteAdmin" }
}

# Invalidates all sessions belonging to a user.  Only site admins may perform this mutation.
#
# operationId: invalidateSessionsByID
export def "mutation invalidate-sessions-by-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user_id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"userID": $user_id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($userID: ID!) { invalidateSessionsByID(userID: $userID) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "invalidateSessionsByID" }
}

# Bulk "invalidateSessionsByID" action.
#
# operationId: invalidateSessionsByIDs
export def "mutation invalidate-sessions-by-i-ds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user_i_ds: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"userIDs": $user_i_ds} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($userIDs: [ID!]!) { invalidateSessionsByIDs(userIDs: $userIDs) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "invalidateSessionsByIDs" }
}

# Reloads the site by restarting the server. This is not supported for all deployment types. This may cause downtime.  Only site admins may perform this mutation.
#
# DEPRECATED
# operationId: reloadSite
@deprecated "This mutation is no longer used and will be removed in a future release."
export def "mutation reload-site" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation { reloadSite { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "reloadSite" }
}

# Submits a user satisfaction (NPS) survey.
#
# operationId: submitSurvey
export def "mutation submit-survey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-email: string # User-provided email address, if there is no currently authenticated user. If there is, this value will not be used.
  --input-score: int # User's likelihood of recommending Sourcegraph to a friend, from 0-10.
  --input-otherUseCase: string # The answer to "What do you use Sourcegraph for?".
  --input-better: string # The answer to "What would make Sourcegraph better?"
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"email": $input_email, "score": $input_score, "otherUseCase": $input_otherUseCase, "better": $input_better} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($input: SurveySubmissionInput!) { submitSurvey(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "submitSurvey" }
}

# Submits happiness feedback.
#
# operationId: submitHappinessFeedback
export def "mutation submit-happiness-feedback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-feedback: string # The feedback text from the user.
  --input-currentPath: string # The path that the happiness feedback will be submitted from.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"feedback": $input_feedback, "currentPath": $input_currentPath} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($input: HappinessFeedbackSubmissionInput!) { submitHappinessFeedback(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "submitHappinessFeedback" }
}

# OBSERVABILITY  Set the status of a test alert of the specified parameters - useful for validating 'observability.alerts' configuration. Alerts may take up to a minute to fire.
#
# operationId: triggerObservabilityTestAlert
export def "mutation trigger-observability-test-alert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  level: string # Level of alert to test - either warning or critical.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"level": $level} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($level: String!) { triggerObservabilityTestAlert(level: $level) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "triggerObservabilityTestAlert" }
}

# Updates an out-of-band migration to run in a particular direction.  Applied in the forward direction, an out-of-band migration migrates data into a format that is readable by newer Sourcegraph instances. This may be destructive or non-destructive process, depending on the nature and implementation of the migration.  Applied in the reverse direction, an out-of-band migration ensures that data is moved back into a format that is readable by the previous Sourcegraph instance. Recently introduced migrations should be applied in reverse prior to downgrading the instance.
#
# operationId: setMigrationDirection
export def "mutation set-migration-direction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  --apply-reverse: string@bool-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id, "applyReverse": $apply_reverse} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!, $applyReverse: Boolean!) { setMigrationDirection(id: $id, applyReverse: $applyReverse) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setMigrationDirection" }
}

# EXPERIMENTAL: Create a new feature flag
#
# operationId: createFeatureFlag
export def "mutation create-feature-flag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  name: string # The name of the feature flag
  --value: string@bool-completer # The value of the feature flag. Only set if the new feature flag will be a concrete boolean flag. Mutually exclusive with rolloutBasisPoints.
  --rollout-basis-points: int # The ratio of users the feature flag will apply to, expressed in basis points (0.01%). Only set if the new feature flag will be a rollout flag. Mutually exclusive with value.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"name": $name, "value": $value, "rolloutBasisPoints": $rollout_basis_points} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename ... on FeatureFlagBoolean { name value createdAt updatedAt } ... on FeatureFlagRollout { name rolloutBasisPoints createdAt updatedAt }" }
    let body = {query: ("mutation($name: String!, $value: Boolean, $rolloutBasisPoints: Int) { createFeatureFlag(name: $name, value: $value, rolloutBasisPoints: $rolloutBasisPoints) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createFeatureFlag" }
}

# EXPERIMENTAL: Delete a feature flag
#
# operationId: deleteFeatureFlag
export def "mutation delete-feature-flag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  name: string # The name of the feature flag
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"name": $name} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($name: String!) { deleteFeatureFlag(name: $name) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteFeatureFlag" }
}

# EXPERIMENTAL: Update a feature flag
#
# operationId: updateFeatureFlag
export def "mutation update-feature-flag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  name: string # The name of the feature flag
  --value: string@bool-completer # The value of the feature flag. Only set if the new feature flag will be a concrete boolean flag. Mutually exclusive with rollout.
  --rollout-basis-points: int # The ratio of users the feature flag will apply to, expressed in basis points (0.01%). Mutually exclusive with value.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"name": $name, "value": $value, "rolloutBasisPoints": $rollout_basis_points} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename ... on FeatureFlagBoolean { name value createdAt updatedAt } ... on FeatureFlagRollout { name rolloutBasisPoints createdAt updatedAt }" }
    let body = {query: ("mutation($name: String!, $value: Boolean, $rolloutBasisPoints: Int) { updateFeatureFlag(name: $name, value: $value, rolloutBasisPoints: $rolloutBasisPoints) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateFeatureFlag" }
}

# EXPERIMENTAL: Create a new feature flag override for the given org or user
#
# operationId: createFeatureFlagOverride
export def "mutation create-feature-flag-override" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  namespace: string # The namespace for this feature flag. Must be either a user ID or an org ID.
  flag_name: string # The name of the feature flag this override applies to
  --value: string@bool-completer # The overridden value
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"namespace": $namespace, "flagName": $flag_name, "value": $value} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id value" }
    let body = {query: ("mutation($namespace: ID!, $flagName: String!, $value: Boolean!) { createFeatureFlagOverride(namespace: $namespace, flagName: $flagName, value: $value) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createFeatureFlagOverride" }
}

# Delete a feature flag override
#
# operationId: deleteFeatureFlagOverride
export def "mutation delete-feature-flag-override" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string # The ID of the feature flag override to delete
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!) { deleteFeatureFlagOverride(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteFeatureFlagOverride" }
}

# Update a feature flag override
#
# operationId: updateFeatureFlagOverride
export def "mutation update-feature-flag-override" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string # The ID of the feature flag override to update
  --value: string@bool-completer # The updated value of the feature flag override
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id, "value": $value} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id value" }
    let body = {query: ("mutation($id: ID!, $value: Boolean!) { updateFeatureFlagOverride(id: $id, value: $value) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateFeatureFlagOverride" }
}

# Overwrites and saves the temporary settings for the current user. If temporary settings for the user do not exist, they are created.
#
# operationId: overwriteTemporarySettings
export def "mutation overwrite-temporary-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  contents: string # The new temporary settings for the current user, as a JSON string.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"contents": $contents} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($contents: String!) { overwriteTemporarySettings(contents: $contents) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "overwriteTemporarySettings" }
}

# Merges the given settings edit with the current temporary settings for the current user. Keys in the given edit take priority over key in the temporary settings. The merge is not recursive. If temporary settings for the user do not exist, they are created.
#
# operationId: editTemporarySettings
export def "mutation edit-temporary-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  settings_to_edit: string # The settings to merge with the current temporary settings for the current user, as a JSON string.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"settingsToEdit": $settings_to_edit} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($settingsToEdit: String!) { editTemporarySettings(settingsToEdit: $settingsToEdit) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "editTemporarySettings" }
}

# Sends an email for testing Sourcegraph's email configuration.  Only administrators can use this API.
#
# operationId: sendTestEmail
export def "mutation send-test-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  to: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"to": $to} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let body = {query: "mutation($to: String!) { sendTestEmail(to: $to) }", variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "sendTestEmail" }
}

# Enqueues a sync for the external service. It will be picked up in the background.  Site-admin or owner of the external service only.
#
# operationId: syncExternalService
export def "mutation sync-external-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!) { syncExternalService(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "syncExternalService" }
}

# Cancels an external service sync job. Must be in queued or processing state.  Site-admin or owner of the external service only.
#
# operationId: cancelExternalServiceSync
export def "mutation cancel-external-service-sync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!) { cancelExternalServiceSync(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "cancelExternalServiceSync" }
}

# Associate a new key-value pair with a repo.
#
# DEPRECATED
# operationId: addRepoKeyValuePair
@deprecated "Use addRepoMetadata instead. This field is a deprecated and will be removed in a future release."
export def "mutation add-repo-key-value-pair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repo: string
  key: string
  --value: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repo": $repo, "key": $key, "value": $value} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($repo: ID!, $key: String!, $value: String) { addRepoKeyValuePair(repo: $repo, key: $key, value: $value) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "addRepoKeyValuePair" }
}

# Associate a new key-value pair metadata with a repo.
#
# operationId: addRepoMetadata
export def "mutation add-repo-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repo: string
  key: string
  --value: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repo": $repo, "key": $key, "value": $value} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($repo: ID!, $key: String!, $value: String) { addRepoMetadata(repo: $repo, key: $key, value: $value) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "addRepoMetadata" }
}

# Update a key-value pair associated with a repo.
#
# DEPRECATED
# operationId: updateRepoKeyValuePair
@deprecated "Use updateRepoMetadata instead. This field is a deprecated and will be removed in a future release."
export def "mutation update-repo-key-value-pair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repo: string
  key: string
  --value: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repo": $repo, "key": $key, "value": $value} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($repo: ID!, $key: String!, $value: String) { updateRepoKeyValuePair(repo: $repo, key: $key, value: $value) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateRepoKeyValuePair" }
}

# Update metadata value for a given metadata key for associated with a repo.
#
# operationId: updateRepoMetadata
export def "mutation update-repo-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repo: string
  key: string
  --value: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repo": $repo, "key": $key, "value": $value} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($repo: ID!, $key: String!, $value: String) { updateRepoMetadata(repo: $repo, key: $key, value: $value) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateRepoMetadata" }
}

# Delete a key-value pair associated with a repo.
#
# DEPRECATED
# operationId: deleteRepoKeyValuePair
@deprecated "Use deleteRepoMetadata instead. This field is a deprecated and will be removed in a future release."
export def "mutation delete-repo-key-value-pair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repo: string
  key: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repo": $repo, "key": $key} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($repo: ID!, $key: String!) { deleteRepoKeyValuePair(repo: $repo, key: $key) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteRepoKeyValuePair" }
}

# Delete a key-value pair metadata associated with a repo.
#
# operationId: deleteRepoMetadata
export def "mutation delete-repo-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repo: string
  key: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repo": $repo, "key": $key} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($repo: ID!, $key: String!) { deleteRepoMetadata(repo: $repo, key: $key) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteRepoMetadata" }
}

# INTERNAL ONLY: Reclone a repository from the gitserver. This involves deleting the file on disk, marking it as not-cloned in the database, and then initiating a repo clone.
#
# operationId: recloneRepository
export def "mutation reclone-repository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repo: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repo": $repo} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($repo: ID!) { recloneRepository(repo: $repo) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "recloneRepository" }
}

# INTERNAL ONLY: Delete a repository from the gitserver. This involves deleting the file on disk, and marking it as not-cloned in the database.
#
# operationId: deleteRepositoryFromDisk
export def "mutation delete-repository-from-disk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repo: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repo": $repo} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($repo: ID!) { deleteRepositoryFromDisk(repo: $repo) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteRepositoryFromDisk" }
}

# Sets the completions requests quota for the user per day. Quota: Null means use the default quota.
#
# operationId: setUserCompletionsQuota
export def "mutation set-user-completions-quota" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user: string
  --quota: int
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"user": $user, "quota": $quota} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id username email displayName avatarURL url settingsURL createdAt updatedAt siteAdmin builtinAuth serviceAccount unrestrictedRepoAccess tosAccepted hasVerifiedEmail viewerCanAdminister viewerCanChangeUsername databaseID namespaceName scimControlled viewerCanChangePrimaryEmail completionsQuotaOverride codeCompletionsQuotaOverride evaluateFeatureFlag" }
    let body = {query: ("mutation($user: ID!, $quota: Int) { setUserCompletionsQuota(user: $user, quota: $quota) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setUserCompletionsQuota" }
}

# Sets the code completions requests quota for the user per day. Quota: Null means use the default quota.
#
# operationId: setUserCodeCompletionsQuota
export def "mutation set-user-code-completions-quota" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user: string
  --quota: int
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"user": $user, "quota": $quota} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id username email displayName avatarURL url settingsURL createdAt updatedAt siteAdmin builtinAuth serviceAccount unrestrictedRepoAccess tosAccepted hasVerifiedEmail viewerCanAdminister viewerCanChangeUsername databaseID namespaceName scimControlled viewerCanChangePrimaryEmail completionsQuotaOverride codeCompletionsQuotaOverride evaluateFeatureFlag" }
    let body = {query: ("mutation($user: ID!, $quota: Int) { setUserCodeCompletionsQuota(user: $user, quota: $quota) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setUserCodeCompletionsQuota" }
}

# Dismisses a notification by its ID.  Admin notifications may only be dismissed by site admins. User notifications may only be dismissed by the user they belong to.
#
# operationId: dismissNotification
export def "mutation dismiss-notification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id key severity title message href dismissedAt occurrenceCount createdAt updatedAt" }
    let body = {query: ("mutation($id: ID!) { dismissNotification(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "dismissNotification" }
}

# Deletes a notification by its ID.  Admin notifications may only be deleted by site admins. User notifications may only be deleted by the user they belong to.
#
# operationId: deleteNotification
export def "mutation delete-notification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!) { deleteNotification(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteNotification" }
}

# Create a new executor secret. See argument descriptions for more details.
#
# operationId: createExecutorSecret
export def "mutation create-executor-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  scope: string@scope-completer # The scope for which the secret is usable.
  key: string # The key under which the secret is known. For executions, this is the name of the environment variable this secret will be accessible under. It is therefore advised that key only contains uppercase letters, numbers and underscores.
  value: string # The secret value.
  --namespace: string # The namespace this secret is for. If not set, a global secret is created that is accessible by all users. Creating a global secret requires site-admin permissions. Creating a namespaced secret requires write-access to the namespace.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"scope": $scope, "key": $key, "value": $value, "namespace": $namespace} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id key scope overwritesGlobalSecret createdAt updatedAt" }
    let body = {query: ("mutation($scope: ExecutorSecretScope!, $key: String!, $value: String!, $namespace: ID) { createExecutorSecret(scope: $scope, key: $key, value: $value, namespace: $namespace) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createExecutorSecret" }
}

# Update the value of an existing executor secret.
#
# operationId: updateExecutorSecret
export def "mutation update-executor-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  scope: string@scope-completer # The scope of the secret.
  id: string # The identifier of the secret that shall be updated.
  value: string # The new secret value.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"scope": $scope, "id": $id, "value": $value} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id key scope overwritesGlobalSecret createdAt updatedAt" }
    let body = {query: ("mutation($scope: ExecutorSecretScope!, $id: ID!, $value: String!) { updateExecutorSecret(scope: $scope, id: $id, value: $value) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateExecutorSecret" }
}

# Deletes the given executor secret.
#
# operationId: deleteExecutorSecret
export def "mutation delete-executor-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  scope: string@scope-completer # The scope of the secret.
  id: string # The identifier of the secret that shall be deleted.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"scope": $scope, "id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($scope: ExecutorSecretScope!, $id: ID!) { deleteExecutorSecret(scope: $scope, id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteExecutorSecret" }
}

# Adds or updates a single container registry credential inside a DOCKER_AUTH_CONFIG executor secret. If the DOCKER_AUTH_CONFIG executor secret does not yet exist in the target namespace, it is created with the supplied credential as its single entry. Exactly one of (`username` + `password`) or `auth` must be supplied:   - When `username` and `password` are supplied, the server encodes     `base64(username:password)` and stores that as the credential.   - When `auth` is supplied, it must already be a `base64(username:password)`     string (e.g. taken from `docker login`'s `~/.docker/config.json`). Only BATCHES scope is currently supported. `namespace` selects which DOCKER_AUTH_CONFIG secret to modify. It may be a User ID or an Org ID. Non-admins may only target their own user namespace or an org they belong to; site admins may target any namespace. When `namespace` is omitted, the site-wide (global) DOCKER_AUTH_CONFIG secret is targeted; this is restricted to site admins.
#
# operationId: upsertDockerRegistryCredential
export def "mutation upsert-docker-registry-credential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  registry: string # The container registry host (e.g. "index.docker.io" or "ghcr.io").
  --username: string # The username to authenticate to the registry as. Mutually exclusive with `auth`.
  --password: string # The password / token to authenticate to the registry with. Mutually exclusive with `auth`.
  --qp-auth: string # A pre-encoded `base64(username:password)` credential string. Mutually exclusive with `username` / `password`.
  --namespace: string # The namespace that owns the DOCKER_AUTH_CONFIG secret. May be a User ID or an Org ID. Non-admins may only target their own user namespace or an org they belong to; site admins may target any namespace. When omitted, the site-wide (global) secret is targeted; this is restricted to site admins.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"registry": $registry, "username": $username, "password": $password, "auth": $qp_auth, "namespace": $namespace} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id key scope overwritesGlobalSecret createdAt updatedAt" }
    let body = {query: ("mutation($registry: String!, $username: String, $password: String, $auth: String, $namespace: ID) { upsertDockerRegistryCredential(registry: $registry, username: $username, password: $password, auth: $auth, namespace: $namespace) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "upsertDockerRegistryCredential" }
}

# Removes a single container registry credential from a DOCKER_AUTH_CONFIG executor secret. If the resulting auth config has no remaining entries, the entire executor secret is deleted and null is returned. Only BATCHES scope is currently supported. See `upsertDockerRegistryCredential` for namespace selection rules.
#
# operationId: deleteDockerRegistryCredential
export def "mutation delete-docker-registry-credential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  registry: string # The container registry host whose credential should be removed.
  --namespace: string # The namespace that owns the DOCKER_AUTH_CONFIG secret. May be a User ID or an Org ID. When omitted, the site-wide (global) secret is targeted; this is restricted to site admins.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"registry": $registry, "namespace": $namespace} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id key scope overwritesGlobalSecret createdAt updatedAt" }
    let body = {query: ("mutation($registry: String!, $namespace: ID) { deleteDockerRegistryCredential(registry: $registry, namespace: $namespace) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteDockerRegistryCredential" }
}

# Marks access_request as rejected
#
# operationId: setAccessRequestStatus
export def "mutation set-access-request-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  status: string@status-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id, "status": $status} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!, $status: AccessRequestStatus!) { setAccessRequestStatus(id: $id, status: $status) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setAccessRequestStatus" }
}

# Stores config for a Slack bot integration.
#
# operationId: connectSlackWorkspace
export def "mutation connect-slack-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  signing_secret: string
  bot_token: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"signingSecret": $signing_secret, "botToken": $bot_token} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($signingSecret: String!, $botToken: String!) { connectSlackWorkspace(signingSecret: $signingSecret, botToken: $botToken) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "connectSlackWorkspace" }
}

# Removes config for a Slack bot integration.
#
# operationId: disconnectSlackWorkspace
export def "mutation disconnect-slack-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!) { disconnectSlackWorkspace(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "disconnectSlackWorkspace" }
}

# Updates whether Deep Search is allowed for a Slack bot integration.
#
# operationId: setSlackAllowDeepSearch
export def "mutation set-slack-allow-deep-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  --allow: string@bool-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id, "allow": $allow} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!, $allow: Boolean!) { setSlackAllowDeepSearch(id: $id, allow: $allow) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setSlackAllowDeepSearch" }
}

# Creates a new outbound webhook.  Only site admins have access to this mutation.
#
# operationId: createOutboundWebhook
# --input-eventTypes item shape: {eventType: string, scope?: string}
export def "mutation create-outbound-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-url: string # The outbound webhook URL.
  --input-secret: string # The secret shared with the outbound webhook.
  --input-eventTypes: record # The event types the outbound webhook will receive.  At least one event type must be provided. — item shape: {eventType: string, scope?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"url": $input_url, "secret": $input_secret, "eventTypes": $input_eventTypes} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id url" }
    let body = {query: ("mutation($input: OutboundWebhookCreateInput!) { createOutboundWebhook(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createOutboundWebhook" }
}

# Deletes an outbound webhook.  Only site admins have access to this mutation.
#
# operationId: deleteOutboundWebhook
export def "mutation delete-outbound-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!) { deleteOutboundWebhook(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteOutboundWebhook" }
}

# Updates an outbound webhook.  Only site admins have access to this mutation.
#
# operationId: updateOutboundWebhook
# --input-eventTypes item shape: {eventType: string, scope?: string}
export def "mutation update-outbound-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  --input-url: string # The outbound webhook URL.
  --input-eventTypes: record # The event types the outbound webhook will receive. This list replaces the event types previously registered on the webhook.  At least one event type must be provided. — item shape: {eventType: string, scope?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"url": $input_url, "eventTypes": $input_eventTypes} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id url" }
    let body = {query: ("mutation($id: ID!, $input: OutboundWebhookUpdateInput!) { updateOutboundWebhook(id: $id, input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateOutboundWebhook" }
}

# Validates an external TLS configuration without saving it. Optionally validates connectivity to a specified endpoint.  Only site admins may perform this mutation.
#
# operationId: validateExternalTLSConfiguration
# --input-certificates item shape: {pem: string, fingerprint?: string}
# --input-mtlsConfigurations item shape: {host: string, clientCertificate: string, clientCertificateFingerprint?: string, clientKey?: string}
export def "mutation validate-external-tls-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --validate-endpoint: string # Optional URL or host:port to validate TLS connectivity against.
  --input-insecureSkipVerify: string@bool-completer # If true, skip TLS certificate verification for all outgoing connections. WARNING: This makes TLS susceptible to man-in-the-middle attacks.
  --input-certificates: record # CA certificates to trust in addition to system CAs. — item shape: {pem: string, fingerprint?: string}
  --input-mtlsConfigurations: record # Mutual TLS (mTLS) configurations for specific hosts. — item shape: {host: string, clientCertificate: string, clientCertificateFingerprint?: string, clientKey?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"insecureSkipVerify": $input_insecureSkipVerify, "certificates": $input_certificates, "mtlsConfigurations": $input_mtlsConfigurations} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"validateEndpoint": $validate_endpoint, "input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "errors warnings" }
    let body = {query: ("mutation($input: ExternalTLSConfigInput!, $validateEndpoint: String) { validateExternalTLSConfiguration(validateEndpoint: $validateEndpoint, input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "validateExternalTLSConfiguration" }
}

# Sets the external TLS configuration in the site configuration.  Only site admins may perform this mutation.
#
# operationId: setExternalTLSConfiguration
# --input-certificates item shape: {pem: string, fingerprint?: string}
# --input-mtlsConfigurations item shape: {host: string, clientCertificate: string, clientCertificateFingerprint?: string, clientKey?: string}
export def "mutation set-external-tls-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-insecureSkipVerify: string@bool-completer # If true, skip TLS certificate verification for all outgoing connections. WARNING: This makes TLS susceptible to man-in-the-middle attacks.
  --input-certificates: record # CA certificates to trust in addition to system CAs. — item shape: {pem: string, fingerprint?: string}
  --input-mtlsConfigurations: record # Mutual TLS (mTLS) configurations for specific hosts. — item shape: {host: string, clientCertificate: string, clientCertificateFingerprint?: string, clientKey?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"insecureSkipVerify": $input_insecureSkipVerify, "certificates": $input_certificates, "mtlsConfigurations": $input_mtlsConfigurations} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($input: ExternalTLSConfigInput) { setExternalTLSConfiguration(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setExternalTLSConfiguration" }
}

# Deletes a precise index.
#
# operationId: deletePreciseIndex
export def "mutation delete-precise-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!) { deletePreciseIndex(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deletePreciseIndex" }
}

# Deletes precise indexes by filter criteria.
#
# operationId: deletePreciseIndexes
export def "mutation delete-precise-indexes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --qp-query: string # An (optional) search query that filters the state, repository name, commit, root, and indexer properties.
  --states: string@states-completer # The index state.
  --indexer-key: string # If supplied, only precise indexes created by an indexer with the given key are modified.
  --is-latest-for-repo: string@bool-completer # When specified, only deletes indexes that are latest for the given repository.
  --repository: string # The repository.
  --index-source: string@index-source-completer # If supplied, only deletes indexes from the given source (AUTO_INDEX or UPLOAD).
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"query": $qp_query, "states": $states, "indexerKey": $indexer_key, "isLatestForRepo": $is_latest_for_repo, "repository": $repository, "indexSource": $index_source} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($query: String, $states: [PreciseIndexState!], $indexerKey: String, $isLatestForRepo: Boolean, $repository: ID, $indexSource: PreciseIndexSource) { deletePreciseIndexes(query: $query, states: $states, indexerKey: $indexerKey, isLatestForRepo: $isLatestForRepo, repository: $repository, indexSource: $indexSource) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deletePreciseIndexes" }
}

# Queues the index jobs for a repository for execution. An optional resolvable revhash (commit, branch name, or tag name) can be specified; by default the tip of the default branch will be used.  If a configuration is supplied, that configuration is used to determine what jobs to schedule. If no configuration is supplied, it will go through the regular index scheduling rules: first look for any existing in-database configuration, then fall back to the automatically inferred configuration based on the repo contents at the target commit.
#
# operationId: queueAutoIndexJobsForRepo
export def "mutation queue-auto-index-jobs-for-repo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repository: string
  --rev: string
  --configuration: string
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repository": $repository, "rev": $rev, "configuration": $configuration} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id inputCommit inputRoot inputIndexer tags state queuedAt indexingStartedAt indexingFinishedAt uploadedAt processingStartedAt processingFinishedAt failure placeInQueue shouldReindex isLatestForRepo" }
    let body = {query: ("mutation($repository: ID!, $rev: String, $configuration: String) { queueAutoIndexJobsForRepo(repository: $repository, rev: $rev, configuration: $configuration) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "queueAutoIndexJobsForRepo" }
}

# Updates the previously set/overrides the default global auto-indexing job inference Lua script with a new override.
#
# operationId: updateCodeIntelligenceInferenceScript
export def "mutation update-code-intelligence-inference-script" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  script: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"script": $script} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($script: String!) { updateCodeIntelligenceInferenceScript(script: $script) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateCodeIntelligenceInferenceScript" }
}

# Updates the indexing configuration associated with a repository.
#
# operationId: updateRepositoryIndexConfiguration
export def "mutation update-repository-index-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repository: string
  configuration: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repository": $repository, "configuration": $configuration} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($repository: ID!, $configuration: String!) { updateRepositoryIndexConfiguration(repository: $repository, configuration: $configuration) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateRepositoryIndexConfiguration" }
}

# Updates the managed indexing settings for the Sourcegraph instance. This creates or updates the "[Sourcegraph Managed]" global policy.
#
# operationId: updateManagedIndexingSettings
export def "mutation update-managed-indexing-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --precise-indexing-enabled: string@bool-completer # Whether precise indexing should be enabled.
  --syntactic-indexing-enabled: string@bool-completer # Whether syntactic indexing should be enabled. Note: If syntactic indexing is disabled at the site config level (codeintelSyntacticIndexing.enabled is false), this value will be ignored and syntactic indexing will remain disabled.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"preciseIndexingEnabled": $precise_indexing_enabled, "syntacticIndexingEnabled": $syntactic_indexing_enabled} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "preciseIndexingEnabled syntacticIndexingEnabled" }
    let body = {query: ("mutation($preciseIndexingEnabled: Boolean!, $syntacticIndexingEnabled: Boolean!) { updateManagedIndexingSettings(preciseIndexingEnabled: $preciseIndexingEnabled, syntacticIndexingEnabled: $syntacticIndexingEnabled) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateManagedIndexingSettings" }
}

# Creates a new configuration policy with the given attributes.
#
# operationId: createCodeIntelligenceConfigurationPolicy
export def "mutation create-code-intelligence-configuration-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --repository: string # If supplied, the repository to which this configuration policy applies. If not supplied, this configuration policy is applied to all repositories.
  --repository-patterns: string # If supplied, the name patterns matching repositories to which this configuration policy applies. This option is mutually exclusive with an explicit repository.
  name: string
  type: string@type-completer-1
  pattern: string
  --retention-enabled: string@bool-completer
  --retention-duration-hours: int
  --retain-intermediate-commits: string@bool-completer
  --indexing-enabled: string@bool-completer # Does this policy enable precise auto-indexing?
  --syntactic-indexing-enabled: string@bool-completer
  --index-commit-max-age-hours: int
  --index-intermediate-commits: string@bool-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repository": $repository, "repositoryPatterns": $repository_patterns, "name": $name, "type": $type, "pattern": $pattern, "retentionEnabled": $retention_enabled, "retentionDurationHours": $retention_duration_hours, "retainIntermediateCommits": $retain_intermediate_commits, "indexingEnabled": $indexing_enabled, "syntacticIndexingEnabled": $syntactic_indexing_enabled, "indexCommitMaxAgeHours": $index_commit_max_age_hours, "indexIntermediateCommits": $index_intermediate_commits} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name repositoryPatterns type pattern protected retentionEnabled retentionDurationHours retainIntermediateCommits indexingEnabled syntacticIndexingEnabled indexCommitMaxAgeHours indexIntermediateCommits" }
    let body = {query: ("mutation($repository: ID, $repositoryPatterns: [String!], $name: String!, $type: GitObjectType!, $pattern: String!, $retentionEnabled: Boolean!, $retentionDurationHours: Int, $retainIntermediateCommits: Boolean!, $indexingEnabled: Boolean!, $syntacticIndexingEnabled: Boolean, $indexCommitMaxAgeHours: Int, $indexIntermediateCommits: Boolean!) { createCodeIntelligenceConfigurationPolicy(repository: $repository, repositoryPatterns: $repositoryPatterns, name: $name, type: $type, pattern: $pattern, retentionEnabled: $retentionEnabled, retentionDurationHours: $retentionDurationHours, retainIntermediateCommits: $retainIntermediateCommits, indexingEnabled: $indexingEnabled, syntacticIndexingEnabled: $syntacticIndexingEnabled, indexCommitMaxAgeHours: $indexCommitMaxAgeHours, indexIntermediateCommits: $indexIntermediateCommits) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createCodeIntelligenceConfigurationPolicy" }
}

# Updates the attributes configuration policy with the given identifier.
#
# operationId: updateCodeIntelligenceConfigurationPolicy
export def "mutation update-code-intelligence-configuration-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  --repository-patterns: string
  name: string
  type: string@type-completer-1
  pattern: string
  --retention-enabled: string@bool-completer
  --retention-duration-hours: int
  --retain-intermediate-commits: string@bool-completer
  --indexing-enabled: string@bool-completer # Does this policy enable precise auto-indexing?
  --syntactic-indexing-enabled: string@bool-completer
  --index-commit-max-age-hours: int
  --index-intermediate-commits: string@bool-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id, "repositoryPatterns": $repository_patterns, "name": $name, "type": $type, "pattern": $pattern, "retentionEnabled": $retention_enabled, "retentionDurationHours": $retention_duration_hours, "retainIntermediateCommits": $retain_intermediate_commits, "indexingEnabled": $indexing_enabled, "syntacticIndexingEnabled": $syntactic_indexing_enabled, "indexCommitMaxAgeHours": $index_commit_max_age_hours, "indexIntermediateCommits": $index_intermediate_commits} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!, $repositoryPatterns: [String!], $name: String!, $type: GitObjectType!, $pattern: String!, $retentionEnabled: Boolean!, $retentionDurationHours: Int, $retainIntermediateCommits: Boolean!, $indexingEnabled: Boolean!, $syntacticIndexingEnabled: Boolean, $indexCommitMaxAgeHours: Int, $indexIntermediateCommits: Boolean!) { updateCodeIntelligenceConfigurationPolicy(id: $id, repositoryPatterns: $repositoryPatterns, name: $name, type: $type, pattern: $pattern, retentionEnabled: $retentionEnabled, retentionDurationHours: $retentionDurationHours, retainIntermediateCommits: $retainIntermediateCommits, indexingEnabled: $indexingEnabled, syntacticIndexingEnabled: $syntacticIndexingEnabled, indexCommitMaxAgeHours: $indexCommitMaxAgeHours, indexIntermediateCommits: $indexIntermediateCommits) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateCodeIntelligenceConfigurationPolicy" }
}

# Resets the list of all unprotected configuration policies to the given list.  Protected policies are not affected; they can be individually modified using updateCodeIntelligenceConfigurationPolicy.  EXPERIMENTAL(May 2025): This API may make breaking changes.
#
# operationId: resetCodeIntelligenceConfigurationPolicies
# --wanted-policies item shape: {name: string, type: "GIT_COMMIT"|"GIT_TAG"|"GIT_TREE"|"GIT_BLOB"|"GIT_UNKNOWN", pattern: string, retentionEnabled: bool, retentionDurationHours?: int, indexingEnabled: bool, syntacticIndexingEnabled: bool, indexCommitMaxAgeHours?: int}
export def "mutation reset-code-intelligence-configuration-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --wanted-policies: record # item shape: {name: string, type: "GIT_COMMIT"|"GIT_TAG"|"GIT_TREE"|"GIT_BLOB"|"GIT_UNKNOWN", pattern: string, retentionEnabled: bool, retentionDurationHours?: int, indexingEnabled: bool, syntacticIndexingEnabled: bool, indexCommitMaxAgeHours?: int}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"wantedPolicies": $wanted_policies} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($wantedPolicies: [CodeGraphConfigurationPolicyInput!]!) { resetCodeIntelligenceConfigurationPolicies(wantedPolicies: $wantedPolicies) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "resetCodeIntelligenceConfigurationPolicies" }
}

# Deletes the configuration policy with the given identifier.
#
# operationId: deleteCodeIntelligenceConfigurationPolicy
export def "mutation delete-code-intelligence-configuration-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  policy: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"policy": $policy} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($policy: ID!) { deleteCodeIntelligenceConfigurationPolicy(policy: $policy) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteCodeIntelligenceConfigurationPolicy" }
}

# Create a new dashboard.
#
# operationId: createInsightsDashboard
# --input-grants shape: {users?: string, organizations?: string, global?: bool}
export def "mutation create-insights-dashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-title: string # Dashboard title.
  --input-grants: record # Permissions to grant to the dashboard. — shape: {users?: string, organizations?: string, global?: bool}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"title": $input_title, "grants": $input_grants} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("mutation($input: CreateInsightsDashboardInput!) { createInsightsDashboard(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createInsightsDashboard" }
}

# Edit an existing dashboard.
#
# operationId: updateInsightsDashboard
# --input-grants shape: {users?: string, organizations?: string, global?: bool}
export def "mutation update-insights-dashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  --input-title: string # Dashboard title.
  --input-grants: record # Permissions to grant to the dashboard. — shape: {users?: string, organizations?: string, global?: bool}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"title": $input_title, "grants": $input_grants} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("mutation($id: ID!, $input: UpdateInsightsDashboardInput!) { updateInsightsDashboard(id: $id, input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateInsightsDashboard" }
}

# Delete a dashboard.
#
# operationId: deleteInsightsDashboard
export def "mutation delete-insights-dashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!) { deleteInsightsDashboard(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteInsightsDashboard" }
}

# Associate an existing insight view with this dashboard.
#
# operationId: addInsightViewToDashboard
export def "mutation add-insight-view-to-dashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-insightViewId: string # ID of the insight view to attach to the dashboard
  --input-dashboardId: string # ID of the dashboard.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"insightViewId": $input_insightViewId, "dashboardId": $input_dashboardId} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("mutation($input: AddInsightViewToDashboardInput!) { addInsightViewToDashboard(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "addInsightViewToDashboard" }
}

# Remove an insight view from a dashboard.
#
# operationId: removeInsightViewFromDashboard
export def "mutation remove-insight-view-from-dashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-insightViewId: string # ID of the insight view to remove from the dashboard
  --input-dashboardId: string # ID of the dashboard.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"insightViewId": $input_insightViewId, "dashboardId": $input_dashboardId} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("mutation($input: RemoveInsightViewFromDashboardInput!) { removeInsightViewFromDashboard(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "removeInsightViewFromDashboard" }
}

# Update an insight series. Restricted to admins only.
#
# operationId: updateInsightSeries
export def "mutation update-insight-series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-seriesId: string # Unique ID for the series.
  --input-enabled: string@bool-completer # The desired activity state (enabled or disabled) for the series.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"seriesId": $input_seriesId, "enabled": $input_enabled} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("mutation($input: UpdateInsightSeriesInput!) { updateInsightSeries(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateInsightSeries" }
}

# Create a line chart backed by search insights.
#
# operationId: createLineChartSearchInsight
# --input-dataSeries item shape: {seriesId?: string, query: string, options: record, repositoryScope?: record, timeScope?: record, generatedFromCaptureGroups?: bool, groupBy?: "REPO"|"LANG"|"PATH"|"AUTHOR"|"DATE"}
# --input-repositoryScope shape: {repositories: string, repositoryCriteria?: string}
# --input-timeScope shape: {stepInterval?: record}
# --input-options shape: {title?: string}
# --input-viewControls shape: {filters: record, seriesDisplayOptions: record}
export def "mutation create-line-chart-search-insight" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-dataSeries: record # The list of data series to create (or add) to this insight. — item shape: {seriesId?: string, query: string, options: record, repositoryScope?: record, timeScope?: record, generatedFromCaptureGroups?: bool, groupBy?: "REPO"|"LANG"|"PATH"|"AUTHOR"|"DATE"}
  --input-repositoryScope: record # The scope of repositories for the insight. If provided here it will apply to all series unless overwritten. — shape: {repositories: string, repositoryCriteria?: string}
  --input-timeScope: record # The scope of time for the insight view. If provided here it will apply to all series unless overwritten. — shape: {stepInterval?: record}
  --input-options: record # The options for this line chart. — shape: {title?: string}
  --input-dashboards: string # The dashboard IDs to associate this insight with once created.
  --input-viewControls: record # The default values for filters and aggregates for this line chart. — shape: {filters: record, seriesDisplayOptions: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"dataSeries": $input_dataSeries, "repositoryScope": $input_repositoryScope, "timeScope": $input_timeScope, "options": $input_options, "dashboards": $input_dashboards, "viewControls": $input_viewControls} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("mutation($input: LineChartSearchInsightInput!) { createLineChartSearchInsight(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createLineChartSearchInsight" }
}

# Create a pie chart backed by search insights.
#
# operationId: createPieChartSearchInsight
# --input-repositoryScope shape: {repositories: string, repositoryCriteria?: string}
# --input-presentationOptions shape: {title: string, otherThreshold: float}
export def "mutation create-pie-chart-search-insight" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-query: string # The query string.
  --input-repositoryScope: record # The scope of repositories. — shape: {repositories: string, repositoryCriteria?: string}
  --input-presentationOptions: record # Options for this pie chart. — shape: {title: string, otherThreshold: float}
  --input-dashboards: string # The dashboard IDs to associate this insight with once created.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"query": $input_query, "repositoryScope": $input_repositoryScope, "presentationOptions": $input_presentationOptions, "dashboards": $input_dashboards} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("mutation($input: PieChartSearchInsightInput!) { createPieChartSearchInsight(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createPieChartSearchInsight" }
}

# Create a repository statistics insight.
#
# operationId: createInventoryStatsInsight
# --input-series item shape: {metric: "LINES_OF_CODE"|"BYTES"|"FILE_COUNT", groupBy?: "REPO"|"LANG"|"PATH"|"AUTHOR"|"DATE", options?: record, timeScope?: record}
# --input-repositoryScope shape: {repositories: string, repositoryCriteria?: string}
# --input-timeScope shape: {stepInterval?: record}
# --input-options shape: {title?: string}
# --input-viewControls shape: {filters: record, seriesDisplayOptions: record}
export def "mutation create-inventory-stats-insight" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-series: record # The series metrics to track (max 3: one of each metric type). — item shape: {metric: "LINES_OF_CODE"|"BYTES"|"FILE_COUNT", groupBy?: "REPO"|"LANG"|"PATH"|"AUTHOR"|"DATE", options?: record, timeScope?: record}
  --input-repositoryScope: record # The scope of repositories. — shape: {repositories: string, repositoryCriteria?: string}
  --input-timeScope: record # The scope of time. If provided here it will apply to all series unless overwritten. — shape: {stepInterval?: record}
  --input-options: record # Options for this chart. — shape: {title?: string}
  --input-dashboards: string # The dashboard IDs with which to associate this insight once created.
  --input-viewControls: record # The default values for filters and aggregates for this chart. — shape: {filters: record, seriesDisplayOptions: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"series": $input_series, "repositoryScope": $input_repositoryScope, "timeScope": $input_timeScope, "options": $input_options, "dashboards": $input_dashboards, "viewControls": $input_viewControls} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("mutation($input: InventoryStatsInsightInput!) { createInventoryStatsInsight(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createInventoryStatsInsight" }
}

# Update a line chart backed by search insights.
#
# operationId: updateLineChartSearchInsight
# --input-dataSeries item shape: {seriesId?: string, query: string, options: record, repositoryScope?: record, timeScope?: record, generatedFromCaptureGroups?: bool, groupBy?: "REPO"|"LANG"|"PATH"|"AUTHOR"|"DATE"}
# --input-repositoryScope shape: {repositories: string, repositoryCriteria?: string}
# --input-timeScope shape: {stepInterval?: record}
# --input-presentationOptions shape: {title?: string}
# --input-viewControls shape: {filters: record, seriesDisplayOptions: record}
export def "mutation update-line-chart-search-insight" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  --input-dataSeries: record # The complete list of data series on this line chart. Note: excluding a data series will remove it. — item shape: {seriesId?: string, query: string, options: record, repositoryScope?: record, timeScope?: record, generatedFromCaptureGroups?: bool, groupBy?: "REPO"|"LANG"|"PATH"|"AUTHOR"|"DATE"}
  --input-repositoryScope: record # The scope of repositories for the insight, this scope will apply to all dataSeries unless another scope is provided by a series. — shape: {repositories: string, repositoryCriteria?: string}
  --input-timeScope: record # The time scope for this insight, this scope will apply to all dataSeries unless another scope is provided by a series. — shape: {stepInterval?: record}
  --input-presentationOptions: record # The presentation options for this line chart. — shape: {title?: string}
  --input-viewControls: record # The default values for filters and aggregates for this line chart. — shape: {filters: record, seriesDisplayOptions: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"dataSeries": $input_dataSeries, "repositoryScope": $input_repositoryScope, "timeScope": $input_timeScope, "presentationOptions": $input_presentationOptions, "viewControls": $input_viewControls} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("mutation($id: ID!, $input: UpdateLineChartSearchInsightInput!) { updateLineChartSearchInsight(id: $id, input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateLineChartSearchInsight" }
}

# Update a pie chart backed by search insights.
#
# operationId: updatePieChartSearchInsight
# --input-repositoryScope shape: {repositories: string, repositoryCriteria?: string}
# --input-presentationOptions shape: {title: string, otherThreshold: float}
export def "mutation update-pie-chart-search-insight" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  --input-query: string # The query string.
  --input-repositoryScope: record # The scope of repositories. — shape: {repositories: string, repositoryCriteria?: string}
  --input-presentationOptions: record # Options for this pie chart. — shape: {title: string, otherThreshold: float}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"query": $input_query, "repositoryScope": $input_repositoryScope, "presentationOptions": $input_presentationOptions} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("mutation($id: ID!, $input: UpdatePieChartSearchInsightInput!) { updatePieChartSearchInsight(id: $id, input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updatePieChartSearchInsight" }
}

# Update a repository statistics insight.
#
# operationId: updateInventoryStatsInsight
# --input-dataSeries item shape: {metric: "LINES_OF_CODE"|"BYTES"|"FILE_COUNT", groupBy?: "REPO"|"LANG"|"PATH"|"AUTHOR"|"DATE", options?: record, timeScope?: record}
# --input-repositoryScope shape: {repositories: string, repositoryCriteria?: string}
# --input-timeScope shape: {stepInterval?: record}
# --input-presentationOptions shape: {title?: string}
# --input-viewControls shape: {filters: record, seriesDisplayOptions: record}
export def "mutation update-inventory-stats-insight" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  --input-dataSeries: record # The complete list of series metrics to track (max 3). — item shape: {metric: "LINES_OF_CODE"|"BYTES"|"FILE_COUNT", groupBy?: "REPO"|"LANG"|"PATH"|"AUTHOR"|"DATE", options?: record, timeScope?: record}
  --input-repositoryScope: record # The scope of repositories. — shape: {repositories: string, repositoryCriteria?: string}
  --input-timeScope: record # The scope of time. — shape: {stepInterval?: record}
  --input-presentationOptions: record # Options for this chart. — shape: {title?: string}
  --input-viewControls: record # The default values for filters and aggregates for this chart. — shape: {filters: record, seriesDisplayOptions: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"dataSeries": $input_dataSeries, "repositoryScope": $input_repositoryScope, "timeScope": $input_timeScope, "presentationOptions": $input_presentationOptions, "viewControls": $input_viewControls} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("mutation($id: ID!, $input: UpdateInventoryStatsInsightInput!) { updateInventoryStatsInsight(id: $id, input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateInventoryStatsInsight" }
}

# Delete an insight view given the graphql ID.
#
# operationId: deleteInsightView
export def "mutation delete-insight-view" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!) { deleteInsightView(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteInsightView" }
}

# Create a new insight view from an existing view.
#
# operationId: saveInsightAsNewView
# --input-options shape: {title?: string}
# --input-viewControls shape: {filters: record, seriesDisplayOptions: record}
export def "mutation save-insight-as-new-view" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-insightViewId: string # The insight view ID we are creating a new view from.
  --input-options: record # The options for this line chart. — shape: {title?: string}
  --input-dashboard: string # The dashboard ID to associate this insight with once created.
  --input-viewControls: record # The default values for filters and aggregates for this line chart. — shape: {filters: record, seriesDisplayOptions: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"insightViewId": $input_insightViewId, "options": $input_options, "dashboard": $input_dashboard, "viewControls": $input_viewControls} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("mutation($input: SaveInsightAsNewViewInput!) { saveInsightAsNewView(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "saveInsightAsNewView" }
}

# Retry the backfill for a failed insight series given the graphql ID of the InsightBackfillQueueItem. Can only be used by a site admin.
#
# operationId: retryInsightSeriesBackfill
export def "mutation retry-insight-series-backfill" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id insightViewTitle seriesLabel seriesSearchQuery" }
    let body = {query: ("mutation($id: ID!) { retryInsightSeriesBackfill(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "retryInsightSeriesBackfill" }
}

# Updates the priority of an insight series backfill making it the highest priority given the graphql ID of the InsightBackfillQueueItem.
#
# operationId: moveInsightSeriesBackfillToFrontOfQueue
export def "mutation move-insight-series-backfill-to-front-of-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id insightViewTitle seriesLabel seriesSearchQuery" }
    let body = {query: ("mutation($id: ID!) { moveInsightSeriesBackfillToFrontOfQueue(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "moveInsightSeriesBackfillToFrontOfQueue" }
}

# Updates the priority of an insight series backfill making it the lowest priority given the graphql ID of the InsightBackfillQueueItem
#
# operationId: moveInsightSeriesBackfillToBackOfQueue
export def "mutation move-insight-series-backfill-to-back-of-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id insightViewTitle seriesLabel seriesSearchQuery" }
    let body = {query: ("mutation($id: ID!) { moveInsightSeriesBackfillToBackOfQueue(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "moveInsightSeriesBackfillToBackOfQueue" }
}

# Set the permissions of a repository (i.e., which users may view it on Sourcegraph). This operation overwrites the previous permissions for the repository.
#
# operationId: setRepositoryPermissionsForUsers
# --user-permissions item shape: {bindID: string, permission?: "READ"}
export def "mutation set-repository-permissions-for-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repository: string # The repository whose permissions to set.
  --user-permissions: record # A list of user identifiers and their repository permissions, which defines the set of users who may view the repository. All users not included in the list will not be permitted to view the repository on Sourcegraph. — item shape: {bindID: string, permission?: "READ"}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repository": $repository, "userPermissions": $user_permissions} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($repository: ID!, $userPermissions: [UserPermissionInput!]!) { setRepositoryPermissionsForUsers(repository: $repository, userPermissions: $userPermissions) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setRepositoryPermissionsForUsers" }
}

# Add permission for a single user to access a repository. This operation preserves existing permissions.
#
# operationId: addRepositoryPermissionForUser
export def "mutation add-repository-permission-for-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user_id: string # The user identifier and permission level to add.
  --permission-repository: string # The repository ID to grant permission for. Mutually exclusive with wildcard.
  --permission-wildcard: string@bool-completer # Whether to grant unrestricted access to all repositories. Mutually exclusive with repository.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let permission = ({"repository": $permission_repository, "wildcard": $permission_wildcard} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"userID": $user_id, "permission": $permission} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($permission: RepositoryPermissionInput!, $userID: ID!) { addRepositoryPermissionForUser(userID: $userID, permission: $permission) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "addRepositoryPermissionForUser" }
}

# Remove permission for a single user to access a repository. This operation preserves other existing permissions.
#
# operationId: removeRepositoryPermissionForUser
export def "mutation remove-repository-permission-for-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repository: string # The repository to remove permission from.
  user_id: string # The bindID (username or email) of the user whose permission to remove.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repository": $repository, "userID": $user_id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($repository: ID!, $userID: ID!) { removeRepositoryPermissionForUser(repository: $repository, userID: $userID) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "removeRepositoryPermissionForUser" }
}

# Set 'unrestricted' to true or false on a set of repositories. Repositories with 'unrestricted' true will be visible to all users on the Sourcegraph instance.
#
# operationId: setRepositoryPermissionsUnrestricted
export def "mutation set-repository-permissions-unrestricted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repositories: string # The repository ids we want to set unrestricted permissions on. Must not contain duplicates.
  --unrestricted: string@bool-completer # true: Any user can view the repo false: Use existing repo permissions
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repositories": $repositories, "unrestricted": $unrestricted} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($repositories: [ID!]!, $unrestricted: Boolean!) { setRepositoryPermissionsUnrestricted(repositories: $repositories, unrestricted: $unrestricted) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setRepositoryPermissionsUnrestricted" }
}

# Schedule a permissions sync for given repository. This queries the repository's code host for all users' permissions associated with the repository, so that the current permissions apply to all users' operations on that repository on Sourcegraph.
#
# operationId: scheduleRepositoryPermissionsSync
export def "mutation schedule-repository-permissions-sync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repository: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repository": $repository} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($repository: ID!) { scheduleRepositoryPermissionsSync(repository: $repository) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "scheduleRepositoryPermissionsSync" }
}

# Schedule a permissions sync for given user. This queries all code hosts for the user's current repository permissions and syncs them to Sourcegraph, so that the current permissions apply to the user's operations on Sourcegraph.
#
# operationId: scheduleUserPermissionsSync
export def "mutation schedule-user-permissions-sync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user: string # User to schedule a sync for.
  --options-invalidateCaches: string@bool-completer # Indicate that any caches added for optimization encountered during this permissions sync should be invalidated.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let options = ({"invalidateCaches": $options_invalidateCaches} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"user": $user, "options": $options} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($user: ID!, $options: FetchPermissionsOptions) { scheduleUserPermissionsSync(user: $user, options: $options) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "scheduleUserPermissionsSync" }
}

# Set the sub-repo permissions of a repository (i.e., which paths are allowed or disallowed for a particular user). This operation overwrites the previous sub-repo permissions for the repository.
#
# operationId: setSubRepositoryPermissionsForUsers
# --user-permissions item shape: {bindID: string, pathIncludes?: string, pathExcludes?: string, paths?: string}
export def "mutation set-sub-repository-permissions-for-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  repository: string # The repository whose permissions to set.
  --user-permissions: record # A list of user identifiers and their sub-repository permissions, which defines the set of paths within the repository they can access. — item shape: {bindID: string, pathIncludes?: string, pathExcludes?: string, paths?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"repository": $repository, "userPermissions": $user_permissions} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($repository: ID!, $userPermissions: [UserSubRepoPermission!]!) { setSubRepositoryPermissionsForUsers(repository: $repository, userPermissions: $userPermissions) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setSubRepositoryPermissionsForUsers" }
}

# Set the repository permissions for a given Bitbucket project. This mutation will apply the user given permissions to all the repositories that are part of the Bitbucket project as identified by the project key and all the users that have access to each repository.
#
# operationId: setRepositoryPermissionsForBitbucketProject
# --user-permissions item shape: {bindID: string, permission?: "READ"}
export def "mutation set-repository-permissions-for-bitbucket-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  project_key: string # Bitbucket project key of which all repository permissions will be updated.
  code_host: string # The bitbucket code host's GraphQL ID where this project is located.
  --user-permissions: record # A list of user identifiers and their repository permissions, which defines the set of users who may view the repository. All users not included in the list will not be permitted to view the repository on Sourcegraph. — item shape: {bindID: string, permission?: "READ"}
  --unrestricted: string@bool-completer # Flag to indicate if ALL repositories under the project will allow unrestricted access to all users who have access to the code host.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"projectKey": $project_key, "codeHost": $code_host, "userPermissions": $user_permissions, "unrestricted": $unrestricted} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($projectKey: String!, $codeHost: ID!, $userPermissions: [UserPermissionInput!]!, $unrestricted: Boolean) { setRepositoryPermissionsForBitbucketProject(projectKey: $projectKey, codeHost: $codeHost, userPermissions: $userPermissions, unrestricted: $unrestricted) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setRepositoryPermissionsForBitbucketProject" }
}

# Cancel permissions sync job with given ID. No error is returned when the job is not in `queued` state or there is no such job with the given ID (latter means that most probably, the job has already been cleaned up).
#
# operationId: cancelPermissionsSyncJob
export def "mutation cancel-permissions-sync-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  job: string # ID of the job to be canceled.
  --reason: string # Optional cancellation reason.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"job": $job, "reason": $reason} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let body = {query: "mutation($job: ID!, $reason: String) { cancelPermissionsSyncJob(job: $job, reason: $reason) }", variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "cancelPermissionsSyncJob" }
}

# Creates a new auth provider wizard draft.
#
# operationId: createAuthProviderWizardDraft
export def "mutation create-auth-provider-wizard-draft" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-wizardType: string@input-wizardType-completer # The type of wizard.
  --input-displayName: string # Optional display name for this draft.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"wizardType": $input_wizardType, "displayName": $input_displayName} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id wizardType displayName stepConfiguration lastValidatedAt createdAt updatedAt" }
    let body = {query: ("mutation($input: CreateAuthProviderWizardDraftInput!) { createAuthProviderWizardDraft(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createAuthProviderWizardDraft" }
}

# Updates an existing auth provider wizard draft.
#
# operationId: updateAuthProviderWizardDraft
export def "mutation update-auth-provider-wizard-draft" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  --input-displayName: string # Optional display name for this draft.
  --input-stepConfiguration: string # The step configuration as a JSON string. This stores all the configuration values collected during the auth provider wizard process.
  --input-clearValidationResult: string@bool-completer # If true, clears the last validation result and timestamp.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"displayName": $input_displayName, "stepConfiguration": $input_stepConfiguration, "clearValidationResult": $input_clearValidationResult} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id wizardType displayName stepConfiguration lastValidatedAt createdAt updatedAt" }
    let body = {query: ("mutation($id: ID!, $input: UpdateAuthProviderWizardDraftInput!) { updateAuthProviderWizardDraft(id: $id, input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateAuthProviderWizardDraft" }
}

# Deletes an auth provider wizard draft.
#
# operationId: deleteAuthProviderWizardDraft
export def "mutation delete-auth-provider-wizard-draft" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!) { deleteAuthProviderWizardDraft(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteAuthProviderWizardDraft" }
}

# Records a validation result for an auth provider wizard draft.
#
# operationId: recordAuthProviderWizardValidationResult
export def "mutation record-auth-provider-wizard-validation-result" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  --result-success: string@bool-completer # Whether the validation was successful.
  --result-errorMessage: string # Error message if the validation failed.
  --result-subject: string # The authenticated subject identifier.
  --result-email: string # The authenticated user's email.
  --result-username: string # The authenticated user's username.
  --result-displayName: string # The authenticated user's display name.
  --result-groups: string # Groups the authenticated user belongs to.
  --result-warnings: string # Any warnings from the validation.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let result = ({"success": $result_success, "errorMessage": $result_errorMessage, "subject": $result_subject, "email": $result_email, "username": $result_username, "displayName": $result_displayName, "groups": $result_groups, "warnings": $result_warnings} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "result": $result} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id wizardType displayName stepConfiguration lastValidatedAt createdAt updatedAt" }
    let body = {query: ("mutation($id: ID!, $result: AuthProviderWizardValidationResultInput!) { recordAuthProviderWizardValidationResult(id: $id, result: $result) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "recordAuthProviderWizardValidationResult" }
}

# Finalizes an auth provider wizard draft by committing the configuration to site config and deleting the draft.
#
# operationId: finalizeAuthProviderWizardDraft
export def "mutation finalize-auth-provider-wizard-draft" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-id: string # The auth provider wizard draft ID to finalize.
  --input-providerConfig: string # The authentication provider configuration to commit to site config.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"id": $input_id, "providerConfig": $input_providerConfig} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($input: FinalizeAuthProviderWizardDraftInput!) { finalizeAuthProviderWizardDraft(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "finalizeAuthProviderWizardDraft" }
}

# Creates a saved search.
#
# operationId: createSavedSearch
export def "mutation create-saved-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-owner: string # The owner of the saved search, either a user or organization.
  --input-description: string # A description of the saved search.
  --input-query: string # The search query.
  --input-draft: string@bool-completer # Whether the saved search is a draft.
  --input-visibility: string@input-visibility-completer # The visibility state for the saved search.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"owner": $input_owner, "description": $input_description, "query": $input_query, "draft": $input_draft, "visibility": $input_visibility} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id description query draft visibility createdAt updatedAt url viewerCanAdminister" }
    let body = {query: ("mutation($input: SavedSearchInput!) { createSavedSearch(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createSavedSearch" }
}

# Updates a saved search.
#
# operationId: updateSavedSearch
export def "mutation update-saved-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  --input-description: string # A description of the saved search.
  --input-query: string # The search query.
  --input-draft: string@bool-completer # Whether the saved search is a draft.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"description": $input_description, "query": $input_query, "draft": $input_draft} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id description query draft visibility createdAt updatedAt url viewerCanAdminister" }
    let body = {query: ("mutation($id: ID!, $input: SavedSearchUpdateInput!) { updateSavedSearch(id: $id, input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateSavedSearch" }
}

# Deletes a saved search.
#
# operationId: deleteSavedSearch
export def "mutation delete-saved-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!) { deleteSavedSearch(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteSavedSearch" }
}

# Transfers ownership of a saved search to a new owner (a namespace, either a user or organization).  Only users who can administer the saved search may transfer it.
#
# operationId: transferSavedSearchOwnership
export def "mutation transfer-saved-search-ownership" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  new_owner: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id, "newOwner": $new_owner} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id description query draft visibility createdAt updatedAt url viewerCanAdminister" }
    let body = {query: ("mutation($id: ID!, $newOwner: ID!) { transferSavedSearchOwnership(id: $id, newOwner: $newOwner) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "transferSavedSearchOwnership" }
}

# Change the visibility state of a saved search.  Only users who can administer the saved search may change its visibility state.
#
# operationId: changeSavedSearchVisibility
export def "mutation change-saved-search-visibility" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  new_visibility: string@new-visibility-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id, "newVisibility": $new_visibility} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id description query draft visibility createdAt updatedAt url viewerCanAdminister" }
    let body = {query: ("mutation($id: ID!, $newVisibility: SavedSearchVisibility!) { changeSavedSearchVisibility(id: $id, newVisibility: $newVisibility) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "changeSavedSearchVisibility" }
}

# EXPERIMENTAL: Mark one or more changed files in a diff as viewed for the current user. Idempotent. Batch capped at 5000 files.
#
# operationId: markChangedFilesAsViewed
# --input-files item shape: {path: string, srcOID?: string, dstOID?: string}
export def "mutation mark-changed-files-as-viewed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-repository: string # The repository containing the diff.
  --input-base: string # The base symbolic ref of the comparison (e.g. "main"). If omitted, treated as "HEAD" to match repository.comparison.
  --input-head: string # The head symbolic ref of the comparison (e.g. "feature"). If omitted, treated as "HEAD" to match repository.comparison.
  --input-files: record # The files to act on within this comparison. — item shape: {path: string, srcOID?: string, dstOID?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"repository": $input_repository, "base": $input_base, "head": $input_head, "files": $input_files} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let body = {query: "mutation($input: MarkChangedFilesInput!) { markChangedFilesAsViewed(input: $input) }", variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "markChangedFilesAsViewed" }
}

# EXPERIMENTAL: Remove the "viewed" mark from one or more changed files in a diff for the current user. Batch capped at 5000 files.
#
# operationId: markChangedFilesAsUnviewed
# --input-files item shape: {path: string, srcOID?: string, dstOID?: string}
export def "mutation mark-changed-files-as-unviewed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-repository: string # The repository containing the diff.
  --input-base: string # The base symbolic ref of the comparison (e.g. "main"). If omitted, treated as "HEAD" to match repository.comparison.
  --input-head: string # The head symbolic ref of the comparison (e.g. "feature"). If omitted, treated as "HEAD" to match repository.comparison.
  --input-files: record # The files to act on within this comparison. — item shape: {path: string, srcOID?: string, dstOID?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"repository": $input_repository, "base": $input_base, "head": $input_head, "files": $input_files} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let body = {query: "mutation($input: MarkChangedFilesInput!) { markChangedFilesAsUnviewed(input: $input) }", variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "markChangedFilesAsUnviewed" }
}

# Delete a GitHub App. The GitHub App, along with all of its associated code host connections and authentication provider, will be deleted. 🚨 SECURITY: Requires site-admin.
#
# operationId: deleteGitHubApp
export def "mutation delete-git-hub-app" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  git_hub_app: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"gitHubApp": $git_hub_app} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($gitHubApp: ID!) { deleteGitHubApp(gitHubApp: $gitHubApp) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteGitHubApp" }
}

# Refresh a GitHub App. This fetches information about the GitHub app and updates all installations associated with it. 🚨 SECURITY: Requires site-admin.
#
# operationId: refreshGitHubApp
export def "mutation refresh-git-hub-app" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  git_hub_app: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"gitHubApp": $git_hub_app} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($gitHubApp: ID!) { refreshGitHubApp(gitHubApp: $gitHubApp) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "refreshGitHubApp" }
}

# Add an existing GitHub App. This uses the provided Client ID and Private Key to fetch the GitHub App details from GitHub and store it in the database. 🚨 SECURITY: Requires site-admin.
#
# operationId: createGitHubApp
export def "mutation create-git-hub-app" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  git_hub_url: string
  client_id: string
  private_key: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"gitHubURL": $git_hub_url, "clientID": $client_id, "privateKey": $private_key} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id appID name domain kind slug baseURL appURL clientID clientSecret logo createdAt updatedAt missingRequiredPermissions" }
    let body = {query: ("mutation($gitHubURL: String!, $clientID: String!, $privateKey: String!) { createGitHubApp(gitHubURL: $gitHubURL, clientID: $clientID, privateKey: $privateKey) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createGitHubApp" }
}

# Adds a GitHub App as an authentication provider in the site configuration. This appends a new GitHub auth provider entry (using the app's clientID, clientSecret, and baseURL) to the "auth.providers" list in site config. If a matching provider already exists, this is a no-op. 🚨 SECURITY: Requires site-admin.
#
# operationId: addGitHubAppAuthProvider
export def "mutation add-git-hub-app-auth-provider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  git_hub_app: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"gitHubApp": $git_hub_app} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($gitHubApp: ID!) { addGitHubAppAuthProvider(gitHubApp: $gitHubApp) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "addGitHubAppAuthProvider" }
}

# Create search context.
#
# operationId: createSearchContext
# --repositories item shape: {repositoryID: string, revisions: string}
export def "mutation create-search-context" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --repositories: record # List of search context repository revisions. — item shape: {repositoryID: string, revisions: string}
  --search-context-name: string # Search context name. Not the same as the search context spec. Search context namespace and search context name are used to construct the fully-qualified search context spec. Example mappings from search context spec to search context name: global -> global, @user -> user, @org -> org, @user/ctx1 -> ctx1, @org/ctxs/ctx -> ctxs/ctx.
  --search-context-description: string # Search context description.
  --search-context-public: string@bool-completer # Public property controls the visibility of the search context. Public search context is available to any user on the instance. If a public search context contains private repositories, those are filtered out for unauthorized users. Private search contexts are only available to their owners. Private user search context is available only to the user, private org search context is available only to the members of the org, and private instance-level search contexts are available only to users with SEARCH_CONTEXTS#WRITE_GLOBAL permission.
  --search-context-namespace: string # Namespace of the search context (user or org). If not set, search context is considered instance-level.
  --search-context-query: string # Sourcegraph search query that defines the search context. e.g. "r:^github\.com/org (rev:bar or rev:HEAD) file:^sub/dir"
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let searchContext = ({"name": $search_context_name, "description": $search_context_description, "public": $search_context_public, "namespace": $search_context_namespace, "query": $search_context_query} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"repositories": $repositories, "searchContext": $searchContext} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id databaseID name description spec autoDefined query public updatedAt viewerCanManage viewerHasAsDefault viewerHasStarred" }
    let body = {query: ("mutation($searchContext: SearchContextInput!, $repositories: [SearchContextRepositoryRevisionsInput!]!) { createSearchContext(repositories: $repositories, searchContext: $searchContext) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createSearchContext" }
}

# Delete search context.
#
# operationId: deleteSearchContext
export def "mutation delete-search-context" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!) { deleteSearchContext(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteSearchContext" }
}

# Update search context.
#
# operationId: updateSearchContext
# --repositories item shape: {repositoryID: string, revisions: string}
export def "mutation update-search-context" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string # Search context ID.
  --repositories: record # List of search context repository revisions. — item shape: {repositoryID: string, revisions: string}
  --search-context-name: string # Search context name. Not the same as the search context spec. Search context namespace and search context name are used to construct the fully-qualified search context spec. Example mappings from search context spec to search context name: global -> global, @user -> user, @org -> org, @user/ctx1 -> ctx1, @org/ctxs/ctx -> ctxs/ctx.
  --search-context-description: string # Search context description.
  --search-context-public: string@bool-completer # Public property controls the visibility of the search context. Public search context is available to any user on the instance. If a public search context contains private repositories, those are filtered out for unauthorized users. Private search contexts are only available to their owners. Private user search context is available only to the user, private org search context is available only to the members of the org, and private instance-level search contexts are available only to users with SEARCH_CONTEXTS#WRITE_GLOBAL permission.
  --search-context-query: string # Sourcegraph search query that defines the search context. e.g. "r:^github\.com/org (rev:bar or rev:HEAD) file:^sub/dir"
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let searchContext = ({"name": $search_context_name, "description": $search_context_description, "public": $search_context_public, "query": $search_context_query} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "repositories": $repositories, "searchContext": $searchContext} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id databaseID name description spec autoDefined query public updatedAt viewerCanManage viewerHasAsDefault viewerHasStarred" }
    let body = {query: ("mutation($id: ID!, $searchContext: SearchContextEditInput!, $repositories: [SearchContextRepositoryRevisionsInput!]!) { updateSearchContext(id: $id, repositories: $repositories, searchContext: $searchContext) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateSearchContext" }
}

# Add a star on a search context for the specified user. Only one star can be created per context and user pair. If the star already exists, this is a no-op.
#
# operationId: createSearchContextStar
export def "mutation create-search-context-star" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  search_context_id: string
  user_id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"searchContextID": $search_context_id, "userID": $user_id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($searchContextID: ID!, $userID: ID!) { createSearchContextStar(searchContextID: $searchContextID, userID: $userID) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createSearchContextStar" }
}

# Delete a star on a search context for the specified user. If the star does not exist, this is a no-op.
#
# operationId: deleteSearchContextStar
export def "mutation delete-search-context-star" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  search_context_id: string
  user_id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"searchContextID": $search_context_id, "userID": $user_id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($searchContextID: ID!, $userID: ID!) { deleteSearchContextStar(searchContextID: $searchContextID, userID: $userID) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteSearchContextStar" }
}

# Set the default search context for the specified user.
#
# operationId: setDefaultSearchContext
export def "mutation set-default-search-context" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  search_context_id: string
  user_id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"searchContextID": $search_context_id, "userID": $user_id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($searchContextID: ID!, $userID: ID!) { setDefaultSearchContext(searchContextID: $searchContextID, userID: $userID) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setDefaultSearchContext" }
}

# Deletes a role. This mutation targets only non-system roles. Any users who were assigned to the role will be unassigned and lose any permissions associated with it.
#
# operationId: deleteRole
export def "mutation delete-role" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  role: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"role": $role} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($role: ID!) { deleteRole(role: $role) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteRole" }
}

# Creates a role.
#
# operationId: createRole
export def "mutation create-role" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  name: string
  permissions: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"name": $name, "permissions": $permissions} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name system createdAt" }
    let body = {query: ("mutation($name: String!, $permissions: [ID!]!) { createRole(name: $name, permissions: $permissions) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createRole" }
}

# Set permissions for role. This updates the permissions assigned to a role based on the `permissions` passed in the argument. Permissions already assigned to the role that aren't part of the arguments of this mutation will be revoked for the role.
#
# operationId: setPermissions
export def "mutation set-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  role: string
  permissions: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"role": $role, "permissions": $permissions} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($role: ID!, $permissions: [ID!]!) { setPermissions(role: $role, permissions: $permissions) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setPermissions" }
}

# Set roles for a user. Similar to `setPermissions`, this updates the roles assigned to a user based on the `roles` passed in the argument. Permissions already assigned to the role that aren't part of the arguments of this mutation will be revoked for the role.
#
# operationId: setRoles
export def "mutation set-roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user: string
  roles: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"user": $user, "roles": $roles} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($user: ID!, $roles: [ID!]!) { setRoles(user: $user, roles: $roles) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "setRoles" }
}

# Creates the entitlement. Site-admin only.
#
# operationId: createEntitlement
export def "mutation create-entitlement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  name: string # The name of the entitlement.
  type: string@type-completer # The type of the entitlement.
  limit: int # The limit value for this entitlement.
  window: string@window-completer # The window to enforce this entitlement over.
  --is-default: string@bool-completer # Whether this is the default entitlement for its type.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"name": $name, "type": $type, "limit": $limit, "window": $window, "isDefault": $is_default} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name type limit window isDefault updatedAt" }
    let body = {query: ("mutation($name: String!, $type: EntitlementType!, $limit: BigInt!, $window: EntitlementWindow!, $isDefault: Boolean) { createEntitlement(name: $name, type: $type, limit: $limit, window: $window, isDefault: $isDefault) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createEntitlement" }
}

# Updates the entitlement. Site-admin only.
#
# operationId: updateEntitlement
export def "mutation update-entitlement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string # The ID of the entitlement to update.
  name: string # The name of the entitlement.
  limit: int # The limit value for this entitlement.
  window: string@window-completer # The window to enforce this entitlement over.
  --is-default: string@bool-completer # Whether this is the default entitlement for its type.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id, "name": $name, "limit": $limit, "window": $window, "isDefault": $is_default} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name type limit window isDefault updatedAt" }
    let body = {query: ("mutation($id: ID!, $name: String!, $limit: BigInt!, $window: EntitlementWindow!, $isDefault: Boolean) { updateEntitlement(id: $id, name: $name, limit: $limit, window: $window, isDefault: $isDefault) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateEntitlement" }
}

# Deletes the entitlement. Site-admin only.
#
# operationId: deleteEntitlement
export def "mutation delete-entitlement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!) { deleteEntitlement(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteEntitlement" }
}

# Grants the entitlement to the users. Site-admin only.
#
# operationId: createEntitlementGrants
export def "mutation create-entitlement-grants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  entitlement_id: string # The ID of the entitlement to grant.
  user_i_ds: string # The list of users IDs to grant the entitlement to.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"entitlementID": $entitlement_id, "userIDs": $user_i_ds} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("mutation($entitlementID: ID!, $userIDs: [ID!]!) { createEntitlementGrants(entitlementID: $entitlementID, userIDs: $userIDs) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createEntitlementGrants" }
}

# Deletes the entitlement grants. Site-admin only.
#
# operationId: deleteEntitlementGrants
export def "mutation delete-entitlement-grants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  entitlement_id: string # The ID of the entitlement grant to delete.
  user_i_ds: string # The list of users IDs to delete the grant from.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"entitlementID": $entitlement_id, "userIDs": $user_i_ds} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($entitlementID: ID!, $userIDs: [ID!]!) { deleteEntitlementGrants(entitlementID: $entitlementID, userIDs: $userIDs) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteEntitlementGrants" }
}

# Resets entitlement usage for a user. Site-admin only.
#
# operationId: resetEntitlementUsage
export def "mutation reset-entitlement-usage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  type: string@type-completer # The type of the entitlement.
  user_id: string # The ID of the user whose usage should be reset.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"type": $type, "userID": $user_id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "isDefault" }
    let body = {query: ("mutation($type: EntitlementType!, $userID: ID!) { resetEntitlementUsage(type: $type, userID: $userID) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "resetEntitlementUsage" }
}

# Telemetry mutations for "Event Logging Everywhere", aka a version 2 of existing event-logging/event-recording APIs.
#
# operationId: telemetry
export def "mutation telemetry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("mutation { telemetry { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "telemetry" }
}

# Create a prompt.
#
# operationId: createPrompt
export def "mutation create-prompt" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-owner: string # The owner of the prompt, either a user or organization.
  --input-name: string # The name of the prompt.
  --input-description: string # The description of the prompt.
  --input-definitionText: string # The prompt template definition.
  --input-draft: string@bool-completer # Whether the prompt is a draft.
  --input-visibility: string@input-visibility-completer # The visibility state for the prompt.
  --input-autoSubmit: string@bool-completer # Whether the prompt should be automatically executed in one click.
  --input-mode: string@input-mode-completer # Whether to execute prompt as chat, edit or insert command.
  --input-recommended: string@bool-completer # Whether the prompt is recommended.
  --input-tags: string # The tags for the prompt.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"owner": $input_owner, "name": $input_name, "description": $input_description, "definitionText": $input_definitionText, "draft": $input_draft, "visibility": $input_visibility, "autoSubmit": $input_autoSubmit, "mode": $input_mode, "recommended": $input_recommended, "tags": $input_tags} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name description draft visibility nameWithOwner createdAt updatedAt url viewerCanAdminister autoSubmit mode recommended builtin" }
    let body = {query: ("mutation($input: PromptInput!) { createPrompt(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createPrompt" }
}

# Update a prompt.
#
# operationId: updatePrompt
export def "mutation update-prompt" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  --input-name: string # The name of the prompt.
  --input-description: string # The description of the prompt.
  --input-definitionText: string # The prompt template definition.
  --input-draft: string@bool-completer # Whether the prompt is a draft.
  --input-autoSubmit: string@bool-completer # Whether the prompt should be automatically executed in one click.
  --input-mode: string@input-mode-completer # Whether to execute prompt as chat, edit or insert command.
  --input-recommended: string@bool-completer # Whether the prompt is recommended.
  --input-tags: string # The new tags delete and override any existing tags.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"name": $input_name, "description": $input_description, "definitionText": $input_definitionText, "draft": $input_draft, "autoSubmit": $input_autoSubmit, "mode": $input_mode, "recommended": $input_recommended, "tags": $input_tags} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name description draft visibility nameWithOwner createdAt updatedAt url viewerCanAdminister autoSubmit mode recommended builtin" }
    let body = {query: ("mutation($id: ID!, $input: PromptUpdateInput!) { updatePrompt(id: $id, input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updatePrompt" }
}

# Delete a prompt.
#
# operationId: deletePrompt
export def "mutation delete-prompt" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!) { deletePrompt(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deletePrompt" }
}

# Transfer ownership of a prompt to a new owner (a namespace, either a user or organization).  Only users who can administer the prompt may transfer it.
#
# operationId: transferPromptOwnership
export def "mutation transfer-prompt-ownership" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  new_owner: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id, "newOwner": $new_owner} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name description draft visibility nameWithOwner createdAt updatedAt url viewerCanAdminister autoSubmit mode recommended builtin" }
    let body = {query: ("mutation($id: ID!, $newOwner: ID!) { transferPromptOwnership(id: $id, newOwner: $newOwner) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "transferPromptOwnership" }
}

# Change the visibility state of a prompt.  Only users who can administer the prompt may change its visibility state.
#
# operationId: changePromptVisibility
export def "mutation change-prompt-visibility" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  new_visibility: string@new-visibility-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id, "newVisibility": $new_visibility} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name description draft visibility nameWithOwner createdAt updatedAt url viewerCanAdminister autoSubmit mode recommended builtin" }
    let body = {query: ("mutation($id: ID!, $newVisibility: PromptVisibility!) { changePromptVisibility(id: $id, newVisibility: $newVisibility) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "changePromptVisibility" }
}

# Create a prompt tag.
#
# operationId: createPromptTag
export def "mutation create-prompt-tag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --input-name: string # The name of the prompt tag.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"name": $input_name} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name createdAt updatedAt url viewerCanAdminister" }
    let body = {query: ("mutation($input: PromptTagCreateInput!) { createPromptTag(input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createPromptTag" }
}

# Update a prompt tag.
#
# operationId: updatePromptTag
export def "mutation update-prompt-tag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  --input-name: string # The name of the prompt tag.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let input = ({"name": $input_name} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "input": $input} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name createdAt updatedAt url viewerCanAdminister" }
    let body = {query: ("mutation($id: ID!, $input: PromptTagUpdateInput!) { updatePromptTag(id: $id, input: $input) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updatePromptTag" }
}

# Delete a prompt tag.
#
# operationId: deletePromptTag
export def "mutation delete-prompt-tag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!) { deletePromptTag(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deletePromptTag" }
}

# Create a new IdP client. The secret will be returned and can never be accessed again.  Requires IDP_CLIENTS#WRITE permission.
#
# operationId: createIDPClient
export def "mutation create-idp-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  name: string # A descriptive name for the client. Will be shown to users.
  --description: string # A detailed description of what this client does and why it needs access. Will be shown to users on consent screens.
  redirect_ur_is: string # The list of permitted redirect URIs.
  scopes: string # The list of scopes this client can request.
  --public: string@bool-completer # Whether this is a public client.  Public clients don't need to present a client secret. This is suitable for single-page applications, mobile apps, and CLI tools. The client supports device flow authentication.  Private clients need to provide the client secret for authorization flows. Suitable for server-side applications, internal services, and M2M use-cases.  This setting cannot be changed after creation.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"name": $name, "description": $description, "redirectURIs": $redirect_ur_is, "scopes": $scopes, "public": $public} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "clientSecret" }
    let body = {query: ("mutation($name: String!, $description: String, $redirectURIs: [String!]!, $scopes: [String!]!, $public: Boolean!) { createIDPClient(name: $name, description: $description, redirectURIs: $redirectURIs, scopes: $scopes, public: $public) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createIDPClient" }
}

# Update an existing IdP client.  Requires IDP_CLIENTS#WRITE permission.
#
# operationId: updateIDPClient
export def "mutation update-idp-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string # The ID of the client to update.
  name: string # A descriptive name for the client. Will be shown to users.
  --description: string # A detailed description of what this client does and why it needs access. Will be shown to users on consent screens.
  redirect_ur_is: string # The list of permitted redirect URIs.
  scopes: string # The list of scopes this client can request.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id, "name": $name, "description": $description, "redirectURIs": $redirect_ur_is, "scopes": $scopes} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id clientID name description redirectURIs responseTypes scopes public audience registrationSource createdAt updatedAt" }
    let body = {query: ("mutation($id: ID!, $name: String!, $description: String, $redirectURIs: [String!]!, $scopes: [String!]!) { updateIDPClient(id: $id, name: $name, description: $description, redirectURIs: $redirectURIs, scopes: $scopes) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "updateIDPClient" }
}

# Delete an existing IdP client. Caution: all access tokens issued by this client are no longer usable.  Requires IDP_CLIENTS#WRITE permission.
#
# operationId: deleteIDPClient
export def "mutation delete-idp-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!) { deleteIDPClient(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteIDPClient" }
}

# Make a determination for device authorization. Identified by the user code from the authorization flow.
#
# operationId: resolveDeviceAuthorization
export def "mutation resolve-device-authorization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user_code: string # The user code associated with the authorization request to respond to.
  --approve: string@bool-completer # Whether to approve the request.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"userCode": $user_code, "approve": $approve} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($userCode: String!, $approve: Boolean!) { resolveDeviceAuthorization(userCode: $userCode, approve: $approve) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "resolveDeviceAuthorization" }
}

# Revoke the UserConsentedIDPClient consent. This will invalidate all access tokens and refresh tokens issued to this client for the current user, and force a consent prompt for the next authorization flow.  Can only be called by the user who owns the consent, or a site-admin.
#
# operationId: revokeIDPClientConsent
export def "mutation revoke-idp-client-consent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  consent_id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"consentID": $consent_id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($consentID: ID!) { revokeIDPClientConsent(consentID: $consentID) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "revokeIDPClientConsent" }
}

# Create a new M2M (Machine-to-Machine) credential for a service account. This creates an IdP client that can use client credentials flow to obtain access tokens with the service account as the subject.  Requires IDP_CLIENTS#WRITE_IMPERSONATION permission.
#
# operationId: createM2MCredential
export def "mutation create-m2m-credential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  user_id: string # The ID of the service account for which to create the M2M credential.
  name: string # A descriptive name for the credential. Will be shown in the credentials list.
  --description: string # A detailed description of what this credential is used for.
  scopes: string # The list of scopes this credential can request.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"userID": $user_id, "name": $name, "description": $description, "scopes": $scopes} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "clientSecret" }
    let body = {query: ("mutation($userID: ID!, $name: String!, $description: String, $scopes: [String!]!) { createM2MCredential(userID: $userID, name: $name, description: $description, scopes: $scopes) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "createM2MCredential" }
}

# Delete an M2M credential for a service account. This will delete the associated IdP client and invalidate all access tokens.  Requires IDP_CLIENTS#WRITE_IMPERSONATION permission.
#
# operationId: deleteM2MCredential
export def "mutation delete-m2m-credential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alwaysNil" }
    let body = {query: ("mutation($id: ID!) { deleteM2MCredential(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "deleteM2MCredential" }
}
